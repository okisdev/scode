//
//  HistoryView.swift
//  scode
//
//  View for displaying and managing change history
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var historyService = HistoryService.shared
    @State private var selectedRecord: ChangeRecord?
    @State private var filterType: ChangeType?
    @State private var showClearConfirm = false

    var body: some View {
        HSplitView {
            // History List
            VStack(spacing: 0) {
                // Header with filter
                HStack {
                    Text("Change History")
                        .font(.headline)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/settings")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("View documentation")

                    Spacer()

                    // Filter picker
                    Picker("Filter", selection: $filterType) {
                        Text("All").tag(nil as ChangeType?)
                        ForEach(ChangeType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type as ChangeType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)

                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Clear history")
                    .disabled(historyService.history.records.isEmpty)
                }
                .padding()

                Divider()

                // Records list
                if filteredRecords.isEmpty {
                    EmptyHistoryView()
                } else {
                    List(selection: $selectedRecord) {
                        ForEach(groupedByDate, id: \.date) { group in
                            Section(header: Text(group.date).font(.caption).foregroundStyle(.secondary)) {
                                ForEach(group.records) { record in
                                    HistoryRecordRow(record: record)
                                        .tag(record)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 300, maxWidth: 400)

            // Detail Panel
            if let record = selectedRecord {
                HistoryDetailPanel(
                    record: record,
                    onRevert: { revertRecord(record) }
                )
            } else {
                EmptyHistoryDetailView()
            }
        }
        .alert("Clear History", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyService.clearHistory()
                selectedRecord = nil
            }
        } message: {
            Text("Are you sure you want to clear all change history? This cannot be undone.")
        }
    }

    private var filteredRecords: [ChangeRecord] {
        if let type = filterType {
            return historyService.history.records.filter { $0.type == type }
        }
        return historyService.history.records
    }

    private var groupedByDate: [(date: String, records: [ChangeRecord])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: filteredRecords) { record in
            formatter.string(from: record.timestamp)
        }

        return grouped.map { (date: $0.key, records: $0.value) }
            .sorted { $0.records.first?.timestamp ?? Date() > $1.records.first?.timestamp ?? Date() }
    }

    private func revertRecord(_ record: ChangeRecord) {
        do {
            try historyService.revert(record)
            appState.refresh()
        } catch {
            appState.showErrorMessage("Failed to revert: \(error.localizedDescription)")
        }
    }
}

// MARK: - History Record Row

struct HistoryRecordRow: View {
    let record: ChangeRecord

    private var actionColor: Color {
        switch record.action {
        case .create: return .green
        case .update: return .blue
        case .delete: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(actionColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: record.type.icon)
                    .foregroundStyle(actionColor)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(record.target)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(record.action.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(actionColor.opacity(0.15))
                        .foregroundStyle(actionColor)
                        .cornerRadius(4)
                }

                HStack(spacing: 8) {
                    Text(record.scope)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(record.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if record.canRevert {
                Image(systemName: "arrow.uturn.backward.circle")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - History Detail Panel

struct HistoryDetailPanel: View {
    let record: ChangeRecord
    let onRevert: () -> Void

    @State private var showDiff = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: record.type.icon)
                            .foregroundStyle(.blue)

                        Text(record.target)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Text(record.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if record.canRevert {
                    Button {
                        onRevert()
                    } label: {
                        Label("Revert", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            // Metadata
            HStack(spacing: 20) {
                MetadataItem(label: "Time", value: record.formattedTime)
                MetadataItem(label: "Scope", value: record.scope)
                MetadataItem(label: "Action", value: record.action.rawValue)

                Spacer()

                if record.oldContent != nil || record.newContent != nil {
                    Toggle("Show Diff", isOn: $showDiff)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))

            // Content diff
            if showDiff {
                DiffView(oldContent: record.oldContent, newContent: record.newContent)
            }

            Spacer()
        }
    }
}

struct MetadataItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Diff View

struct DiffView: View {
    let oldContent: String?
    let newContent: String?

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                // Old content
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Before")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))

                    if let old = oldContent {
                        Text(old)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("(empty)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.02))

                Divider()

                // New content
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("After")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))

                    if let new = newContent {
                        Text(new)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("(deleted)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.02))
            }
        }
    }
}

// MARK: - Empty Views

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Changes Yet")
                .font(.headline)

            Text("Changes to settings, MCP servers, memory, and rules will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyHistoryDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Change")
                .font(.headline)

            Text("Choose a change record from the list to view details")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState.shared)
        .frame(width: 900, height: 600)
}
