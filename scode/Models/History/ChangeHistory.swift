//
//  ChangeHistory.swift
//  scode
//
//  Model for tracking configuration changes
//

import Foundation

/// Type of configuration change
enum ChangeType: String, Codable, CaseIterable, Identifiable {
    case settings = "Settings"
    case mcp = "MCP"
    case memory = "Memory"
    case rules = "Rules"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .settings: return "gearshape"
        case .mcp: return "server.rack"
        case .memory: return "brain"
        case .rules: return "doc.text"
        }
    }
}

/// Action type for the change
enum ChangeAction: String, Codable {
    case create = "Created"
    case update = "Updated"
    case delete = "Deleted"

    var icon: String {
        switch self {
        case .create: return "plus.circle.fill"
        case .update: return "pencil.circle.fill"
        case .delete: return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .create: return "green"
        case .update: return "blue"
        case .delete: return "red"
        }
    }
}

/// A single configuration change record
struct ChangeRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: ChangeType
    let action: ChangeAction
    let scope: String  // User, Project, Local, etc.
    let target: String // File name or item name
    let description: String
    let oldContent: String?
    let newContent: String?
    let filePath: String?

    init(
        type: ChangeType,
        action: ChangeAction,
        scope: String,
        target: String,
        description: String,
        oldContent: String? = nil,
        newContent: String? = nil,
        filePath: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.action = action
        self.scope = scope
        self.target = target
        self.description = description
        self.oldContent = oldContent
        self.newContent = newContent
        self.filePath = filePath
    }

    /// Human readable time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Formatted timestamp
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    /// Check if this change can be reverted
    var canRevert: Bool {
        switch action {
        case .create:
            return filePath != nil  // Can delete the created file
        case .update:
            return oldContent != nil && filePath != nil  // Can restore old content
        case .delete:
            return oldContent != nil && filePath != nil  // Can recreate the file
        }
    }
}

/// History storage container
struct ChangeHistoryStore: Codable {
    var records: [ChangeRecord]
    var maxRecords: Int

    init(maxRecords: Int = 100) {
        self.records = []
        self.maxRecords = maxRecords
    }

    mutating func add(_ record: ChangeRecord) {
        records.insert(record, at: 0)
        // Trim old records
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
    }

    mutating func remove(_ record: ChangeRecord) {
        records.removeAll { $0.id == record.id }
    }

    mutating func clear() {
        records.removeAll()
    }
}
