//
//  PermissionsModel.swift
//  scode
//
//  Permission settings model
//

import Foundation

/// Permission settings structure
struct PermissionSettings: Codable, Equatable {
    var allow: [String]?
    var ask: [String]?
    var deny: [String]?
    var additionalDirectories: [String]?
    var defaultMode: String?
    var disableBypassPermissionsMode: String?

    init() {}
}

/// Permission mode options
enum PermissionMode: String, CaseIterable, Identifiable {
    case `default` = "default"
    case plan = "plan"
    case acceptEdits = "acceptEdits"
    case dontAsk = "dontAsk"
    case bypassPermissions = "bypassPermissions"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .plan:
            return "Plan Mode"
        case .acceptEdits:
            return "Accept Edits"
        case .dontAsk:
            return "Don't Ask"
        case .bypassPermissions:
            return "Bypass Permissions"
        }
    }

    var description: String {
        switch self {
        case .default:
            return "Standard permission prompts"
        case .plan:
            return "Planning mode without execution"
        case .acceptEdits:
            return "Auto-accept file edits"
        case .dontAsk:
            return "Skip all permission prompts"
        case .bypassPermissions:
            return "Bypass all permission checks"
        }
    }
}

/// Permission rule type
enum PermissionRuleType: String, CaseIterable, Identifiable {
    case allow
    case ask
    case deny

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .allow:
            return "Allow"
        case .ask:
            return "Ask"
        case .deny:
            return "Deny"
        }
    }

    var color: String {
        switch self {
        case .allow:
            return "green"
        case .ask:
            return "yellow"
        case .deny:
            return "red"
        }
    }
}

/// Represents a single permission rule
struct PermissionRule: Identifiable, Equatable {
    var id = UUID()
    var type: PermissionRuleType
    var pattern: String

    init(type: PermissionRuleType, pattern: String) {
        self.type = type
        self.pattern = pattern
    }
}

/// Known tool names for permission rules
enum KnownTool: String, CaseIterable {
    case Bash
    case Read
    case Write
    case Edit
    case Glob
    case Grep
    case WebFetch
    case WebSearch
    case Task
    case NotebookEdit

    var description: String {
        switch self {
        case .Bash:
            return "Shell command execution"
        case .Read:
            return "File reading"
        case .Write:
            return "File creation/overwriting"
        case .Edit:
            return "File editing"
        case .Glob:
            return "File pattern matching"
        case .Grep:
            return "Content search"
        case .WebFetch:
            return "URL content fetching"
        case .WebSearch:
            return "Web search"
        case .Task:
            return "Subagent tasks"
        case .NotebookEdit:
            return "Jupyter notebook editing"
        }
    }
}
