//
//  MemoryView.swift
//  scode
//
//  Clean memory file management view
//

import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFile: MemoryFile?
    @State private var selectedRule: RuleFile?
    @State private var editingContent = ""
    @State private var hasChanges = false
    @State private var showNewRuleSheet = false

    var body: some View {
        HSplitView {
            // File List
            VStack(spacing: 0) {
                List {
                    // Memory Files
                    Section("Memory Files") {
                        ForEach(appState.memoryFiles) { file in
                            MemoryFileRow(file: file, isSelected: selectedFile?.id == file.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectMemoryFile(file)
                                }
                        }

                        // Create buttons
                        ForEach(availableScopes) { scope in
                            if canCreateFile(for: scope) {
                                Button {
                                    appState.createMemoryFile(scope: scope)
                                } label: {
                                    Label("Create \(scope.rawValue) Memory", systemImage: "plus.circle")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }

                    // Rules
                    Section("Rules") {
                        ForEach(appState.ruleFiles) { rule in
                            RuleFileRow(rule: rule, isSelected: selectedRule?.id == rule.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectRuleFile(rule)
                                }
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        appState.deleteRuleFile(rule)
                                        if selectedRule?.id == rule.id {
                                            selectedRule = nil
                                            editingContent = ""
                                        }
                                    }
                                }
                        }

                        Button {
                            showNewRuleSheet = true
                        } label: {
                            Label("Add Rule", systemImage: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 250, maxWidth: 300)

            // Editor
            VStack(spacing: 0) {
                if selectedFile != nil || selectedRule != nil {
                    EditorPanel(
                        file: selectedFile,
                        rule: selectedRule,
                        content: $editingContent,
                        hasChanges: hasChanges,
                        onSave: saveCurrentFile,
                        onRevert: revertChanges
                    )
                } else {
                    EmptyEditorView()
                }
            }
        }
        .sheet(isPresented: $showNewRuleSheet) {
            NewRuleSheet(isPresented: $showNewRuleSheet)
        }
        .onChange(of: editingContent) { _, newValue in
            if selectedFile != nil {
                hasChanges = newValue != selectedFile?.content
            } else if selectedRule != nil {
                hasChanges = newValue != selectedRule?.content
            }
        }
    }

    private var availableScopes: [MemoryScope] {
        if appState.currentProjectPath != nil {
            return [.user, .project, .local]
        }
        return [.user]
    }

    private func canCreateFile(for scope: MemoryScope) -> Bool {
        guard let file = appState.memoryFiles.first(where: { $0.scope == scope }) else {
            return true
        }
        return !file.exists
    }

    private func selectMemoryFile(_ file: MemoryFile) {
        if hasChanges { return } // TODO: Prompt to save
        selectedFile = file
        selectedRule = nil
        editingContent = file.content
        hasChanges = false
    }

    private func selectRuleFile(_ rule: RuleFile) {
        if hasChanges { return }
        selectedRule = rule
        selectedFile = nil
        editingContent = rule.content
        hasChanges = false
    }

    private func saveCurrentFile() {
        if var file = selectedFile {
            file.content = editingContent
            appState.saveMemoryFile(file)
            selectedFile?.content = editingContent
        } else if var rule = selectedRule {
            rule.content = editingContent
            appState.saveRuleFile(rule)
            selectedRule?.content = editingContent
        }
        hasChanges = false
    }

    private func revertChanges() {
        if let file = selectedFile {
            editingContent = file.content
        } else if let rule = selectedRule {
            editingContent = rule.content
        }
        hasChanges = false
    }
}

// MARK: - File Rows

struct MemoryFileRow: View {
    let file: MemoryFile
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.scope.icon)
                .foregroundStyle(file.exists ? .blue : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(file.scope.rawValue)
                        .fontWeight(.medium)

                    if !file.exists {
                        Text("(Not created)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if !file.isEditable {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(file.displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .opacity(file.exists ? 1 : 0.6)
    }
}

struct RuleFileRow: View {
    let rule: RuleFile
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.orange)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .fontWeight(.medium)

                if let paths = rule.frontmatter?.paths {
                    Text("Paths: \(paths)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Editor Panel

struct EditorPanel: View {
    let file: MemoryFile?
    let rule: RuleFile?
    @Binding var content: String
    let hasChanges: Bool
    let onSave: () -> Void
    let onRevert: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let file = file {
                    Image(systemName: file.scope.icon)
                        .foregroundStyle(.blue)
                    Text(file.fileName)
                        .fontWeight(.medium)
                    Text("(\(file.scope.rawValue))")
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/memory")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("Open Claude Code memory documentation")

                    if !file.isEditable {
                        Label("Read-only", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let rule = rule {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.orange)
                    Text(rule.name)
                        .fontWeight(.medium)
                    Text(".md")
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/memory")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("Open Claude Code memory documentation")
                }

                Spacer()

                if hasChanges {
                    Button("Revert", action: onRevert)
                        .buttonStyle(.plain)

                    Button("Save", action: onSave)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            // Editor
            if let file = file, !file.isEditable {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
            } else {
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
}

// MARK: - Empty View

struct EmptyEditorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("Memory & Rules")
                    .font(.headline)

                Link(destination: URL(string: "https://code.claude.com/docs/en/memory")!) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .help("Open Claude Code memory documentation")
            }

            Text("Choose a memory file or rule from the sidebar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - New Rule Sheet

struct NewRuleSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var paths = ""
    @State private var content = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Rule File")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }

                Button("Create") {
                    createRule()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()

            Divider()

            Form {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                TextField("Paths (optional glob pattern)", text: $paths)
                    .textFieldStyle(.roundedBorder)

                Section("Content") {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 450)
    }

    private func createRule() {
        let rulesDir: URL
        if let projectPath = appState.currentProjectPath {
            rulesDir = appState.configService.projectRulesDirectory(for: projectPath)
        } else {
            rulesDir = appState.configService.userRulesDirectory
        }

        let fileName = name.hasSuffix(".md") ? name : "\(name).md"
        let path = rulesDir.appendingPathComponent(fileName)

        var fileContent = ""
        if !paths.isEmpty {
            fileContent = "---\npaths: \(paths)\n---\n\n"
        }
        fileContent += content.isEmpty ? "# \(name)\n\nAdd your rules here.\n" : content

        let rule = RuleFile(path: path, content: fileContent)
        appState.saveRuleFile(rule)
        isPresented = false
    }
}

#Preview {
    MemoryView()
        .environmentObject(AppState.shared)
        .frame(width: 900, height: 600)
}
