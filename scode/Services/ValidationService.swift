//
//  ValidationService.swift
//  scode
//
//  Configuration validation service
//

import Foundation

/// Service for validating Claude Code configurations
class ValidationService {
    static let shared = ValidationService()

    // MARK: - Permission Validation

    struct ValidationResult {
        var isValid: Bool
        var errors: [ValidationError]
        var warnings: [ValidationWarning]
    }

    struct ValidationError: Identifiable {
        var id = UUID()
        var field: String
        var message: String
    }

    struct ValidationWarning: Identifiable {
        var id = UUID()
        var field: String
        var message: String
    }

    func validatePermissionRule(_ rule: String) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Check basic format: Tool(pattern) or Tool
        let toolPattern = #"^([A-Za-z]+)(\(.*\))?$"#
        guard let regex = try? NSRegularExpression(pattern: toolPattern),
              regex.firstMatch(in: rule, range: NSRange(rule.startIndex..., in: rule)) != nil else {
            errors.append(ValidationError(
                field: "pattern",
                message: "Invalid format. Expected: Tool or Tool(pattern)"
            ))
            return ValidationResult(isValid: false, errors: errors, warnings: warnings)
        }

        // Extract tool name
        let toolName = rule.components(separatedBy: "(").first ?? rule

        // Check if tool is known
        let knownTools = KnownTool.allCases.map { $0.rawValue }
        if !knownTools.contains(toolName) && !toolName.hasPrefix("mcp__") {
            warnings.append(ValidationWarning(
                field: "tool",
                message: "Unknown tool: \(toolName). Known tools: \(knownTools.joined(separator: ", "))"
            ))
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }

    // MARK: - Settings Validation

    func validateSettings(_ settings: ClaudeSettings) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate cleanupPeriodDays
        if let days = settings.cleanupPeriodDays, days < 0 {
            errors.append(ValidationError(
                field: "cleanupPeriodDays",
                message: "Cleanup period must be non-negative"
            ))
        }

        // Validate permissions
        if let permissions = settings.permissions {
            for rule in permissions.allow ?? [] {
                let result = validatePermissionRule(rule)
                errors.append(contentsOf: result.errors)
                warnings.append(contentsOf: result.warnings)
            }
            for rule in permissions.deny ?? [] {
                let result = validatePermissionRule(rule)
                errors.append(contentsOf: result.errors)
                warnings.append(contentsOf: result.warnings)
            }
        }

        // Validate sandbox settings
        if let sandbox = settings.sandbox {
            if let httpPort = sandbox.network?.httpProxyPort, (httpPort < 1 || httpPort > 65535) {
                errors.append(ValidationError(
                    field: "sandbox.network.httpProxyPort",
                    message: "HTTP proxy port must be between 1 and 65535"
                ))
            }
            if let socksPort = sandbox.network?.socksProxyPort, (socksPort < 1 || socksPort > 65535) {
                errors.append(ValidationError(
                    field: "sandbox.network.socksProxyPort",
                    message: "SOCKS proxy port must be between 1 and 65535"
                ))
            }
        }

        // Validate forceLoginMethod
        if let method = settings.forceLoginMethod {
            let validMethods = ["claudeai", "console"]
            if !validMethods.contains(method) {
                errors.append(ValidationError(
                    field: "forceLoginMethod",
                    message: "Invalid login method. Must be 'claudeai' or 'console'"
                ))
            }
        }

        // Validate defaultMode
        if let mode = settings.permissions?.defaultMode {
            let validModes = PermissionMode.allCases.map { $0.rawValue }
            if !validModes.contains(mode) {
                errors.append(ValidationError(
                    field: "permissions.defaultMode",
                    message: "Invalid permission mode. Valid modes: \(validModes.joined(separator: ", "))"
                ))
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }

    // MARK: - MCP Validation

    func validateMCPServer(_ server: MCPServer) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate based on type
        if let type = server.type {
            switch type {
            case .http, .sse:
                if server.url == nil || server.url?.isEmpty == true {
                    errors.append(ValidationError(
                        field: "url",
                        message: "URL is required for \(type.displayName) transport"
                    ))
                } else if let url = server.url, !url.hasPrefix("http://") && !url.hasPrefix("https://") {
                    errors.append(ValidationError(
                        field: "url",
                        message: "URL must start with http:// or https://"
                    ))
                }

                if type == .sse {
                    warnings.append(ValidationWarning(
                        field: "type",
                        message: "SSE transport is deprecated. Consider using HTTP instead"
                    ))
                }

            case .stdio:
                if server.command == nil || server.command?.isEmpty == true {
                    errors.append(ValidationError(
                        field: "command",
                        message: "Command is required for stdio transport"
                    ))
                }
            }
        } else {
            errors.append(ValidationError(
                field: "type",
                message: "Transport type is required"
            ))
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }

    // MARK: - Hook Validation

    func validateHook(_ hook: HookCommand) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        switch hook.type {
        case .command:
            if hook.command == nil || hook.command?.isEmpty == true {
                errors.append(ValidationError(
                    field: "command",
                    message: "Command is required for command-type hooks"
                ))
            }
        case .prompt:
            if hook.prompt == nil || hook.prompt?.isEmpty == true {
                errors.append(ValidationError(
                    field: "prompt",
                    message: "Prompt is required for prompt-type hooks"
                ))
            }
        }

        // Validate timeout
        if let timeout = hook.timeout, timeout < 0 {
            errors.append(ValidationError(
                field: "timeout",
                message: "Timeout must be non-negative"
            ))
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
}
