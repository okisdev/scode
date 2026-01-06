//
//  HooksModel.swift
//  scode
//
//  Hooks configuration model
//

import Foundation

/// Hook matcher containing pattern and hook commands
struct HookMatcher: Codable, Equatable, Identifiable {
    var id = UUID()
    var matcher: String?
    var hooks: [HookCommand]

    enum CodingKeys: String, CodingKey {
        case matcher, hooks
    }

    init(matcher: String? = nil, hooks: [HookCommand] = []) {
        self.matcher = matcher
        self.hooks = hooks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matcher = try container.decodeIfPresent(String.self, forKey: .matcher)
        hooks = try container.decode([HookCommand].self, forKey: .hooks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(matcher, forKey: .matcher)
        try container.encode(hooks, forKey: .hooks)
    }
}

/// Individual hook command
struct HookCommand: Codable, Equatable, Identifiable {
    var id = UUID()
    var type: HookType
    var command: String?
    var prompt: String?
    var timeout: Int?

    enum CodingKeys: String, CodingKey {
        case type, command, prompt, timeout
    }

    init(type: HookType, command: String? = nil, prompt: String? = nil, timeout: Int? = nil) {
        self.type = type
        self.command = command
        self.prompt = prompt
        self.timeout = timeout
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(HookType.self, forKey: .type)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        timeout = try container.decodeIfPresent(Int.self, forKey: .timeout)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(prompt, forKey: .prompt)
        try container.encodeIfPresent(timeout, forKey: .timeout)
    }
}

/// Hook execution type
enum HookType: String, Codable, CaseIterable, Identifiable {
    case command
    case prompt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .command:
            return "Command"
        case .prompt:
            return "Prompt"
        }
    }

    var description: String {
        switch self {
        case .command:
            return "Execute a bash command"
        case .prompt:
            return "Send prompt to LLM for evaluation"
        }
    }
}

/// Hook event types
enum HookEventName: String, CaseIterable, Identifiable {
    case PreToolUse
    case PermissionRequest
    case PostToolUse
    case Notification
    case UserPromptSubmit
    case Stop
    case SubagentStop
    case PreCompact
    case SessionStart
    case SessionEnd

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .PreToolUse:
            return "Pre Tool Use"
        case .PermissionRequest:
            return "Permission Request"
        case .PostToolUse:
            return "Post Tool Use"
        case .Notification:
            return "Notification"
        case .UserPromptSubmit:
            return "User Prompt Submit"
        case .Stop:
            return "Stop"
        case .SubagentStop:
            return "Subagent Stop"
        case .PreCompact:
            return "Pre Compact"
        case .SessionStart:
            return "Session Start"
        case .SessionEnd:
            return "Session End"
        }
    }

    var description: String {
        switch self {
        case .PreToolUse:
            return "Runs before processing a tool call"
        case .PermissionRequest:
            return "Runs when permission dialog is shown"
        case .PostToolUse:
            return "Runs after a tool completes"
        case .Notification:
            return "Runs when Claude sends notifications"
        case .UserPromptSubmit:
            return "Runs when user submits a prompt"
        case .Stop:
            return "Runs when Claude finishes responding"
        case .SubagentStop:
            return "Runs when a subagent finishes"
        case .PreCompact:
            return "Runs before compact operation"
        case .SessionStart:
            return "Runs when session starts"
        case .SessionEnd:
            return "Runs when session ends"
        }
    }

    var icon: String {
        switch self {
        case .PreToolUse:
            return "wrench.and.screwdriver"
        case .PermissionRequest:
            return "lock.shield"
        case .PostToolUse:
            return "checkmark.circle"
        case .Notification:
            return "bell"
        case .UserPromptSubmit:
            return "text.bubble"
        case .Stop:
            return "stop.circle"
        case .SubagentStop:
            return "person.crop.circle.badge.checkmark"
        case .PreCompact:
            return "arrow.down.right.and.arrow.up.left"
        case .SessionStart:
            return "play.circle"
        case .SessionEnd:
            return "xmark.circle"
        }
    }

    var supportsMatcher: Bool {
        switch self {
        case .PreToolUse, .PermissionRequest, .PostToolUse, .Notification, .PreCompact, .SessionStart:
            return true
        case .UserPromptSubmit, .Stop, .SubagentStop, .SessionEnd:
            return false
        }
    }
}
