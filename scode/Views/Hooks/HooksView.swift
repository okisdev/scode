//
//  HooksView.swift
//  scode
//
//  Clean hooks configuration view
//

import SwiftUI

struct HooksView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedEvent: HookEventName?
    @State private var editingMatchers: [HookMatcher] = []
    @State private var hasChanges = false

    private var currentScope: SettingsScope {
        appState.selectedSettingsScope
    }

    var body: some View {
        HSplitView {
            // Event List
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Hook Events")
                        .font(.headline)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/hooks")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("Open Claude Code hooks documentation")

                    Spacer()
                }
                .padding()

                Divider()

                List(selection: $selectedEvent) {
                    ForEach(HookEventName.allCases) { event in
                        HookEventRow(
                            event: event,
                            count: hookCount(for: event)
                        )
                        .tag(event)
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 250, maxWidth: 300)

            // Editor
            if let event = selectedEvent {
                HookEditorPanel(
                    event: event,
                    matchers: $editingMatchers,
                    hasChanges: hasChanges,
                    onSave: saveChanges,
                    onRevert: revertChanges,
                    onChanged: { hasChanges = true }
                )
            } else {
                EmptyHookView()
            }
        }
        .onChange(of: selectedEvent) { _, newEvent in
            if let event = newEvent {
                loadMatchers(for: event)
            }
        }
        .onChange(of: currentScope) { _, _ in
            if let event = selectedEvent {
                loadMatchers(for: event)
            }
        }
    }

    private func hookCount(for event: HookEventName) -> Int {
        let settings = appState.getSettings(for: currentScope)
        return settings.hooks?[event.rawValue]?.count ?? 0
    }

    private func loadMatchers(for event: HookEventName) {
        let settings = appState.getSettings(for: currentScope)
        editingMatchers = settings.hooks?[event.rawValue] ?? []
        hasChanges = false
    }

    private func saveChanges() {
        guard let event = selectedEvent else { return }
        var settings = appState.getSettings(for: currentScope)
        var hooks = settings.hooks ?? [:]

        if editingMatchers.isEmpty {
            hooks.removeValue(forKey: event.rawValue)
        } else {
            hooks[event.rawValue] = editingMatchers
        }

        settings.hooks = hooks.isEmpty ? nil : hooks
        appState.saveSettings(settings, scope: currentScope)
        hasChanges = false
    }

    private func revertChanges() {
        if let event = selectedEvent {
            loadMatchers(for: event)
        }
    }
}

// MARK: - Event Row

struct HookEventRow: View {
    let event: HookEventName
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayName)
                    .fontWeight(.medium)

                Text(event.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Hook Editor Panel

struct HookEditorPanel: View {
    let event: HookEventName
    @Binding var matchers: [HookMatcher]
    let hasChanges: Bool
    let onSave: () -> Void
    let onRevert: () -> Void
    let onChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: event.icon)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    HStack(spacing: 8) {
                        Text(event.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Link(destination: URL(string: "https://code.claude.com/docs/en/hooks")!) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                        }
                        .help("Open Claude Code hooks documentation")
                    }

                    Text(event.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if event.supportsMatcher {
                    Text("Supports matchers")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
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

            // Matchers
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(matchers.enumerated()), id: \.element.id) { index, matcher in
                        MatcherCard(
                            matcher: Binding(
                                get: { matchers[index] },
                                set: {
                                    matchers[index] = $0
                                    onChanged()
                                }
                            ),
                            supportsMatcher: event.supportsMatcher,
                            onDelete: {
                                matchers.remove(at: index)
                                onChanged()
                            }
                        )
                    }

                    Button {
                        matchers.append(HookMatcher(hooks: []))
                        onChanged()
                    } label: {
                        Label("Add Hook Matcher", systemImage: "plus.circle")
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
}

// MARK: - Matcher Card

struct MatcherCard: View {
    @Binding var matcher: HookMatcher
    let supportsMatcher: Bool
    let onDelete: () -> Void

    @State private var newHookType: HookType = .command
    @State private var newCommand = ""
    @State private var newPrompt = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if supportsMatcher {
                    Text("Matcher:")
                        .foregroundStyle(.secondary)
                    TextField("Pattern (e.g., Write|Edit)", text: Binding(
                        get: { matcher.matcher ?? "" },
                        set: { matcher.matcher = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 250)
                } else {
                    Text("No matcher required")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }

            Divider()

            // Hooks
            Text("Commands")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(matcher.hooks.enumerated()), id: \.element.id) { index, hook in
                HookRow(hook: hook) {
                    matcher.hooks.remove(at: index)
                }
            }

            // Add hook
            HStack {
                Picker("Type", selection: $newHookType) {
                    ForEach(HookType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .frame(width: 120)

                if newHookType == .command {
                    TextField("Command", text: $newCommand)
                        .textFieldStyle(.roundedBorder)
                } else {
                    TextField("Prompt", text: $newPrompt)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    addHook()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(newHookType == .command ? newCommand.isEmpty : newPrompt.isEmpty)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private func addHook() {
        let hook = HookCommand(
            type: newHookType,
            command: newHookType == .command ? newCommand : nil,
            prompt: newHookType == .prompt ? newPrompt : nil
        )
        matcher.hooks.append(hook)
        newCommand = ""
        newPrompt = ""
    }
}

struct HookRow: View {
    let hook: HookCommand
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: hook.type == .command ? "terminal" : "bubble.left.and.bubble.right")
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(hook.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let command = hook.command {
                    Text(command)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(2)
                } else if let prompt = hook.prompt {
                    Text(prompt)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Empty View

struct EmptyHookView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "link")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("Hooks")
                    .font(.headline)

                Link(destination: URL(string: "https://code.claude.com/docs/en/hooks")!) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .help("Open Claude Code hooks documentation")
            }

            Text("Choose a hook event from the sidebar to configure")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HooksView()
        .environmentObject(AppState.shared)
        .frame(width: 900, height: 600)
}
