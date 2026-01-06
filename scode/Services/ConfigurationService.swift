//
//  ConfigurationService.swift
//  scode
//
//  Service for reading and writing Claude Code configuration files
//

import Foundation
import Combine

/// Service for managing Claude Code configurations
@MainActor
class ConfigurationService: ObservableObject {
    static let shared = ConfigurationService()

    // MARK: - Path Constants

    /// Real user home directory (not sandbox container)
    private var homeDirectory: URL {
        // Try to get real home from passwd entry
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: home))
        }
        // Fallback to HOME environment variable
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            return URL(fileURLWithPath: home)
        }
        // Last resort
        return FileManager.default.homeDirectoryForCurrentUser
    }

    /// User settings path: ~/.claude/settings.json
    var userSettingsPath: URL {
        homeDirectory.appendingPathComponent(".claude/settings.json")
    }

    /// User MCP config path: ~/.claude.json
    var userMCPPath: URL {
        homeDirectory.appendingPathComponent(".claude.json")
    }

    /// User memory path: ~/.claude/CLAUDE.md
    var userMemoryPath: URL {
        homeDirectory.appendingPathComponent(".claude/CLAUDE.md")
    }

    /// User rules directory: ~/.claude/rules/
    var userRulesDirectory: URL {
        homeDirectory.appendingPathComponent(".claude/rules")
    }

    /// Enterprise settings path (macOS)
    var enterpriseSettingsPath: URL {
        URL(fileURLWithPath: "/Library/Application Support/ClaudeCode/managed-settings.json")
    }

    /// Enterprise MCP path (macOS)
    var enterpriseMCPPath: URL {
        URL(fileURLWithPath: "/Library/Application Support/ClaudeCode/managed-mcp.json")
    }

    /// Enterprise memory path (macOS)
    var enterpriseMemoryPath: URL {
        URL(fileURLWithPath: "/Library/Application Support/ClaudeCode/CLAUDE.md")
    }

    // MARK: - Project Paths

    func projectSettingsPath(for projectPath: URL) -> URL {
        projectPath.appendingPathComponent(".claude/settings.json")
    }

    func localSettingsPath(for projectPath: URL) -> URL {
        projectPath.appendingPathComponent(".claude/settings.local.json")
    }

    func projectMCPPath(for projectPath: URL) -> URL {
        projectPath.appendingPathComponent(".mcp.json")
    }

    func projectMemoryPath(for projectPath: URL) -> URL {
        // Check both possible locations
        let dotClaudePath = projectPath.appendingPathComponent(".claude/CLAUDE.md")
        let rootPath = projectPath.appendingPathComponent("CLAUDE.md")

        if FileManager.default.fileExists(atPath: dotClaudePath.path) {
            return dotClaudePath
        }
        return rootPath
    }

    func localMemoryPath(for projectPath: URL) -> URL {
        projectPath.appendingPathComponent("CLAUDE.local.md")
    }

    func projectRulesDirectory(for projectPath: URL) -> URL {
        projectPath.appendingPathComponent(".claude/rules")
    }

    // MARK: - Settings Operations

    func loadSettings(from path: URL) throws -> ClaudeSettings {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return ClaudeSettings()
        }

        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try decoder.decode(ClaudeSettings.self, from: data)
    }

    func saveSettings(_ settings: ClaudeSettings, to path: URL) throws {
        // Ensure directory exists
        let directory = path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Soft edit: load original JSON, merge with updates, then write
        let originalDict = loadRawJSON(from: path)
        let updatesDict = try encodeToDictionary(settings)
        let mergedDict = deepMerge(originalDict, with: updatesDict)

        let data = try JSONSerialization.data(withJSONObject: mergedDict, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: path)
    }

    // MARK: - Soft Edit Helpers

    /// Convert an Encodable object to a dictionary
    private func encodeToDictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    /// Load raw JSON dictionary from file
    private func loadRawJSON(from path: URL) -> [String: Any] {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: path)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return [:]
            }
            return dict
        } catch {
            // File exists but parsing failed - return empty dict (will overwrite)
            print("[Warning] Failed to parse existing JSON at \(path.path): \(error)")
            return [:]
        }
    }

    /// Deep merge two dictionaries (updates override original, preserving unknown fields)
    private func deepMerge(_ original: [String: Any], with updates: [String: Any]) -> [String: Any] {
        var result = original

        for (key, newValue) in updates {
            if let originalDict = original[key] as? [String: Any],
               let updateDict = newValue as? [String: Any] {
                // Nested dictionary: merge recursively
                result[key] = deepMerge(originalDict, with: updateDict)
            } else {
                // Non-dictionary: override with new value
                result[key] = newValue
            }
        }

        return result
    }

    func loadAllSettings(projectPath: URL?) -> [SettingsScope: ClaudeSettings] {
        var result: [SettingsScope: ClaudeSettings] = [:]

        // Enterprise settings
        if let settings = try? loadSettings(from: enterpriseSettingsPath) {
            result[.enterprise] = settings
        }

        // User settings
        if let settings = try? loadSettings(from: userSettingsPath) {
            result[.user] = settings
        }

        // Project settings
        if let projectPath = projectPath {
            if let settings = try? loadSettings(from: projectSettingsPath(for: projectPath)) {
                result[.project] = settings
            }

            if let settings = try? loadSettings(from: localSettingsPath(for: projectPath)) {
                result[.local] = settings
            }
        }

        return result
    }

    // MARK: - MCP Operations

    func loadMCPConfig(from path: URL) throws -> MCPConfig {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return MCPConfig()
        }

        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try decoder.decode(MCPConfig.self, from: data)
    }

    func saveMCPConfig(_ config: MCPConfig, to path: URL) throws {
        let directory = path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: path)
    }

    func loadUserClaudeConfig() throws -> UserClaudeConfig {
        guard FileManager.default.fileExists(atPath: userMCPPath.path) else {
            return UserClaudeConfig()
        }

        let data = try Data(contentsOf: userMCPPath)

        // 使用 JSONSerialization 手动解析以处理复杂结构
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return UserClaudeConfig()
        }

        var config = UserClaudeConfig()

        // 解析顶级 mcpServers
        if let serversDict = json["mcpServers"] as? [String: Any], !serversDict.isEmpty {
            let serversData = try JSONSerialization.data(withJSONObject: serversDict)
            config.mcpServers = try JSONDecoder().decode([String: MCPServer].self, from: serversData)
        }

        // 解析 projects 中的 mcpServers
        if let projects = json["projects"] as? [String: Any] {
            var projectConfigs: [String: UserClaudeConfig.ProjectConfig] = [:]

            for (path, projectData) in projects {
                guard let projectDict = projectData as? [String: Any] else { continue }

                var projectConfig = UserClaudeConfig.ProjectConfig()

                if let servers = projectDict["mcpServers"] as? [String: Any], !servers.isEmpty {
                    let serversData = try JSONSerialization.data(withJSONObject: servers)
                    projectConfig.mcpServers = try JSONDecoder().decode([String: MCPServer].self, from: serversData)
                }

                if let tools = projectDict["allowedTools"] as? [String] {
                    projectConfig.allowedTools = tools
                }

                projectConfigs[path] = projectConfig
            }

            config.projects = projectConfigs
        }

        return config
    }

    func saveUserClaudeConfig(_ config: UserClaudeConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: userMCPPath)
    }

    func loadAllMCPServers(projectPath: URL?) -> [MCPServerEntry] {
        var entries: [MCPServerEntry] = []
        var addedServers: Set<String> = [] // Track added servers to avoid duplicates

        // Enterprise MCP
        if let config = try? loadMCPConfig(from: enterpriseMCPPath),
           let servers = config.mcpServers {
            for (name, server) in servers {
                entries.append(MCPServerEntry(name: name, server: server, scope: .enterprise))
                addedServers.insert(name)
            }
        }

        // User MCP (from ~/.claude.json)
        if let config = try? loadUserClaudeConfig() {
            // Top-level mcpServers (global user servers)
            if let servers = config.mcpServers {
                for (name, server) in servers {
                    if !addedServers.contains(name) {
                        entries.append(MCPServerEntry(name: name, server: server, scope: .user))
                        addedServers.insert(name)
                    }
                }
            }

            // Project-specific servers from ~/.claude.json
            if let projects = config.projects {
                if let projectPath = projectPath {
                    // Load servers for specific project
                    if let projectConfig = projects[projectPath.path],
                       let projectServers = projectConfig.mcpServers {
                        for (name, server) in projectServers {
                            if !addedServers.contains(name) {
                                entries.append(MCPServerEntry(name: name, server: server, scope: .user))
                                addedServers.insert(name)
                            }
                        }
                    }
                } else {
                    // No project selected - load all MCP servers from all projects
                    for (_, projectConfig) in projects {
                        if let projectServers = projectConfig.mcpServers {
                            for (name, server) in projectServers {
                                if !addedServers.contains(name) {
                                    entries.append(MCPServerEntry(name: name, server: server, scope: .user))
                                    addedServers.insert(name)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Project MCP (from .mcp.json in project directory)
        if let projectPath = projectPath {
            if let config = try? loadMCPConfig(from: projectMCPPath(for: projectPath)),
               let servers = config.mcpServers {
                for (name, server) in servers {
                    if !addedServers.contains(name) {
                        entries.append(MCPServerEntry(name: name, server: server, scope: .project))
                    }
                }
            }
        }

        return entries
    }

    // MARK: - Memory Operations

    func loadMemoryContent(from path: URL) -> String? {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        return try? String(contentsOf: path, encoding: .utf8)
    }

    func saveMemoryContent(_ content: String, to path: URL) throws {
        let directory = path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    func loadAllMemoryFiles(projectPath: URL?) -> [MemoryFile] {
        var files: [MemoryFile] = []

        // Enterprise memory
        let enterpriseContent = loadMemoryContent(from: enterpriseMemoryPath)
        files.append(MemoryFile(
            path: enterpriseMemoryPath,
            scope: .enterprise,
            content: enterpriseContent ?? "",
            exists: enterpriseContent != nil,
            isEditable: false
        ))

        // User memory
        let userContent = loadMemoryContent(from: userMemoryPath)
        files.append(MemoryFile(
            path: userMemoryPath,
            scope: .user,
            content: userContent ?? "",
            exists: userContent != nil,
            isEditable: true
        ))

        // Project memory
        if let projectPath = projectPath {
            let projectMemory = projectMemoryPath(for: projectPath)
            let projectContent = loadMemoryContent(from: projectMemory)
            files.append(MemoryFile(
                path: projectMemory,
                scope: .project,
                content: projectContent ?? "",
                exists: projectContent != nil,
                isEditable: true
            ))

            // Local memory
            let localMemory = localMemoryPath(for: projectPath)
            let localContent = loadMemoryContent(from: localMemory)
            files.append(MemoryFile(
                path: localMemory,
                scope: .local,
                content: localContent ?? "",
                exists: localContent != nil,
                isEditable: true
            ))
        }

        return files
    }

    // MARK: - Rules Operations

    func loadRuleFiles(from directory: URL) -> [RuleFile] {
        var rules: [RuleFile] = []

        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return rules
        }

        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "md" else { continue }

            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                rules.append(RuleFile(path: fileURL, content: content))
            }
        }

        return rules.sorted { $0.name < $1.name }
    }

    func saveRuleFile(_ rule: RuleFile) throws {
        let directory = rule.path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try rule.content.write(to: rule.path, atomically: true, encoding: .utf8)
    }

    func deleteRuleFile(_ rule: RuleFile) throws {
        try FileManager.default.removeItem(at: rule.path)
    }

    // MARK: - Utility

    func fileExists(at path: URL) -> Bool {
        FileManager.default.fileExists(atPath: path.path)
    }

    func ensureDirectoryExists(at path: URL) throws {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
    }
}
