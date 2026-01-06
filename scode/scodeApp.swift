//
//  scodeApp.swift
//  scode
//
//  Claude Code Configuration Manager
//

import SwiftUI

@main
struct scodeApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 700)
        .commands {
            // File Menu
            CommandGroup(after: .newItem) {
                Button("Open Project...") {
                    Task {
                        await appState.fileService.selectProject()
                    }
                }
                .keyboardShortcut("o", modifiers: [.command])

                Divider()

                Button("Refresh") {
                    appState.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }

            // View Menu
            CommandGroup(after: .sidebar) {
                Divider()

                Menu("Go to") {
                    ForEach(ConfigTab.allCases) { tab in
                        Button(tab.rawValue) {
                            appState.selectedTab = tab
                        }
                    }
                }
            }
        }

        // Settings Window (macOS 14+)
        #if os(macOS)
        Settings {
            AppSettingsView()
                .environmentObject(appState)
        }
        #endif
    }
}

// MARK: - App Settings View

struct AppSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralAppSettings()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AboutAppSettings()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct GeneralAppSettings: View {
    @AppStorage("autoRefreshOnProjectChange") private var autoRefresh = true

    var body: some View {
        Form {
            Toggle("Auto-refresh when project changes", isOn: $autoRefresh)

            Section("Paths") {
                LabeledContent("User Settings") {
                    Text("~/.claude/settings.json")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                LabeledContent("User MCP") {
                    Text("~/.claude.json")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                LabeledContent("User Memory") {
                    Text("~/.claude/CLAUDE.md")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutAppSettings: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("scode")
                .font(.title)
                .fontWeight(.bold)

            Text("Claude Code Configuration Manager")
                .foregroundStyle(.secondary)

            Text("Version 1.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("A visual tool for managing Claude Code configurations including settings, MCP servers, memory files, and hooks.")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}
