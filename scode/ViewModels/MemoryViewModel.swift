//
//  MemoryViewModel.swift
//  scode
//
//  Memory files view model
//

import Foundation
import SwiftUI
import Combine

/// View model for memory file management
@MainActor
class MemoryViewModel: ObservableObject {
    @Published var memoryFiles: [MemoryFile] = []
    @Published var ruleFiles: [RuleFile] = []
    @Published var selectedFile: MemoryFile?
    @Published var selectedRule: RuleFile?

    @Published var editingContent = ""
    @Published var hasChanges = false

    @Published var isAddingRule = false
    @Published var newRuleName = ""
    @Published var newRuleContent = ""
    @Published var newRulePaths = ""

    private let appState: AppState

    init(appState: AppState = .shared) {
        self.appState = appState
        loadFiles()
    }

    // MARK: - Load

    func loadFiles() {
        memoryFiles = appState.memoryFiles
        ruleFiles = appState.ruleFiles
    }

    func refresh() {
        appState.refresh()
        loadFiles()
    }

    // MARK: - Memory File Selection

    func selectMemoryFile(_ file: MemoryFile) {
        if hasChanges {
            // Prompt to save changes
            return
        }

        selectedFile = file
        selectedRule = nil
        editingContent = file.content
        hasChanges = false
    }

    func selectRuleFile(_ rule: RuleFile) {
        if hasChanges {
            // Prompt to save changes
            return
        }

        selectedRule = rule
        selectedFile = nil
        editingContent = rule.content
        hasChanges = false
    }

    // MARK: - Editing

    func updateContent(_ content: String) {
        editingContent = content
        hasChanges = true
    }

    func saveCurrentFile() {
        if let file = selectedFile {
            var updatedFile = file
            updatedFile.content = editingContent
            appState.saveMemoryFile(updatedFile)
            loadFiles()

            // Update selection
            if let updated = memoryFiles.first(where: { $0.path == file.path }) {
                selectedFile = updated
            }
        } else if let rule = selectedRule {
            do {
                var updatedRule = rule
                updatedRule.content = editingContent
                try ConfigurationService.shared.saveRuleFile(updatedRule)
                loadFiles()

                if let updated = ruleFiles.first(where: { $0.path == rule.path }) {
                    selectedRule = updated
                }
            } catch {
                appState.showErrorMessage("Failed to save rule: \(error.localizedDescription)")
            }
        }

        hasChanges = false
    }

    func revertChanges() {
        if let file = selectedFile {
            editingContent = file.content
        } else if let rule = selectedRule {
            editingContent = rule.content
        }
        hasChanges = false
    }

    // MARK: - Create Memory File

    func createMemoryFile(scope: MemoryScope) {
        let path: URL
        switch scope {
        case .user:
            path = ConfigurationService.shared.userMemoryPath
        case .project:
            guard let projectPath = appState.currentProjectPath else {
                appState.showErrorMessage("No project selected")
                return
            }
            path = ConfigurationService.shared.projectMemoryPath(for: projectPath)
        case .local:
            guard let projectPath = appState.currentProjectPath else {
                appState.showErrorMessage("No project selected")
                return
            }
            path = ConfigurationService.shared.localMemoryPath(for: projectPath)
        case .enterprise:
            appState.showErrorMessage("Cannot create enterprise memory file")
            return
        }

        let initialContent = "# Claude Code Instructions\n\nAdd your instructions here.\n"
        do {
            try ConfigurationService.shared.saveMemoryContent(initialContent, to: path)
            loadFiles()

            // Select the new file
            if let newFile = memoryFiles.first(where: { $0.path == path }) {
                selectMemoryFile(newFile)
            }
        } catch {
            appState.showErrorMessage("Failed to create memory file: \(error.localizedDescription)")
        }
    }

    // MARK: - Rule File Operations

    func resetNewRuleForm() {
        newRuleName = ""
        newRuleContent = ""
        newRulePaths = ""
    }

    func addRule() {
        guard !newRuleName.isEmpty else { return }

        let rulesDir: URL
        if let projectPath = appState.currentProjectPath {
            rulesDir = ConfigurationService.shared.projectRulesDirectory(for: projectPath)
        } else {
            rulesDir = ConfigurationService.shared.userRulesDirectory
        }

        let fileName = newRuleName.hasSuffix(".md") ? newRuleName : "\(newRuleName).md"
        let path = rulesDir.appendingPathComponent(fileName)

        var content = ""
        if !newRulePaths.isEmpty {
            content = "---\npaths: \(newRulePaths)\n---\n\n"
        }
        content += newRuleContent.isEmpty ? "# \(newRuleName)\n\nAdd your rules here.\n" : newRuleContent

        do {
            try FileSystemService.shared.createDirectory(rulesDir)
            try FileSystemService.shared.writeFile(content, to: path)
            loadFiles()

            if let newRule = ruleFiles.first(where: { $0.path == path }) {
                selectRuleFile(newRule)
            }

            resetNewRuleForm()
            isAddingRule = false
        } catch {
            appState.showErrorMessage("Failed to create rule file: \(error.localizedDescription)")
        }
    }

    func deleteRule(_ rule: RuleFile) {
        do {
            try ConfigurationService.shared.deleteRuleFile(rule)
            loadFiles()

            if selectedRule?.path == rule.path {
                selectedRule = nil
                editingContent = ""
            }
        } catch {
            appState.showErrorMessage("Failed to delete rule: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    var availableMemoryScopes: [MemoryScope] {
        if appState.currentProjectPath != nil {
            return [.user, .project, .local]
        } else {
            return [.user]
        }
    }

    func canCreateMemoryFile(for scope: MemoryScope) -> Bool {
        guard let file = memoryFiles.first(where: { $0.scope == scope }) else {
            return true
        }
        return !file.exists
    }
}
