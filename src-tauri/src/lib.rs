use chrono::{DateTime, Local, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::{self, OpenOptions};
use std::io::{BufRead, BufReader, Write};
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

// ============================================================================
// Claude Code Usage Tracking
// ============================================================================

/// Raw usage entry from JSONL file
#[derive(Debug, Deserialize)]
struct RawUsageEntry {
    timestamp: String,
    #[serde(rename = "sessionId")]
    session_id: Option<String>,
    version: Option<String>,
    cwd: Option<String>,
    message: RawMessage,
    #[serde(rename = "costUSD")]
    cost_usd: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct RawMessage {
    model: String,
    usage: RawUsage,
}

#[derive(Debug, Deserialize)]
struct RawUsage {
    input_tokens: u64,
    output_tokens: u64,
    #[serde(default)]
    cache_creation_input_tokens: u64,
    #[serde(default)]
    cache_read_input_tokens: u64,
}

/// Parsed usage entry with project info
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UsageEntry {
    pub timestamp: String,
    pub session_id: String,
    pub model: String,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_tokens: u64,
    pub cache_read_tokens: u64,
    pub cost_usd: f64,
    pub project_path: String,
}

/// Daily aggregated usage
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DailyUsage {
    pub date: String,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_tokens: u64,
    pub cache_read_tokens: u64,
    pub total_cost: f64,
    pub models_used: Vec<String>,
    pub request_count: u64,
}

/// Session aggregated usage
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SessionUsage {
    pub session_id: String,
    pub project_path: String,
    pub project_display_name: String,
    pub project_full_path: String,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_tokens: u64,
    pub cache_read_tokens: u64,
    pub total_cost: f64,
    pub last_activity: String,
    pub request_count: u64,
    pub models_used: Vec<String>,
}

/// Usage summary
#[derive(Debug, Serialize, Deserialize)]
pub struct UsageSummary {
    pub total_input_tokens: u64,
    pub total_output_tokens: u64,
    pub total_cache_creation_tokens: u64,
    pub total_cache_read_tokens: u64,
    pub total_cost: f64,
    pub total_requests: u64,
    pub session_count: u64,
    pub project_count: u64,
}

/// Project aggregated usage
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ProjectUsage {
    pub project_path: String,
    pub display_name: String,
    pub full_path: String,
    pub session_count: u64,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_tokens: u64,
    pub cache_read_tokens: u64,
    pub total_cost: f64,
    pub request_count: u64,
    pub last_activity: String,
    pub models_used: Vec<String>,
}

/// Model aggregated usage
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ModelUsage {
    pub model: String,
    pub display_name: String,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub total_cost: f64,
    pub request_count: u64,
    pub percentage: f64,
}

/// Model pricing per million tokens (hardcoded for common models)
fn get_model_pricing(model: &str) -> (f64, f64) {
    // (input_price_per_million, output_price_per_million)
    match model {
        // Claude 4 models
        m if m.contains("claude-opus-4") => (15.0, 75.0),
        m if m.contains("claude-sonnet-4") => (3.0, 15.0),
        // Claude 3.5 models
        m if m.contains("claude-3-5-sonnet") => (3.0, 15.0),
        m if m.contains("claude-3-5-haiku") => (0.8, 4.0),
        // Claude 3 models
        m if m.contains("claude-3-opus") => (15.0, 75.0),
        m if m.contains("claude-3-sonnet") => (3.0, 15.0),
        m if m.contains("claude-3-haiku") => (0.25, 1.25),
        // Default to sonnet pricing
        _ => (3.0, 15.0),
    }
}

/// Calculate cost from tokens
fn calculate_cost(model: &str, input_tokens: u64, output_tokens: u64) -> f64 {
    let (input_price, output_price) = get_model_pricing(model);
    let input_cost = (input_tokens as f64 / 1_000_000.0) * input_price;
    let output_cost = (output_tokens as f64 / 1_000_000.0) * output_price;
    input_cost + output_cost
}

/// Check if a path looks like an encoded absolute path
/// Encoded paths start with `-` followed by common root directories
fn is_encoded_absolute_path(path: &str) -> bool {
    if !path.starts_with('-') {
        return false;
    }
    // Check for common root directories after the first `-`
    let lower = path.to_lowercase();
    lower.starts_with("-users-")
        || lower.starts_with("-home-")
        || lower.starts_with("-var-")
        || lower.starts_with("-tmp-")
        || lower.starts_with("-opt-")
        || lower.starts_with("-usr-")
        || lower.starts_with("-private-")
}

/// Smart decode of Claude project path by checking filesystem
/// "-Users-Shared-GitHub-mcp-github-repos" → "/Users/Shared/GitHub/mcp-github-repos"
/// This handles directory names that contain hyphens
fn decode_project_path_smart(encoded: &str) -> String {
    if !is_encoded_absolute_path(encoded) {
        return encoded.to_string();
    }

    // Remove leading '-' and split by '-'
    let without_prefix = &encoded[1..];
    let parts: Vec<&str> = without_prefix.split('-').collect();

    if parts.is_empty() {
        return encoded.to_string();
    }

    // Build path by checking filesystem at each step
    let mut current_path = String::new();
    let mut i = 0;

    while i < parts.len() {
        // Try to find the longest valid path segment
        let mut found = false;

        // Try from longest possible segment to shortest
        for j in (i + 1..=parts.len()).rev() {
            let segment = parts[i..j].join("-");
            let test_path = if current_path.is_empty() {
                format!("/{}", segment)
            } else {
                format!("{}/{}", current_path, segment)
            };

            if std::path::Path::new(&test_path).exists() {
                current_path = test_path;
                i = j;
                found = true;
                break;
            }
        }

        // If no valid path found, just use single segment
        if !found {
            let segment = parts[i];
            current_path = if current_path.is_empty() {
                format!("/{}", segment)
            } else {
                format!("{}/{}", current_path, segment)
            };
            i += 1;
        }
    }

    if current_path.is_empty() {
        encoded.to_string()
    } else {
        current_path
    }
}

/// Decode Claude project path - uses smart decoding with filesystem check
fn decode_project_path(encoded: &str) -> String {
    decode_project_path_smart(encoded)
}

/// Get project display name (last part of path)
fn get_project_display_name(encoded: &str) -> String {
    let decoded = decode_project_path(encoded);
    // Split by '/' to get the last component
    decoded
        .split('/')
        .filter(|s| !s.is_empty())
        .last()
        .unwrap_or(encoded)
        .to_string()
}

/// Get model display name
fn get_model_display_name(model: &str) -> String {
    // Check more specific patterns first (e.g., opus-4-5 before opus-4)
    if model.contains("opus-4-5") {
        "Opus 4.5".to_string()
    } else if model.contains("sonnet-4-5") {
        "Sonnet 4.5".to_string()
    } else if model.contains("opus-4") {
        "Opus 4".to_string()
    } else if model.contains("sonnet-4") {
        "Sonnet 4".to_string()
    } else if model.contains("3-5-sonnet") || model.contains("3.5-sonnet") {
        "Sonnet 3.5".to_string()
    } else if model.contains("3-5-haiku") || model.contains("3.5-haiku") {
        "Haiku 3.5".to_string()
    } else if model.contains("3-opus") {
        "Opus 3".to_string()
    } else if model.contains("3-sonnet") {
        "Sonnet 3".to_string()
    } else if model.contains("3-haiku") {
        "Haiku 3".to_string()
    } else {
        model.to_string()
    }
}

/// Get Claude data directories
fn get_claude_dirs() -> Vec<PathBuf> {
    let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));
    let mut dirs = Vec::new();

    // New XDG config path
    if let Some(config_dir) = dirs::config_dir() {
        let xdg_claude = config_dir.join("claude").join("projects");
        if xdg_claude.exists() {
            dirs.push(xdg_claude);
        }
    }

    // Old ~/.claude path
    let old_claude = home.join(".claude").join("projects");
    if old_claude.exists() {
        dirs.push(old_claude);
    }

    dirs
}

/// Scan all JSONL files in Claude directories
fn scan_jsonl_files() -> Vec<(PathBuf, String)> {
    let mut files = Vec::new();

    for base_dir in get_claude_dirs() {
        if let Ok(entries) = fs::read_dir(&base_dir) {
            for entry in entries.flatten() {
                let project_path = entry.path();
                if project_path.is_dir() {
                    let project_name = project_path
                        .file_name()
                        .and_then(|n| n.to_str())
                        .unwrap_or("unknown")
                        .to_string();

                    if let Ok(session_files) = fs::read_dir(&project_path) {
                        for session_file in session_files.flatten() {
                            let file_path = session_file.path();
                            if file_path.extension().map_or(false, |ext| ext == "jsonl") {
                                files.push((file_path, project_name.clone()));
                            }
                        }
                    }
                }
            }
        }
    }

    files
}

/// Parse a single JSONL file
fn parse_jsonl_file(path: &PathBuf, project_path: &str) -> Vec<UsageEntry> {
    let mut entries = Vec::new();

    let file = match fs::File::open(path) {
        Ok(f) => f,
        Err(_) => return entries,
    };

    let reader = BufReader::new(file);
    let session_id = path
        .file_stem()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string();

    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => continue,
        };

        if line.trim().is_empty() {
            continue;
        }

        let raw: RawUsageEntry = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(_) => continue, // Skip malformed lines
        };

        let cost = raw.cost_usd.unwrap_or_else(|| {
            calculate_cost(
                &raw.message.model,
                raw.message.usage.input_tokens,
                raw.message.usage.output_tokens,
            )
        });

        entries.push(UsageEntry {
            timestamp: raw.timestamp,
            session_id: raw.session_id.unwrap_or_else(|| session_id.clone()),
            model: raw.message.model,
            input_tokens: raw.message.usage.input_tokens,
            output_tokens: raw.message.usage.output_tokens,
            cache_creation_tokens: raw.message.usage.cache_creation_input_tokens,
            cache_read_tokens: raw.message.usage.cache_read_input_tokens,
            cost_usd: cost,
            project_path: project_path.to_string(),
        });
    }

    entries
}

/// Load all usage entries
fn load_all_usage() -> Vec<UsageEntry> {
    let files = scan_jsonl_files();
    let mut all_entries = Vec::new();

    for (path, project) in files {
        let entries = parse_jsonl_file(&path, &project);
        all_entries.extend(entries);
    }

    // Sort by timestamp descending
    all_entries.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));
    all_entries
}

#[tauri::command]
async fn get_usage_summary() -> Result<UsageSummary, String> {
    let entries = load_all_usage();

    let mut sessions: HashMap<String, bool> = HashMap::new();
    let mut projects: HashMap<String, bool> = HashMap::new();

    let mut summary = UsageSummary {
        total_input_tokens: 0,
        total_output_tokens: 0,
        total_cache_creation_tokens: 0,
        total_cache_read_tokens: 0,
        total_cost: 0.0,
        total_requests: 0,
        session_count: 0,
        project_count: 0,
    };

    for entry in entries {
        summary.total_input_tokens += entry.input_tokens;
        summary.total_output_tokens += entry.output_tokens;
        summary.total_cache_creation_tokens += entry.cache_creation_tokens;
        summary.total_cache_read_tokens += entry.cache_read_tokens;
        summary.total_cost += entry.cost_usd;
        summary.total_requests += 1;

        sessions.insert(entry.session_id, true);
        projects.insert(entry.project_path, true);
    }

    summary.session_count = sessions.len() as u64;
    summary.project_count = projects.len() as u64;

    Ok(summary)
}

#[tauri::command]
async fn get_daily_usage(days: Option<u32>) -> Result<Vec<DailyUsage>, String> {
    let entries = load_all_usage();
    let days = days.unwrap_or(30);

    // Calculate cutoff date
    let cutoff = Utc::now() - chrono::Duration::days(days as i64);

    // Group by date
    let mut daily_map: HashMap<String, DailyUsage> = HashMap::new();

    for entry in entries {
        // Parse timestamp and check if within range
        let timestamp = match DateTime::parse_from_rfc3339(&entry.timestamp) {
            Ok(t) => t.with_timezone(&Utc),
            Err(_) => continue,
        };

        if timestamp < cutoff {
            continue;
        }

        let date = timestamp.format("%Y-%m-%d").to_string();

        let daily = daily_map.entry(date.clone()).or_insert(DailyUsage {
            date,
            input_tokens: 0,
            output_tokens: 0,
            cache_creation_tokens: 0,
            cache_read_tokens: 0,
            total_cost: 0.0,
            models_used: Vec::new(),
            request_count: 0,
        });

        daily.input_tokens += entry.input_tokens;
        daily.output_tokens += entry.output_tokens;
        daily.cache_creation_tokens += entry.cache_creation_tokens;
        daily.cache_read_tokens += entry.cache_read_tokens;
        daily.total_cost += entry.cost_usd;
        daily.request_count += 1;

        if !daily.models_used.contains(&entry.model) {
            daily.models_used.push(entry.model);
        }
    }

    // Convert to vec and sort by date descending
    let mut daily_list: Vec<DailyUsage> = daily_map.into_values().collect();
    daily_list.sort_by(|a, b| b.date.cmp(&a.date));

    Ok(daily_list)
}

#[tauri::command]
async fn get_session_usage() -> Result<Vec<SessionUsage>, String> {
    let entries = load_all_usage();

    // Group by session_id
    let mut session_map: HashMap<String, SessionUsage> = HashMap::new();

    for entry in entries {
        let session = session_map
            .entry(entry.session_id.clone())
            .or_insert_with(|| {
                let display_name = get_project_display_name(&entry.project_path);
                let full_path = decode_project_path(&entry.project_path);
                SessionUsage {
                    session_id: entry.session_id.clone(),
                    project_path: entry.project_path.clone(),
                    project_display_name: display_name,
                    project_full_path: full_path,
                    input_tokens: 0,
                    output_tokens: 0,
                    cache_creation_tokens: 0,
                    cache_read_tokens: 0,
                    total_cost: 0.0,
                    last_activity: entry.timestamp.clone(),
                    request_count: 0,
                    models_used: Vec::new(),
                }
            });

        session.input_tokens += entry.input_tokens;
        session.output_tokens += entry.output_tokens;
        session.cache_creation_tokens += entry.cache_creation_tokens;
        session.cache_read_tokens += entry.cache_read_tokens;
        session.total_cost += entry.cost_usd;
        session.request_count += 1;

        // Update last_activity if this entry is more recent
        if entry.timestamp > session.last_activity {
            session.last_activity = entry.timestamp.clone();
        }

        if !session.models_used.contains(&entry.model) {
            session.models_used.push(entry.model);
        }
    }

    // Convert to vec and sort by last_activity descending
    let mut session_list: Vec<SessionUsage> = session_map.into_values().collect();
    session_list.sort_by(|a, b| b.last_activity.cmp(&a.last_activity));

    Ok(session_list)
}

#[tauri::command]
async fn get_recent_usage(minutes: Option<u32>) -> Result<Vec<UsageEntry>, String> {
    let entries = load_all_usage();
    let minutes = minutes.unwrap_or(60);

    let cutoff = Utc::now() - chrono::Duration::minutes(minutes as i64);

    let recent: Vec<UsageEntry> = entries
        .into_iter()
        .filter(|e| {
            DateTime::parse_from_rfc3339(&e.timestamp)
                .map(|t| t.with_timezone(&Utc) >= cutoff)
                .unwrap_or(false)
        })
        .collect();

    Ok(recent)
}

#[tauri::command]
async fn get_project_usage() -> Result<Vec<ProjectUsage>, String> {
    let entries = load_all_usage();

    // Group by project_path
    let mut project_map: HashMap<String, ProjectUsage> = HashMap::new();
    // Track unique sessions per project
    let mut project_sessions: HashMap<String, std::collections::HashSet<String>> = HashMap::new();

    for entry in entries {
        let project = project_map
            .entry(entry.project_path.clone())
            .or_insert_with(|| {
                let display_name = get_project_display_name(&entry.project_path);
                let full_path = decode_project_path(&entry.project_path);
                ProjectUsage {
                    project_path: entry.project_path.clone(),
                    display_name,
                    full_path,
                    session_count: 0, // Will be calculated after
                    input_tokens: 0,
                    output_tokens: 0,
                    cache_creation_tokens: 0,
                    cache_read_tokens: 0,
                    total_cost: 0.0,
                    request_count: 0,
                    last_activity: entry.timestamp.clone(),
                    models_used: Vec::new(),
                }
            });

        project.input_tokens += entry.input_tokens;
        project.output_tokens += entry.output_tokens;
        project.cache_creation_tokens += entry.cache_creation_tokens;
        project.cache_read_tokens += entry.cache_read_tokens;
        project.total_cost += entry.cost_usd;
        project.request_count += 1;

        // Update last_activity if this entry is more recent
        if entry.timestamp > project.last_activity {
            project.last_activity = entry.timestamp.clone();
        }

        if !project.models_used.contains(&entry.model) {
            project.models_used.push(entry.model.clone());
        }

        // Track sessions
        project_sessions
            .entry(entry.project_path.clone())
            .or_default()
            .insert(entry.session_id);
    }

    // Update session counts
    for (project_path, sessions) in project_sessions {
        if let Some(project) = project_map.get_mut(&project_path) {
            project.session_count = sessions.len() as u64;
        }
    }

    // Convert to vec and sort by total_cost descending
    let mut project_list: Vec<ProjectUsage> = project_map.into_values().collect();
    project_list.sort_by(|a, b| {
        b.total_cost
            .partial_cmp(&a.total_cost)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    Ok(project_list)
}

#[tauri::command]
async fn get_model_usage() -> Result<Vec<ModelUsage>, String> {
    let entries = load_all_usage();

    // Group by model
    let mut model_map: HashMap<String, ModelUsage> = HashMap::new();
    let mut total_tokens: u64 = 0;

    for entry in &entries {
        total_tokens += entry.input_tokens + entry.output_tokens;

        let model = model_map.entry(entry.model.clone()).or_insert_with(|| {
            let display_name = get_model_display_name(&entry.model);
            ModelUsage {
                model: entry.model.clone(),
                display_name,
                input_tokens: 0,
                output_tokens: 0,
                total_cost: 0.0,
                request_count: 0,
                percentage: 0.0,
            }
        });

        model.input_tokens += entry.input_tokens;
        model.output_tokens += entry.output_tokens;
        model.total_cost += entry.cost_usd;
        model.request_count += 1;
    }

    // Calculate percentages
    for model in model_map.values_mut() {
        let model_tokens = model.input_tokens + model.output_tokens;
        model.percentage = if total_tokens > 0 {
            (model_tokens as f64 / total_tokens as f64) * 100.0
        } else {
            0.0
        };
    }

    // Convert to vec and sort by percentage descending
    let mut model_list: Vec<ModelUsage> = model_map.into_values().collect();
    model_list.sort_by(|a, b| {
        b.percentage
            .partial_cmp(&a.percentage)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    Ok(model_list)
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
            brew_untap,
            // Claude Code usage commands
            get_usage_summary,
            get_daily_usage,
            get_session_usage,
            get_recent_usage,
            get_project_usage,
            get_model_usage
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
