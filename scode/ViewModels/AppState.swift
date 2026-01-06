//
//  AppState.swift
//  scode
//
//  Global application state with bidirectional sync
//

import Foundation
import SwiftUI
import Combine

/// Global application state
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Services
    let configService = ConfigurationService.shared
    let fileService = FileSystemService.shared
    let fileWatcher = FileWatcherService.shared
    let historyService = HistoryService.shared

    // MARK: - Navigation
    @Published var selectedSettingsScope: SettingsScope = .user
    @Published var selectedTab: ConfigTab = .settings

    // MARK: - Project State
    @Published var currentProjectPath: URL? {
        didSet {
            if currentProjectPath != oldValue {
                loadProjectData()
                setupFileWatching()
            }
        }
    }

    // MARK: - Data State
    @Published var settings: [SettingsScope: ClaudeSettings] = [:]
    @Published var mcpServers: [MCPServerEntry] = []
    @Published var memoryFiles: [MemoryFile] = []
    @Published var ruleFiles: [RuleFile] = []

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var lastSyncTime = Date()
    @Published var showExternalChangesAlert = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Bind to file service
        fileService.$currentProjectPath
            .assign(to: &$currentProjectPath)

        // Sync file watcher changes to alert state
        fileWatcher.$hasExternalChanges
            .assign(to: &$showExternalChangesAlert)

        // Load initial data
        loadUserData()
        setupFileWatching()
    }

    // MARK: - File Watching

    private func setupFileWatching() {
        fileWatcher.stopAll()

        // Watch user config files
        fileWatcher.startWatching(configService.userSettingsPath)
        fileWatcher.startWatching(configService.userMCPPath)
        fileWatcher.startWatching(configService.userMemoryPath)

        // Watch project config files
        if let projectPath = currentProjectPath {
            fileWatcher.startWatching(configService.projectSettingsPath(for: projectPath))
            fileWatcher.startWatching(configService.localSettingsPath(for: projectPath))
            fileWatcher.startWatching(configService.projectMCPPath(for: projectPath))
            fileWatcher.startWatching(configService.projectMemoryPath(for: projectPath))
            fileWatcher.startWatching(configService.localMemoryPath(for: projectPath))
        }
    }

    // MARK: - Data Loading

    func loadUserData() {
        isLoading = true

        // Load user-level settings
        if let userSettings = try? configService.loadSettings(from: configService.userSettingsPath) {
            settings[.user] = userSettings
        } else {
            settings[.user] = ClaudeSettings()
        }

        // Load enterprise settings (read-only)
        if let enterpriseSettings = try? configService.loadSettings(from: configService.enterpriseSettingsPath) {
            settings[.enterprise] = enterpriseSettings
        }

        // Load MCP servers
        mcpServers = configService.loadAllMCPServers(projectPath: currentProjectPath)

        // Load memory files
        memoryFiles = configService.loadAllMemoryFiles(projectPath: currentProjectPath)

        // Load user rules
        ruleFiles = configService.loadRuleFiles(from: configService.userRulesDirectory)

        lastSyncTime = Date()
        isLoading = false
    }

    func loadProjectData() {
        guard let projectPath = currentProjectPath else {
            // Clear project-specific data
            settings.removeValue(forKey: .project)
            settings.removeValue(forKey: .local)
            mcpServers = configService.loadAllMCPServers(projectPath: nil)
            memoryFiles = configService.loadAllMemoryFiles(projectPath: nil)
            return
        }

        isLoading = true

        // Load project settings
        if let projectSettings = try? configService.loadSettings(from: configService.projectSettingsPath(for: projectPath)) {
            settings[.project] = projectSettings
        } else {
            settings[.project] = ClaudeSettings()
        }

        if let localSettings = try? configService.loadSettings(from: configService.localSettingsPath(for: projectPath)) {
            settings[.local] = localSettings
        } else {
            settings[.local] = ClaudeSettings()
        }

        // Reload MCP servers with project context
        mcpServers = configService.loadAllMCPServers(projectPath: projectPath)

        // Reload memory files with project context
        memoryFiles = configService.loadAllMemoryFiles(projectPath: projectPath)

        // Load project rules
        let projectRules = configService.loadRuleFiles(from: configService.projectRulesDirectory(for: projectPath))
        let userRules = configService.loadRuleFiles(from: configService.userRulesDirectory)
        ruleFiles = userRules + projectRules

        lastSyncTime = Date()
        isLoading = false
    }

    func refresh() {
        loadUserData()
        if currentProjectPath != nil {
            loadProjectData()
        }
        fileWatcher.acknowledgeChanges()
    }

    // MARK: - Settings Operations

    func saveSettings(_ newSettings: ClaudeSettings, scope: SettingsScope) {
        let path: URL
        switch scope {
        case .user:
            path = configService.userSettingsPath
        case .project:
            guard let projectPath = currentProjectPath else {
                showErrorMessage("No project selected")
                return
            }
            path = configService.projectSettingsPath(for: projectPath)
        case .local:
            guard let projectPath = currentProjectPath else {
                showErrorMessage("No project selected")
                return
            }
            path = configService.localSettingsPath(for: projectPath)
        case .enterprise:
            showErrorMessage("Cannot modify enterprise settings")
            return
        }

        do {
            let oldSettings = settings[scope]
            fileWatcher.markAsInternalWrite(path)
            try configService.saveSettings(newSettings, to: path)
            self.settings[scope] = newSettings
            lastSyncTime = Date()

            // Record history
            historyService.recordSettingsChange(
                scope: scope.rawValue,
                oldSettings: oldSettings,
                newSettings: newSettings
            )
        } catch {
            showErrorMessage("Failed to save settings: \(error.localizedDescription)")
        }
    }

    func getSettings(for scope: SettingsScope) -> ClaudeSettings {
        settings[scope] ?? ClaudeSettings()
    }

    // MARK: - MCP Operations

    func addMCPServer(name: String, server: MCPServer, scope: MCPScope) {
        do {
            var filePath: String?

            switch scope {
            case .user:
                filePath = configService.userMCPPath.path
                fileWatcher.markAsInternalWrite(configService.userMCPPath)
                var config = try configService.loadUserClaudeConfig()
                var servers = config.mcpServers ?? [:]
                servers[name] = server
                config.mcpServers = servers
                try configService.saveUserClaudeConfig(config)

            case .project:
                guard let projectPath = currentProjectPath else {
                    showErrorMessage("No project selected")
                    return
                }
                let mcpPath = configService.projectMCPPath(for: projectPath)
                filePath = mcpPath.path
                fileWatcher.markAsInternalWrite(mcpPath)
                var config = try configService.loadMCPConfig(from: mcpPath)
                var servers = config.mcpServers ?? [:]
                servers[name] = server
                config.mcpServers = servers
                try configService.saveMCPConfig(config, to: mcpPath)

            case .local, .enterprise:
                showErrorMessage("Cannot add servers to this scope")
                return
            }

            // Record history
            historyService.recordMCPChange(
                action: .create,
                scope: scope.rawValue,
                serverName: name,
                oldServer: nil,
                newServer: server,
                filePath: filePath
            )

            // Refresh MCP list
            mcpServers = configService.loadAllMCPServers(projectPath: currentProjectPath)
            lastSyncTime = Date()
        } catch {
            showErrorMessage("Failed to add MCP server: \(error.localizedDescription)")
        }
    }

    func updateMCPServer(name: String, server: MCPServer, scope: MCPScope) {
        do {
            var filePath: String?
            var oldServer: MCPServer?

            switch scope {
            case .user:
                filePath = configService.userMCPPath.path
                fileWatcher.markAsInternalWrite(configService.userMCPPath)
                var config = try configService.loadUserClaudeConfig()
                oldServer = config.mcpServers?[name]
                config.mcpServers?[name] = server
                try configService.saveUserClaudeConfig(config)

            case .project:
                guard let projectPath = currentProjectPath else { return }
                let mcpPath = configService.projectMCPPath(for: projectPath)
                filePath = mcpPath.path
                fileWatcher.markAsInternalWrite(mcpPath)
                var config = try configService.loadMCPConfig(from: mcpPath)
                oldServer = config.mcpServers?[name]
                config.mcpServers?[name] = server
                try configService.saveMCPConfig(config, to: mcpPath)

            default:
                return
            }

            // Record history
            historyService.recordMCPChange(
                action: .update,
                scope: scope.rawValue,
                serverName: name,
                oldServer: oldServer,
                newServer: server,
                filePath: filePath
            )

            mcpServers = configService.loadAllMCPServers(projectPath: currentProjectPath)
            lastSyncTime = Date()
        } catch {
            showErrorMessage("Failed to update MCP server: \(error.localizedDescription)")
        }
    }

    func removeMCPServer(_ entry: MCPServerEntry) {
        do {
            var filePath: String?

            switch entry.scope {
            case .user:
                filePath = configService.userMCPPath.path
                fileWatcher.markAsInternalWrite(configService.userMCPPath)
                var config = try configService.loadUserClaudeConfig()
                config.mcpServers?.removeValue(forKey: entry.name)
                try configService.saveUserClaudeConfig(config)

            case .project:
                guard let projectPath = currentProjectPath else {
                    showErrorMessage("Cannot delete project-scoped server: No project is open. Open the project first to delete this server.")
                    return
                }
                let mcpPath = configService.projectMCPPath(for: projectPath)
                filePath = mcpPath.path
                fileWatcher.markAsInternalWrite(mcpPath)
                var config = try configService.loadMCPConfig(from: mcpPath)
                config.mcpServers?.removeValue(forKey: entry.name)
                try configService.saveMCPConfig(config, to: mcpPath)

            case .local, .enterprise:
                showErrorMessage("Cannot remove servers from this scope")
                return
            }

            // Record history
            historyService.recordMCPChange(
                action: .delete,
                scope: entry.scope.rawValue,
                serverName: entry.name,
                oldServer: entry.server,
                newServer: nil,
                filePath: filePath
            )

            mcpServers = configService.loadAllMCPServers(projectPath: currentProjectPath)
            lastSyncTime = Date()
        } catch {
            showErrorMessage("Failed to remove MCP server: \(error.localizedDescription)")
        }
    }

    // MARK: - Memory Operations

    func saveMemoryFile(_ file: MemoryFile) {
        do {
            // Get old content for history
            let oldContent = configService.loadMemoryContent(from: file.path)
            let isNew = oldContent == nil

            fileWatcher.markAsInternalWrite(file.path)
            try configService.saveMemoryContent(file.content, to: file.path)
            memoryFiles = configService.loadAllMemoryFiles(projectPath: currentProjectPath)
            lastSyncTime = Date()

            // Record history
            historyService.recordMemoryChange(
                action: isNew ? .create : .update,
                scope: file.scope.rawValue,
                fileName: file.fileName,
                oldContent: oldContent,
                newContent: file.content,
                filePath: file.path.path
            )
        } catch {
            showErrorMessage("Failed to save memory file: \(error.localizedDescription)")
        }
    }

    func createMemoryFile(scope: MemoryScope, initialContent: String = "") {
        let path: URL
        switch scope {
        case .user:
            path = configService.userMemoryPath
        case .project:
            guard let projectPath = currentProjectPath else {
                showErrorMessage("No project selected")
                return
            }
            path = configService.projectMemoryPath(for: projectPath)
        case .local:
            guard let projectPath = currentProjectPath else {
                showErrorMessage("No project selected")
                return
            }
            path = configService.localMemoryPath(for: projectPath)
        case .enterprise:
            showErrorMessage("Cannot create enterprise memory file")
            return
        }

        let content = initialContent.isEmpty ? "# Claude Code Instructions\n\nAdd your instructions here.\n" : initialContent
        do {
            fileWatcher.markAsInternalWrite(path)
            try configService.saveMemoryContent(content, to: path)
            memoryFiles = configService.loadAllMemoryFiles(projectPath: currentProjectPath)
            lastSyncTime = Date()

            // Record history
            historyService.recordMemoryChange(
                action: .create,
                scope: scope.rawValue,
                fileName: path.lastPathComponent,
                oldContent: nil,
                newContent: content,
                filePath: path.path
            )
        } catch {
            showErrorMessage("Failed to create memory file: \(error.localizedDescription)")
        }
    }

    // MARK: - Rule Operations

    func saveRuleFile(_ rule: RuleFile) {
        do {
            // Check if this is a new file or update
            let isNew = !FileManager.default.fileExists(atPath: rule.path.path)
            let oldContent: String? = isNew ? nil : try? String(contentsOf: rule.path, encoding: .utf8)

            fileWatcher.markAsInternalWrite(rule.path)
            try configService.saveRuleFile(rule)
            refreshRules()
            lastSyncTime = Date()

            // Record history
            historyService.recordRuleChange(
                action: isNew ? .create : .update,
                ruleName: rule.name,
                oldContent: oldContent,
                newContent: rule.content,
                filePath: rule.path.path
            )
        } catch {
            showErrorMessage("Failed to save rule: \(error.localizedDescription)")
        }
    }

    func deleteRuleFile(_ rule: RuleFile) {
        do {
            fileWatcher.markAsInternalWrite(rule.path)
            try configService.deleteRuleFile(rule)
            refreshRules()
            lastSyncTime = Date()

            // Record history
            historyService.recordRuleChange(
                action: .delete,
                ruleName: rule.name,
                oldContent: rule.content,
                newContent: nil,
                filePath: rule.path.path
            )
        } catch {
            showErrorMessage("Failed to delete rule: \(error.localizedDescription)")
        }
    }

    private func refreshRules() {
        var allRules = configService.loadRuleFiles(from: configService.userRulesDirectory)
        if let projectPath = currentProjectPath {
            allRules += configService.loadRuleFiles(from: configService.projectRulesDirectory(for: projectPath))
        }
        ruleFiles = allRules
    }

    // MARK: - Error Handling

    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
