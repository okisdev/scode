use chrono::Local;
use serde::{Deserialize, Serialize};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;

#[derive(Debug, Serialize, Deserialize)]
pub struct BrewInfo {
    pub version: String,
    pub prefix: String,
    pub formulae_count: u32,
    pub cask_count: u32,
    pub outdated_count: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Package {
    pub name: String,
    pub version: String,
    pub description: Option<String>,
    pub installed: bool,
    pub outdated: bool,
    pub current_version: Option<String>,
    pub latest_version: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Cask {
    pub name: String,
    pub version: String,
    pub description: Option<String>,
    pub installed: bool,
    pub outdated: bool,
    pub icon: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Tap {
    pub name: String,
    pub official: bool,
    pub remote: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LogEntry {
    pub timestamp: String,
    pub category: String,
    pub action: String,
    pub target: String,
    pub success: bool,
    pub output: String,
}

fn get_scode_dir() -> PathBuf {
    let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));
    home.join(".scode")
}

fn get_logs_dir() -> PathBuf {
    get_scode_dir().join("logs")
}

fn ensure_logs_dir() -> Result<(), String> {
    let logs_dir = get_logs_dir();
    fs::create_dir_all(&logs_dir).map_err(|e| format!("Failed to create logs directory: {}", e))
}

fn write_log(category: &str, entry: &LogEntry) -> Result<(), String> {
    ensure_logs_dir()?;
    let log_file = get_logs_dir().join(format!("{}.log", category));

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_file)
        .map_err(|e| format!("Failed to open log file: {}", e))?;

    let status = if entry.success { "SUCCESS" } else { "FAILED" };
    let log_line = format!(
        "[{}] [{}] {} {} - {}\n",
        entry.timestamp, status, entry.action, entry.target, entry.output
    );

    file.write_all(log_line.as_bytes())
        .map_err(|e| format!("Failed to write log: {}", e))
}

fn get_brew_path() -> String {
    if std::path::Path::new("/opt/homebrew/bin/brew").exists() {
        "/opt/homebrew/bin/brew".to_string()
    } else if std::path::Path::new("/usr/local/bin/brew").exists() {
        "/usr/local/bin/brew".to_string()
    } else {
        "brew".to_string()
    }
}

fn run_brew_command(args: &[&str]) -> Result<String, String> {
    let brew_path = get_brew_path();
    let output = Command::new(&brew_path)
        .args(args)
        .output()
        .map_err(|e| format!("Failed to execute brew: {}", e))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!("Brew command failed: {}", stderr))
    }
}

fn run_brew_command_with_log(
    args: &[&str],
    action: &str,
    target: &str,
) -> Result<String, String> {
    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
    let result = run_brew_command(args);

    let entry = LogEntry {
        timestamp,
        category: "homebrew".to_string(),
        action: action.to_string(),
        target: target.to_string(),
        success: result.is_ok(),
        output: result
            .as_ref()
            .map(|s| s.lines().take(3).collect::<Vec<_>>().join(" "))
            .unwrap_or_else(|e| e.clone()),
    };

    let _ = write_log("homebrew", &entry);
    result
}

// Logging commands
#[tauri::command]
async fn get_logs(category: String, limit: Option<usize>) -> Result<Vec<LogEntry>, String> {
    let log_file = get_logs_dir().join(format!("{}.log", category));

    if !log_file.exists() {
        return Ok(Vec::new());
    }

    let content =
        fs::read_to_string(&log_file).map_err(|e| format!("Failed to read log file: {}", e))?;

    let limit = limit.unwrap_or(100);
    let entries: Vec<LogEntry> = content
        .lines()
        .rev()
        .take(limit)
        .filter_map(|line| {
            // Parse log line format: [timestamp] [STATUS] action target - output
            let parts: Vec<&str> = line.splitn(2, "] ").collect();
            if parts.len() < 2 {
                return None;
            }

            let timestamp = parts[0].trim_start_matches('[').to_string();
            let rest = parts[1];

            let status_end = rest.find(']')?;
            let status = &rest[1..status_end];
            let success = status == "SUCCESS";

            let after_status = &rest[status_end + 2..];
            let dash_pos = after_status.find(" - ")?;
            let action_target = &after_status[..dash_pos];
            let output = after_status[dash_pos + 3..].to_string();

            let mut action_parts = action_target.splitn(2, ' ');
            let action = action_parts.next()?.to_string();
            let target = action_parts.next().unwrap_or("").to_string();

            Some(LogEntry {
                timestamp,
                category: category.clone(),
                action,
                target,
                success,
                output,
            })
        })
        .collect();

    Ok(entries)
}

#[tauri::command]
async fn clear_logs(category: String) -> Result<(), String> {
    let log_file = get_logs_dir().join(format!("{}.log", category));

    if log_file.exists() {
        fs::remove_file(&log_file).map_err(|e| format!("Failed to clear logs: {}", e))?;
    }

    Ok(())
}

// Homebrew commands
#[tauri::command]
async fn brew_info() -> Result<BrewInfo, String> {
    let version_output = run_brew_command(&["--version"])?;
    let version = version_output
        .lines()
        .next()
        .unwrap_or("Unknown")
        .replace("Homebrew ", "")
        .to_string();

    let prefix = run_brew_command(&["--prefix"])?.trim().to_string();

    let formulae_output = run_brew_command(&["list", "--formula", "-1"])?;
    let formulae_count = formulae_output
        .lines()
        .filter(|l| !l.is_empty())
        .count() as u32;

    let cask_output = run_brew_command(&["list", "--cask", "-1"])?;
    let cask_count = cask_output.lines().filter(|l| !l.is_empty()).count() as u32;

    let outdated_output = run_brew_command(&["outdated", "--json=v2"])?;
    let outdated_count = if outdated_output.trim().is_empty() {
        0
    } else {
        let json: serde_json::Value = serde_json::from_str(&outdated_output)
            .map_err(|e| format!("Failed to parse outdated JSON: {}", e))?;
        let formulae_count = json["formulae"].as_array().map(|a| a.len()).unwrap_or(0);
        let casks_count = json["casks"].as_array().map(|a| a.len()).unwrap_or(0);
        (formulae_count + casks_count) as u32
    };

    Ok(BrewInfo {
        version,
        prefix,
        formulae_count,
        cask_count,
        outdated_count,
    })
}

#[tauri::command]
async fn brew_list_formulae() -> Result<Vec<Package>, String> {
    let output = run_brew_command(&["list", "--formula", "--versions"])?;
    let mut packages = Vec::new();

    for line in output.lines() {
        if line.is_empty() {
            continue;
        }
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }
        let name = parts[0].to_string();
        let version = parts.get(1).unwrap_or(&"").to_string();

        packages.push(Package {
            name,
            version: version.clone(),
            description: None,
            installed: true,
            outdated: false,
            current_version: Some(version),
            latest_version: None,
        });
    }

    Ok(packages)
}

#[tauri::command]
async fn brew_list_casks() -> Result<Vec<Cask>, String> {
    let output = run_brew_command(&["list", "--cask", "--versions"])?;
    let mut casks = Vec::new();

    for line in output.lines() {
        if line.is_empty() {
            continue;
        }
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }
        let name = parts[0].to_string();
        let version = parts.get(1).unwrap_or(&"").to_string();

        casks.push(Cask {
            name,
            version,
            description: None,
            installed: true,
            outdated: false,
            icon: None,
        });
    }

    Ok(casks)
}

#[tauri::command]
async fn brew_outdated() -> Result<Vec<Package>, String> {
    let output = run_brew_command(&["outdated", "--json=v2"])?;
    let mut packages = Vec::new();

    if output.trim().is_empty() {
        return Ok(packages);
    }

    let json: serde_json::Value =
        serde_json::from_str(&output).map_err(|e| format!("Failed to parse JSON: {}", e))?;

    if let Some(formulae) = json["formulae"].as_array() {
        for item in formulae {
            let name = item["name"].as_str().unwrap_or("").to_string();
            let current = item["installed_versions"]
                .as_array()
                .and_then(|v| v.first())
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            let latest = item["current_version"].as_str().unwrap_or("").to_string();

            packages.push(Package {
                name,
                version: latest.clone(),
                description: None,
                installed: true,
                outdated: true,
                current_version: Some(current),
                latest_version: Some(latest),
            });
        }
    }

    if let Some(casks) = json["casks"].as_array() {
        for item in casks {
            let name = item["name"].as_str().unwrap_or("").to_string();
            let current = item["installed_versions"]
                .as_str()
                .unwrap_or("")
                .to_string();
            let latest = item["current_version"].as_str().unwrap_or("").to_string();

            packages.push(Package {
                name,
                version: latest.clone(),
                description: None,
                installed: true,
                outdated: true,
                current_version: Some(current),
                latest_version: Some(latest),
            });
        }
    }

    Ok(packages)
}

#[tauri::command]
async fn brew_list_taps() -> Result<Vec<Tap>, String> {
    let output = run_brew_command(&["tap"])?;
    let mut taps = Vec::new();

    for line in output.lines() {
        if line.is_empty() {
            continue;
        }
        let name = line.trim().to_string();
        let official = name.starts_with("homebrew/");

        taps.push(Tap {
            name,
            official,
            remote: None,
        });
    }

    Ok(taps)
}

#[tauri::command]
async fn brew_search(query: String, is_cask: bool) -> Result<Vec<Package>, String> {
    let args = if is_cask {
        vec!["search", "--cask", &query]
    } else {
        vec!["search", "--formula", &query]
    };

    let output = run_brew_command(&args)?;
    let mut packages = Vec::new();

    for line in output.lines() {
        if line.is_empty() || line.starts_with("==>") {
            continue;
        }
        let name = line.trim().to_string();
        if name.is_empty() {
            continue;
        }

        packages.push(Package {
            name,
            version: String::new(),
            description: None,
            installed: false,
            outdated: false,
            current_version: None,
            latest_version: None,
        });
    }

    Ok(packages)
}

#[tauri::command]
async fn brew_install(name: String, is_cask: bool) -> Result<String, String> {
    let args: Vec<&str> = if is_cask {
        vec!["install", "--cask", &name]
    } else {
        vec!["install", &name]
    };

    run_brew_command_with_log(&args, "INSTALL", &name)
}

#[tauri::command]
async fn brew_uninstall(name: String, is_cask: bool) -> Result<String, String> {
    let args: Vec<&str> = if is_cask {
        vec!["uninstall", "--cask", &name]
    } else {
        vec!["uninstall", &name]
    };

    run_brew_command_with_log(&args, "UNINSTALL", &name)
}

#[tauri::command]
async fn brew_upgrade(name: String) -> Result<String, String> {
    run_brew_command_with_log(&["upgrade", &name], "UPGRADE", &name)
}

#[tauri::command]
async fn brew_update() -> Result<String, String> {
    run_brew_command_with_log(&["update"], "UPDATE", "homebrew")
}

#[tauri::command]
async fn brew_upgrade_all() -> Result<String, String> {
    run_brew_command_with_log(&["upgrade"], "UPGRADE_ALL", "all")
}

#[tauri::command]
async fn brew_cleanup() -> Result<String, String> {
    run_brew_command_with_log(&["cleanup"], "CLEANUP", "cache")
}

#[tauri::command]
async fn brew_doctor() -> Result<String, String> {
    let brew_path = get_brew_path();
    let output = Command::new(&brew_path)
        .arg("doctor")
        .output()
        .map_err(|e| format!("Failed to execute brew doctor: {}", e))?;

    let result = String::from_utf8_lossy(&output.stdout).to_string()
        + &String::from_utf8_lossy(&output.stderr);

    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
    let entry = LogEntry {
        timestamp,
        category: "homebrew".to_string(),
        action: "DOCTOR".to_string(),
        target: "system".to_string(),
        success: output.status.success(),
        output: result
            .lines()
            .take(3)
            .collect::<Vec<_>>()
            .join(" "),
    };
    let _ = write_log("homebrew", &entry);

    Ok(result)
}

#[tauri::command]
async fn brew_tap(name: String) -> Result<String, String> {
    run_brew_command_with_log(&["tap", &name], "TAP", &name)
}

#[tauri::command]
async fn brew_untap(name: String) -> Result<String, String> {
    run_brew_command_with_log(&["untap", &name], "UNTAP", &name)
}

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_http::init())
        .setup(|app| {
            use tauri::menu::{MenuBuilder, MenuItemBuilder, PredefinedMenuItem, SubmenuBuilder};
            use tauri::Emitter;

            let about_item = MenuItemBuilder::with_id("about", "About Scode").build(app)?;

            let app_submenu = SubmenuBuilder::new(app, "Scode")
                .item(&about_item)
                .separator()
                .item(&PredefinedMenuItem::hide(app, Some("Hide Scode"))?)
                .item(&PredefinedMenuItem::hide_others(app, None)?)
                .item(&PredefinedMenuItem::show_all(app, None)?)
                .separator()
                .item(&PredefinedMenuItem::quit(app, Some("Quit Scode"))?)
                .build()?;

            let edit_submenu = SubmenuBuilder::new(app, "Edit")
                .item(&PredefinedMenuItem::undo(app, None)?)
                .item(&PredefinedMenuItem::redo(app, None)?)
                .separator()
                .item(&PredefinedMenuItem::cut(app, None)?)
                .item(&PredefinedMenuItem::copy(app, None)?)
                .item(&PredefinedMenuItem::paste(app, None)?)
                .item(&PredefinedMenuItem::select_all(app, None)?)
                .build()?;

            let window_submenu = SubmenuBuilder::new(app, "Window")
                .item(&PredefinedMenuItem::minimize(app, None)?)
                .item(&PredefinedMenuItem::maximize(app, None)?)
                .separator()
                .item(&PredefinedMenuItem::close_window(app, Some("Close"))?)
                .build()?;

            let menu = MenuBuilder::new(app)
                .item(&app_submenu)
                .item(&edit_submenu)
                .item(&window_submenu)
                .build()?;

            app.set_menu(menu)?;

            app.on_menu_event(move |app_handle, event| {
                if event.id().0.as_str() == "about" {
                    let _ = app_handle.emit("show-about", ());
                }
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            greet,
            get_logs,
            clear_logs,
            brew_info,
            brew_list_formulae,
            brew_list_casks,
            brew_outdated,
            brew_list_taps,
            brew_search,
            brew_install,
            brew_uninstall,
            brew_upgrade,
            brew_update,
            brew_upgrade_all,
            brew_cleanup,
            brew_doctor,
            brew_tap,
            brew_untap
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
