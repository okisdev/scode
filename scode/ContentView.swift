//
//  ContentView.swift
//  scode
//
//  Main content view with improved UI/UX
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            TopToolbarView()

            Divider()

            // Main Content
            HStack(spacing: 0) {
                // Sidebar
                ConfigSidebar()
                    .frame(width: 220)

                Divider()

                // Content Area
                ConfigContentView(selectedTab: appState.selectedTab)
            }

            Divider()

            // Status Bar
            StatusBarView()
        }
        .frame(minWidth: 1000, minHeight: 650)
        .alert("External Changes Detected", isPresented: $appState.showExternalChangesAlert) {
            Button("Reload") {
                appState.refresh()
                appState.fileWatcher.acknowledgeChanges()
            }
            Button("Ignore", role: .cancel) {
                appState.fileWatcher.acknowledgeChanges()
            }
        } message: {
            Text("Configuration files have been modified externally. Would you like to reload?")
        }
        .alert("Error", isPresented: $appState.showError) {
            Button("OK") {
                appState.showError = false
            }
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
    }
}

// MARK: - Top Toolbar

struct TopToolbarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // App Title
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("scode")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Divider()
                .frame(height: 24)

            // Current File Path
            if let projectPath = appState.currentProjectPath {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.secondary)
                    Text(projectPath.lastPathComponent)
                        .fontWeight(.medium)
                    Text(appState.fileService.projectDisplayPath(projectPath))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                    Text("User Configuration")
                        .fontWeight(.medium)
                }
            }

            Spacer()

            // Sync Status
            SyncStatusIndicator()

            // Project Selector
            Menu {
                Button("Open Project...") {
                    Task {
                        await appState.fileService.selectProject()
                    }
                }

                if appState.currentProjectPath != nil {
                    Button("Close Project") {
                        appState.fileService.clearCurrentProject()
                    }
                }

                if !appState.fileService.recentProjects.isEmpty {
                    Divider()
                    Text("Recent Projects")
                    ForEach(appState.fileService.recentProjects.prefix(5), id: \.path) { project in
                        Button(project.lastPathComponent) {
                            appState.fileService.setCurrentProject(project)
                        }
                    }
                }
            } label: {
                Label("Project", systemImage: "folder.badge.gearshape")
            }
            .menuStyle(.borderlessButton)

            // Refresh
            Button {
                appState.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh configurations")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Sync Status Indicator

struct SyncStatusIndicator: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 6) {
            if appState.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Loading...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if appState.showExternalChangesAlert {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("External changes")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Synced")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Config Sidebar

struct ConfigSidebar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Scope Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("SCOPE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                ForEach(availableScopes) { scope in
                    ScopeButton(
                        scope: scope,
                        isSelected: appState.selectedSettingsScope == scope,
                        action: { appState.selectedSettingsScope = scope }
                    )
                }
            }
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 12)

            // Navigation
            VStack(alignment: .leading, spacing: 8) {
                Text("CONFIGURATION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                ForEach(ConfigTab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: appState.selectedTab == tab,
                        action: { appState.selectedTab = tab }
                    )
                }
            }

            Spacer()

            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text("ACTIVE FILE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(currentFilePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var availableScopes: [SettingsScope] {
        if appState.currentProjectPath != nil {
            return [.user, .project, .local]
        } else {
            return [.user]
        }
    }

    private var currentFilePath: String {
        let scope = appState.selectedSettingsScope
        switch scope {
        case .user:
            return "~/.claude/settings.json"
        case .project:
            return ".claude/settings.json"
        case .local:
            return ".claude/settings.local.json"
        case .enterprise:
            return "/Library/.../managed-settings.json"
        }
    }
}

struct ScopeButton: View {
    let scope: SettingsScope
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: scope.icon)
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? .white : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(scope.rawValue)
                        .fontWeight(isSelected ? .semibold : .regular)
                    Text(scope.description)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

struct TabButton: View {
    let tab: ConfigTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                Text(tab.rawValue)
                    .fontWeight(isSelected ? .semibold : .regular)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

// MARK: - Config Content View

struct ConfigContentView: View {
    let selectedTab: ConfigTab

    var body: some View {
        switch selectedTab {
        case .settings:
            SettingsView()
        case .mcp:
            MCPView()
        case .memory:
            MemoryView()
        case .hooks:
            HooksView()
        case .usage:
            UsageView()
        case .raw:
            RawConfigView()
        case .history:
            HistoryView()
        }
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // Left: File counts
            HStack(spacing: 12) {
                Label("\(appState.mcpServers.count) MCP Servers", systemImage: "server.rack")
                Label("\(appState.memoryFiles.filter { $0.exists }.count) Memory Files", systemImage: "doc.text")
                Label("\(appState.ruleFiles.count) Rules", systemImage: "list.bullet")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            // Right: Last sync time
            Text("Last sync: \(Date(), style: .time)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
