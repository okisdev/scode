//
//  SettingsViewModel.swift
//  scode
//
//  Settings view model
//

import Foundation
import SwiftUI
import Combine

/// View model for settings management
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var currentSettings: ClaudeSettings
    @Published var selectedScope: SettingsScope
    @Published var hasChanges = false
    @Published var validationResult: ValidationService.ValidationResult?

    private let appState: AppState
    private var originalSettings: ClaudeSettings

    init(appState: AppState = .shared) {
        self.appState = appState
        self.selectedScope = appState.selectedSettingsScope
        let settings = appState.getSettings(for: appState.selectedSettingsScope)
        self.currentSettings = settings
        self.originalSettings = settings
    }

    // MARK: - Scope Management

    func switchScope(to scope: SettingsScope) {
        if hasChanges {
            // Prompt to save changes before switching
            return
        }

        selectedScope = scope
        appState.selectedSettingsScope = scope
        currentSettings = appState.getSettings(for: scope)
        originalSettings = currentSettings
        hasChanges = false
        validationResult = nil
    }

    var canEdit: Bool {
        selectedScope != .enterprise
    }

    var scopeDescription: String {
        switch selectedScope {
        case .user:
            return "Settings apply to all your projects"
        case .project:
            return "Settings are shared with your team"
        case .local:
            return "Settings are personal to this project"
        case .enterprise:
            return "Settings are managed by your organization (read-only)"
        }
    }

    // MARK: - Settings Updates

    func updateSettings(_ update: (inout ClaudeSettings) -> Void) {
        var settings = currentSettings
        update(&settings)
        currentSettings = settings
        hasChanges = currentSettings != originalSettings
        validate()
    }

    // MARK: - Permissions

    func addPermissionRule(type: PermissionRuleType, pattern: String) {
        updateSettings { settings in
            var permissions = settings.permissions ?? PermissionSettings()
            switch type {
            case .allow:
                var rules = permissions.allow ?? []
                rules.append(pattern)
                permissions.allow = rules
            case .ask:
                var rules = permissions.ask ?? []
                rules.append(pattern)
                permissions.ask = rules
            case .deny:
                var rules = permissions.deny ?? []
                rules.append(pattern)
                permissions.deny = rules
            }
            settings.permissions = permissions
        }
    }

    func removePermissionRule(type: PermissionRuleType, at index: Int) {
        updateSettings { settings in
            var permissions = settings.permissions ?? PermissionSettings()
            switch type {
            case .allow:
                permissions.allow?.remove(at: index)
            case .ask:
                permissions.ask?.remove(at: index)
            case .deny:
                permissions.deny?.remove(at: index)
            }
            settings.permissions = permissions
        }
    }

    func updatePermissionRule(type: PermissionRuleType, at index: Int, with pattern: String) {
        updateSettings { settings in
            var permissions = settings.permissions ?? PermissionSettings()
            switch type {
            case .allow:
                permissions.allow?[index] = pattern
            case .ask:
                permissions.ask?[index] = pattern
            case .deny:
                permissions.deny?[index] = pattern
            }
            settings.permissions = permissions
        }
    }

    // MARK: - Environment Variables

    func addEnvironmentVariable(key: String, value: String) {
        updateSettings { settings in
            var env = settings.env ?? [:]
            env[key] = value
            settings.env = env
        }
    }

    func removeEnvironmentVariable(key: String) {
        updateSettings { settings in
            settings.env?.removeValue(forKey: key)
        }
    }

    func updateEnvironmentVariable(key: String, value: String) {
        updateSettings { settings in
            settings.env?[key] = value
        }
    }

    // MARK: - Sandbox

    func updateSandbox(_ update: (inout SandboxSettings) -> Void) {
        updateSettings { settings in
            var sandbox = settings.sandbox ?? SandboxSettings()
            update(&sandbox)
            settings.sandbox = sandbox
        }
    }

    // MARK: - Validation & Save

    func validate() {
        validationResult = ValidationService.shared.validateSettings(currentSettings)
    }

    func save() {
        validate()

        guard validationResult?.isValid != false else {
            return
        }

        appState.saveSettings(currentSettings, scope: selectedScope)
        originalSettings = currentSettings
        hasChanges = false
    }

    func revert() {
        currentSettings = originalSettings
        hasChanges = false
        validationResult = nil
    }
}
