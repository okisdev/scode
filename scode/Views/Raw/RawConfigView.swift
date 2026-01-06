//
//  RawConfigView.swift
//  scode
//
//  Raw JSON configuration viewer
//

import SwiftUI

struct RawConfigView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFile: RawConfigFile?
    @State private var fileContent: String = ""
    @State private var isEditing = false
    @State private var editedContent: String = ""
    @State private var hasChanges = false

    var body: some View {
        HSplitView {
            // File List
            VStack(spacing: 0) {
                HStack {
                    Text("Configuration Files")
                        .font(.headline)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/settings")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("View documentation")

                    Spacer()
                }
                .padding()

                Divider()

                List(selection: $selectedFile) {
                    // Settings Files
                    Section("Settings") {
                        ForEach(settingsFiles) { file in
                            RawFileRow(file: file)
                                .tag(file)
                        }
                    }

                    // MCP Files
                    Section("MCP") {
                        ForEach(mcpFiles) { file in
                            RawFileRow(file: file)
                                .tag(file)
                        }
                    }

                    // Memory Files
                    Section("Memory") {
                        ForEach(memoryFiles) { file in
                            RawFileRow(file: file)
                                .tag(file)
                        }
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 280, maxWidth: 350)

            // Content Panel
            if let file = selectedFile {
                RawContentPanel(
                    file: file,
                    content: $fileContent,
                    isEditing: $isEditing,
                    editedContent: $editedContent,
                    hasChanges: $hasChanges,
                    onSave: saveFile,
                    onRevert: revertChanges,
                    onRefresh: { loadFileContent(file) }
                )
            } else {
                EmptyRawView()
            }
        }
        .onChange(of: selectedFile) { _, newFile in
            if let file = newFile {
                loadFileContent(file)
            }
        }
    }

    // MARK: - File Lists

    private var settingsFiles: [RawConfigFile] {
        var files: [RawConfigFile] = []

        // User settings
        files.append(RawConfigFile(
            name: "settings.json",
            scope: "User",
            path: appState.configService.userSettingsPath,
            icon: "person.fill",
            isEditable: true
        ))

        // Project settings
        if let projectPath = appState.currentProjectPath {
            files.append(RawConfigFile(
                name: "settings.json",
                scope: "Project",
                path: appState.configService.projectSettingsPath(for: projectPath),
                icon: "folder.fill",
                isEditable: true
            ))

            files.append(RawConfigFile(
                name: "settings.local.json",
                scope: "Local",
                path: appState.configService.localSettingsPath(for: projectPath),
                icon: "lock.fill",
                isEditable: true
            ))
        }

        // Enterprise settings
        files.append(RawConfigFile(
            name: "managed-settings.json",
            scope: "Enterprise",
            path: appState.configService.enterpriseSettingsPath,
            icon: "building.2.fill",
            isEditable: false
        ))

        return files
    }

    private var mcpFiles: [RawConfigFile] {
        var files: [RawConfigFile] = []

        // User MCP
        files.append(RawConfigFile(
            name: ".claude.json",
            scope: "User",
            path: appState.configService.userMCPPath,
            icon: "person.fill",
            isEditable: true
        ))

        // Project MCP
        if let projectPath = appState.currentProjectPath {
            files.append(RawConfigFile(
                name: ".mcp.json",
                scope: "Project",
                path: appState.configService.projectMCPPath(for: projectPath),
                icon: "folder.fill",
                isEditable: true
            ))
        }

        // Enterprise MCP
        files.append(RawConfigFile(
            name: "managed-mcp.json",
            scope: "Enterprise",
            path: appState.configService.enterpriseMCPPath,
            icon: "building.2.fill",
            isEditable: false
        ))

        return files
    }

    private var memoryFiles: [RawConfigFile] {
        var files: [RawConfigFile] = []

        // User memory
        files.append(RawConfigFile(
            name: "CLAUDE.md",
            scope: "User",
            path: appState.configService.userMemoryPath,
            icon: "person.fill",
            isEditable: true
        ))

        // Project memory
        if let projectPath = appState.currentProjectPath {
            files.append(RawConfigFile(
                name: "CLAUDE.md",
                scope: "Project",
                path: appState.configService.projectMemoryPath(for: projectPath),
                icon: "folder.fill",
                isEditable: true
            ))

            files.append(RawConfigFile(
                name: "CLAUDE.local.md",
                scope: "Local",
                path: appState.configService.localMemoryPath(for: projectPath),
                icon: "lock.fill",
                isEditable: true
            ))
        }

        // Enterprise memory
        files.append(RawConfigFile(
            name: "CLAUDE.md",
            scope: "Enterprise",
            path: appState.configService.enterpriseMemoryPath,
            icon: "building.2.fill",
            isEditable: false
        ))

        return files
    }

    // MARK: - Actions

    private func loadFileContent(_ file: RawConfigFile) {
        if FileManager.default.fileExists(atPath: file.path.path) {
            fileContent = (try? String(contentsOf: file.path, encoding: .utf8)) ?? "(Unable to read file)"
        } else {
            fileContent = "(File does not exist)"
        }
        editedContent = fileContent
        hasChanges = false
        isEditing = false
    }

    private func saveFile() {
        guard let file = selectedFile, file.isEditable else { return }

        do {
            // Create directory if needed
            let directory = file.path.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            // Mark as internal write
            appState.fileWatcher.markAsInternalWrite(file.path)

            // Write content
            try editedContent.write(to: file.path, atomically: true, encoding: .utf8)

            fileContent = editedContent
            hasChanges = false
            isEditing = false

            // Refresh app state
            appState.refresh()
        } catch {
            appState.showErrorMessage("Failed to save: \(error.localizedDescription)")
        }
    }

    private func revertChanges() {
        editedContent = fileContent
        hasChanges = false
    }
}

// MARK: - Models

struct RawConfigFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let scope: String
    let path: URL
    let icon: String
    let isEditable: Bool

    var exists: Bool {
        FileManager.default.fileExists(atPath: path.path)
    }

    var displayPath: String {
        path.path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
}

// MARK: - File Row

struct RawFileRow: View {
    let file: RawConfigFile

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.icon)
                .foregroundStyle(file.exists ? .blue : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.name)
                        .fontWeight(.medium)

                    if !file.exists {
                        Text("(missing)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    if !file.isEditable {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(file.scope)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(file.exists ? 1 : 0.6)
    }
}

// MARK: - Content Panel

struct RawContentPanel: View {
    let file: RawConfigFile
    @Binding var content: String
    @Binding var isEditing: Bool
    @Binding var editedContent: String
    @Binding var hasChanges: Bool
    let onSave: () -> Void
    let onRevert: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: file.icon)
                            .foregroundStyle(.blue)

                        Text(file.name)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("(\(file.scope))")
                            .foregroundStyle(.secondary)
                    }

                    Text(file.displayPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                if file.exists {
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")

                    if file.isEditable {
                        if isEditing {
                            if hasChanges {
                                Button("Revert", action: onRevert)
                                    .buttonStyle(.plain)

                                Button("Save", action: onSave)
                                    .buttonStyle(.borderedProminent)
                            }

                            Button("Done") {
                                if hasChanges {
                                    onRevert()
                                }
                                isEditing = false
                            }
                        } else {
                            Button("Edit") {
                                isEditing = true
                            }
                        }
                    } else {
                        Label("Read-only", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()

            Divider()

            // Content
            if file.exists {
                if isEditing && file.isEditable {
                    TextEditor(text: $editedContent)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: editedContent) { _, newValue in
                            hasChanges = newValue != content
                        }
                } else {
                    ScrollView {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("File Does Not Exist")
                        .font(.headline)

                    Text(file.displayPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if file.isEditable {
                        Button("Create File") {
                            createEmptyFile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func createEmptyFile() {
        do {
            let directory = file.path.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let initialContent: String
            if file.name.hasSuffix(".json") {
                initialContent = "{}\n"
            } else if file.name.hasSuffix(".md") {
                initialContent = "# Claude Code Instructions\n\nAdd your instructions here.\n"
            } else {
                initialContent = ""
            }

            try initialContent.write(to: file.path, atomically: true, encoding: .utf8)
            onRefresh()
        } catch {
            // Handle error
        }
    }
}

// MARK: - Empty View

struct EmptyRawView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Raw Configuration")
                .font(.headline)

            Text("Select a file from the sidebar to view its contents")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RawConfigView()
        .environmentObject(AppState.shared)
        .frame(width: 900, height: 600)
}
