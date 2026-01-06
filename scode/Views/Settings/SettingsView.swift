//
//  SettingsView.swift
//  scode
//
//  Clean settings view with card-based layout
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingSettings: ClaudeSettings = ClaudeSettings()
    @State private var hasChanges = false

    private var currentScope: SettingsScope {
        appState.selectedSettingsScope
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SettingsHeaderView(
                scope: currentScope,
                hasChanges: hasChanges,
                onSave: saveChanges,
                onRevert: revertChanges
            )

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // General Section
                    SettingsCard(title: "General", icon: "gear") {
                        GeneralSettings(settings: $editingSettings, onChange: markChanged)
                    }

                    // Permissions Section
                    SettingsCard(title: "Permissions", icon: "lock.shield") {
                        PermissionsSettings(settings: $editingSettings, onChange: markChanged)
                    }

                    // Sandbox Section
                    SettingsCard(title: "Sandbox", icon: "shield.checkered") {
                        SandboxSettingsSection(settings: $editingSettings, onChange: markChanged)
                    }

                    // Environment Variables
                    SettingsCard(title: "Environment Variables", icon: "terminal") {
                        EnvironmentSettings(settings: $editingSettings, onChange: markChanged)
                    }
                }
                .padding(20)
            }
            .disabled(currentScope == .enterprise)
        }
        .onAppear { loadSettings() }
        .onChange(of: currentScope) { _, _ in loadSettings() }
        .onChange(of: appState.settings) { _, _ in
            if !hasChanges {
                loadSettings()
            }
        }
    }

    private func loadSettings() {
        editingSettings = appState.getSettings(for: currentScope)
        hasChanges = false
    }

    private func markChanged() {
        hasChanges = true
    }

    private func saveChanges() {
        appState.saveSettings(editingSettings, scope: currentScope)
        hasChanges = false
    }

    private func revertChanges() {
        loadSettings()
    }
}

// MARK: - Header

struct SettingsHeaderView: View {
    let scope: SettingsScope
    let hasChanges: Bool
    let onSave: () -> Void
    let onRevert: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/settings")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("Open Claude Code settings documentation")
                }

                Text(scope.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if scope == .enterprise {
                Label("Read-only", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            } else if hasChanges {
                HStack(spacing: 8) {
                    Button("Revert", action: onRevert)
                        .buttonStyle(.plain)

                    Button("Save Changes", action: onSave)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                content
                    .padding(16)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - General Settings

struct GeneralSettings: View {
    @Binding var settings: ClaudeSettings
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Model
            SettingsRow(label: "Model") {
                TextField("Default model (e.g., claude-sonnet-4-20250514)", text: Binding(
                    get: { settings.model ?? "" },
                    set: {
                        settings.model = $0.isEmpty ? nil : $0
                        onChange()
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }

            // Cleanup Period
            SettingsRow(label: "Cleanup Period") {
                HStack {
                    TextField("Days", value: Binding(
                        get: { settings.cleanupPeriodDays ?? 30 },
                        set: {
                            settings.cleanupPeriodDays = $0
                            onChange()
                        }
                    ), formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)

                    Text("days")
                        .foregroundStyle(.secondary)
                }
            }

            // Extended Thinking
            SettingsRow(label: "Extended Thinking") {
                Toggle("Always enable extended thinking", isOn: Binding(
                    get: { settings.alwaysThinkingEnabled ?? false },
                    set: {
                        settings.alwaysThinkingEnabled = $0
                        onChange()
                    }
                ))
                .toggleStyle(.switch)
            }

            // Output Style
            SettingsRow(label: "Output Style") {
                TextField("Custom output style", text: Binding(
                    get: { settings.outputStyle ?? "" },
                    set: {
                        settings.outputStyle = $0.isEmpty ? nil : $0
                        onChange()
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }
}

// MARK: - Permissions Settings

struct PermissionsSettings: View {
    @Binding var settings: ClaudeSettings
    let onChange: () -> Void

    @State private var newRule = ""
    @State private var selectedRuleType: PermissionRuleType = .allow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Default Mode
            SettingsRow(label: "Default Mode") {
                Picker("Mode", selection: Binding(
                    get: {
                        PermissionMode(rawValue: settings.permissions?.defaultMode ?? "default") ?? .default
                    },
                    set: { mode in
                        var permissions = settings.permissions ?? PermissionSettings()
                        permissions.defaultMode = mode.rawValue
                        settings.permissions = permissions
                        onChange()
                    }
                )) {
                    ForEach(PermissionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
            }

            Divider()

            // Rules by type
            ForEach(PermissionRuleType.allCases) { ruleType in
                RuleSection(
                    ruleType: ruleType,
                    rules: rulesFor(ruleType),
                    onAdd: { addRule(ruleType, pattern: $0) },
                    onRemove: { removeRule(ruleType, at: $0) }
                )
            }
        }
    }

    private func rulesFor(_ type: PermissionRuleType) -> [String] {
        switch type {
        case .allow: return settings.permissions?.allow ?? []
        case .ask: return settings.permissions?.ask ?? []
        case .deny: return settings.permissions?.deny ?? []
        }
    }

    private func addRule(_ type: PermissionRuleType, pattern: String) {
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
        onChange()
    }

    private func removeRule(_ type: PermissionRuleType, at index: Int) {
        var permissions = settings.permissions ?? PermissionSettings()
        switch type {
        case .allow: permissions.allow?.remove(at: index)
        case .ask: permissions.ask?.remove(at: index)
        case .deny: permissions.deny?.remove(at: index)
        }
        settings.permissions = permissions
        onChange()
    }
}

struct RuleSection: View {
    let ruleType: PermissionRuleType
    let rules: [String]
    let onAdd: (String) -> Void
    let onRemove: (Int) -> Void

    @State private var newPattern = ""

    private var ruleColor: Color {
        switch ruleType {
        case .allow: return .green
        case .ask: return .orange
        case .deny: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(ruleColor)
                    .frame(width: 8, height: 8)
                Text(ruleType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("(\(rules.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Existing rules
            FlowLayout(spacing: 6) {
                ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                    RuleTag(rule: rule, color: ruleColor) {
                        onRemove(index)
                    }
                }
            }

            // Add new rule
            HStack {
                TextField("Tool(pattern)", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !newPattern.isEmpty {
                            onAdd(newPattern)
                            newPattern = ""
                        }
                    }

                Button {
                    if !newPattern.isEmpty {
                        onAdd(newPattern)
                        newPattern = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(newPattern.isEmpty)
            }
        }
    }
}

struct RuleTag: View {
    let rule: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(rule)
                .font(.system(.caption, design: .monospaced))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .cornerRadius(6)
    }
}

// MARK: - Sandbox Settings

struct SandboxSettingsSection: View {
    @Binding var settings: ClaudeSettings
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Sandbox", isOn: Binding(
                get: { settings.sandbox?.enabled ?? false },
                set: {
                    var sandbox = settings.sandbox ?? SandboxSettings()
                    sandbox.enabled = $0
                    settings.sandbox = sandbox
                    onChange()
                }
            ))
            .toggleStyle(.switch)

            Toggle("Auto-allow Bash if Sandboxed", isOn: Binding(
                get: { settings.sandbox?.autoAllowBashIfSandboxed ?? true },
                set: {
                    var sandbox = settings.sandbox ?? SandboxSettings()
                    sandbox.autoAllowBashIfSandboxed = $0
                    settings.sandbox = sandbox
                    onChange()
                }
            ))
            .toggleStyle(.switch)

            Toggle("Allow Unsandboxed Commands", isOn: Binding(
                get: { settings.sandbox?.allowUnsandboxedCommands ?? true },
                set: {
                    var sandbox = settings.sandbox ?? SandboxSettings()
                    sandbox.allowUnsandboxedCommands = $0
                    settings.sandbox = sandbox
                    onChange()
                }
            ))
            .toggleStyle(.switch)

            Divider()

            Text("Network")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Toggle("Allow Local Binding", isOn: Binding(
                get: { settings.sandbox?.network?.allowLocalBinding ?? false },
                set: {
                    var sandbox = settings.sandbox ?? SandboxSettings()
                    var network = sandbox.network ?? NetworkSettings()
                    network.allowLocalBinding = $0
                    sandbox.network = network
                    settings.sandbox = sandbox
                    onChange()
                }
            ))
            .toggleStyle(.switch)
        }
    }
}

// MARK: - Environment Settings

struct EnvironmentSettings: View {
    @Binding var settings: ClaudeSettings
    let onChange: () -> Void

    @State private var newKey = ""
    @State private var newValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let env = settings.env ?? [:]

            if env.isEmpty {
                Text("No environment variables defined")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(env.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        Text("=")
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)

                        Spacer()

                        Button {
                            settings.env?.removeValue(forKey: key)
                            onChange()
                        } label: {
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

            Divider()

            HStack {
                TextField("KEY", text: $newKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)

                Text("=")
                    .foregroundStyle(.secondary)

                TextField("value", text: $newValue)
                    .textFieldStyle(.roundedBorder)

                Button {
                    if !newKey.isEmpty {
                        var env = settings.env ?? [:]
                        env[newKey] = newValue
                        settings.env = env
                        newKey = ""
                        newValue = ""
                        onChange()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(newKey.isEmpty)
            }
        }
    }
}

// MARK: - Helper Views

struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .frame(width: 140, alignment: .leading)
                .foregroundStyle(.secondary)

            content
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            height = y + lineHeight
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
        .frame(width: 700, height: 800)
}
