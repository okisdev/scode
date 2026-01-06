//
//  SettingsModel.swift
//  scode
//
//  Claude Code Settings Configuration Model
//

import Foundation

/// Main settings model representing settings.json structure
struct ClaudeSettings: Codable, Equatable {
    var apiKeyHelper: String?
    var cleanupPeriodDays: Int?
    var companyAnnouncements: [String]?
    var env: [String: String]?
    var attribution: AttributionSettings?
    var includeCoAuthoredBy: Bool?
    var permissions: PermissionSettings?
    var sandbox: SandboxSettings?
    var hooks: [String: [HookMatcher]]?
    var disableAllHooks: Bool?
    var allowManagedHooksOnly: Bool?
    var model: String?
    var otelHeadersHelper: String?
    var statusLine: StatusLineConfig?
    var fileSuggestion: FileSuggestionConfig?
    var outputStyle: String?
    var forceLoginMethod: String?
    var forceLoginOrgUUID: String?
    var enableAllProjectMcpServers: Bool?
    var enabledMcpjsonServers: [String]?
    var disabledMcpjsonServers: [String]?
    var allowedMcpServers: [MCPServerRestriction]?
    var deniedMcpServers: [MCPServerRestriction]?
    var strictKnownMarketplaces: [MarketplaceSource]?
    var awsAuthRefresh: String?
    var awsCredentialExport: String?
    var alwaysThinkingEnabled: Bool?
    var enabledPlugins: [String: Bool]?
    var extraKnownMarketplaces: [String: MarketplaceConfig]?

    init() {}
}

/// Attribution settings for git commits and PRs
struct AttributionSettings: Codable, Equatable {
    var commit: String?
    var pr: String?
}

/// Status line configuration
struct StatusLineConfig: Codable, Equatable {
    var type: String?
    var command: String?
}

/// File suggestion configuration
struct FileSuggestionConfig: Codable, Equatable {
    var type: String?
    var command: String?
}

/// MCP server restriction entry
struct MCPServerRestriction: Codable, Equatable {
    var serverName: String?
    var serverCommand: [String]?
    var serverUrl: String?
}

/// Marketplace source configuration
struct MarketplaceSource: Codable, Equatable {
    var source: String?
    var repo: String?
    var url: String?
    var `ref`: String?
    var path: String?
    var `package`: String?
    var headers: [String: String]?
}

/// Marketplace configuration with nested source
struct MarketplaceConfig: Codable, Equatable {
    var source: MarketplaceSource?
}

// MARK: - Settings Scope

/// Represents different scopes where settings can be stored
enum SettingsScope: String, CaseIterable, Identifiable {
    case user = "User"
    case project = "Project"
    case local = "Local"
    case enterprise = "Enterprise"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .user:
            return "Personal settings across all projects"
        case .project:
            return "Team-shared project settings"
        case .local:
            return "Personal project-specific settings"
        case .enterprise:
            return "Organization-wide managed settings"
        }
    }

    var icon: String {
        switch self {
        case .user:
            return "person.fill"
        case .project:
            return "folder.fill"
        case .local:
            return "laptopcomputer"
        case .enterprise:
            return "building.2.fill"
        }
    }
}
