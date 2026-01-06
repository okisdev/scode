//
//  HistoryService.swift
//  scode
//
//  Service for managing configuration change history
//

import Foundation
import Combine

/// Service for tracking and managing configuration changes
@MainActor
class HistoryService: ObservableObject {
    static let shared = HistoryService()

    @Published var history: ChangeHistoryStore = ChangeHistoryStore()

    private let historyPath: URL

    init() {
        // Store history in ~/.scode/history.json
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            let homeDir = URL(fileURLWithPath: String(cString: home))
            historyPath = homeDir.appendingPathComponent(".scode/history.json")
        } else {
            historyPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".scode/history.json")
        }

        loadHistory()
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyPath.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: historyPath)
            history = try JSONDecoder().decode(ChangeHistoryStore.self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let directory = historyPath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            try data.write(to: historyPath)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    // MARK: - Recording Changes

    func recordChange(
        type: ChangeType,
        action: ChangeAction,
        scope: String,
        target: String,
        description: String,
        oldContent: String? = nil,
        newContent: String? = nil,
        filePath: String? = nil
    ) {
        let record = ChangeRecord(
            type: type,
            action: action,
            scope: scope,
            target: target,
            description: description,
            oldContent: oldContent,
            newContent: newContent,
            filePath: filePath
        )

        history.add(record)
        saveHistory()
    }

    // MARK: - Convenience Methods

    func recordSettingsChange(scope: String, oldSettings: ClaudeSettings?, newSettings: ClaudeSettings) {
        let oldContent = oldSettings.flatMap { try? jsonString(from: $0) }
        let newContent = try? jsonString(from: newSettings)

        recordChange(
            type: .settings,
            action: oldSettings == nil ? .create : .update,
            scope: scope,
            target: "settings.json",
            description: "Updated \(scope) settings",
            oldContent: oldContent,
            newContent: newContent
        )
    }

    func recordMCPChange(
        action: ChangeAction,
        scope: String,
        serverName: String,
        oldServer: MCPServer? = nil,
        newServer: MCPServer? = nil,
        filePath: String? = nil
    ) {
        let oldContent = oldServer.flatMap { try? jsonString(from: $0) }
        let newContent = newServer.flatMap { try? jsonString(from: $0) }

        let description: String
        switch action {
        case .create: description = "Added MCP server '\(serverName)'"
        case .update: description = "Updated MCP server '\(serverName)'"
        case .delete: description = "Removed MCP server '\(serverName)'"
        }

        recordChange(
            type: .mcp,
            action: action,
            scope: scope,
            target: serverName,
            description: description,
            oldContent: oldContent,
            newContent: newContent,
            filePath: filePath
        )
    }

    func recordMemoryChange(
        action: ChangeAction,
        scope: String,
        fileName: String,
        oldContent: String? = nil,
        newContent: String? = nil,
        filePath: String? = nil
    ) {
        let description: String
        switch action {
        case .create: description = "Created \(scope) memory file"
        case .update: description = "Updated \(scope) memory file"
        case .delete: description = "Deleted \(scope) memory file"
        }

        recordChange(
            type: .memory,
            action: action,
            scope: scope,
            target: fileName,
            description: description,
            oldContent: oldContent,
            newContent: newContent,
            filePath: filePath
        )
    }

    func recordRuleChange(
        action: ChangeAction,
        ruleName: String,
        oldContent: String? = nil,
        newContent: String? = nil,
        filePath: String? = nil
    ) {
        let description: String
        switch action {
        case .create: description = "Created rule '\(ruleName)'"
        case .update: description = "Updated rule '\(ruleName)'"
        case .delete: description = "Deleted rule '\(ruleName)'"
        }

        recordChange(
            type: .rules,
            action: action,
            scope: "Rules",
            target: ruleName,
            description: description,
            oldContent: oldContent,
            newContent: newContent,
            filePath: filePath
        )
    }

    // MARK: - Revert

    func revert(_ record: ChangeRecord) throws {
        guard record.canRevert else {
            throw HistoryError.cannotRevert
        }

        guard let filePath = record.filePath else {
            throw HistoryError.missingFilePath
        }

        let fileURL = URL(fileURLWithPath: filePath)

        switch record.action {
        case .create:
            // Delete the created file
            try FileManager.default.removeItem(at: fileURL)
            recordChange(
                type: record.type,
                action: .delete,
                scope: record.scope,
                target: record.target,
                description: "Reverted: \(record.description)",
                oldContent: record.newContent,
                newContent: nil,
                filePath: filePath
            )

        case .update:
            // Restore old content
            guard let oldContent = record.oldContent else {
                throw HistoryError.missingOldContent
            }
            try oldContent.write(to: fileURL, atomically: true, encoding: .utf8)
            recordChange(
                type: record.type,
                action: .update,
                scope: record.scope,
                target: record.target,
                description: "Reverted: \(record.description)",
                oldContent: record.newContent,
                newContent: oldContent,
                filePath: filePath
            )

        case .delete:
            // Recreate the file
            guard let oldContent = record.oldContent else {
                throw HistoryError.missingOldContent
            }
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try oldContent.write(to: fileURL, atomically: true, encoding: .utf8)
            recordChange(
                type: record.type,
                action: .create,
                scope: record.scope,
                target: record.target,
                description: "Reverted: \(record.description)",
                oldContent: nil,
                newContent: oldContent,
                filePath: filePath
            )
        }
    }

    // MARK: - Management

    func clearHistory() {
        history.clear()
        saveHistory()
    }

    func removeRecord(_ record: ChangeRecord) {
        history.remove(record)
        saveHistory()
    }

    // MARK: - Helpers

    private func jsonString<T: Encodable>(from value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum HistoryError: LocalizedError {
    case cannotRevert
    case missingFilePath
    case missingOldContent

    var errorDescription: String? {
        switch self {
        case .cannotRevert: return "This change cannot be reverted"
        case .missingFilePath: return "Missing file path for revert"
        case .missingOldContent: return "Missing previous content for revert"
        }
    }
}
