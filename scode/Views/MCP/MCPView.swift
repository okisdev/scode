//
//  MCPView.swift
//  scode
//
//  Clean MCP server management view
//

import SwiftUI

struct MCPView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedServer: MCPServerEntry?
    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var showImportSheet = false

    var body: some View {
        HSplitView {
            // Server List
            VStack(spacing: 0) {
                // Search & Add
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search servers...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)

                    Button {
                        showImportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .help("Import from other projects")

                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                // Server List
                List(selection: $selectedServer) {
                    ForEach(groupedServers.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { scope in
                        Section(scope.rawValue) {
                            ForEach(groupedServers[scope] ?? []) { server in
                                ServerRow(entry: server)
                                    .tag(server)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 280, maxWidth: 350)

            // Detail Panel
            if let server = selectedServer {
                ServerDetailPanel(
                    entry: server,
                    onEdit: { showEditSheet = true },
                    onDelete: {
                        appState.removeMCPServer(server)
                        selectedServer = nil
                    }
                )
            } else {
                EmptyServerView(onAdd: { showAddSheet = true })
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddServerSheet(isPresented: $showAddSheet)
        }
        .sheet(isPresented: $showEditSheet) {
            if let server = selectedServer {
                EditServerSheet(entry: server, isPresented: $showEditSheet) {
                    selectedServer = nil
                }
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportServersSheet(isPresented: $showImportSheet)
        }
        .onChange(of: appState.mcpServers) { _, newServers in
            // Clear selection if selected server is no longer in the list
            if let selected = selectedServer,
               !newServers.contains(where: { $0.id == selected.id }) {
                selectedServer = nil
            }
        }
        .onChange(of: appState.currentProjectPath) { _, _ in
            // Clear selection when project changes
            selectedServer = nil
        }
    }

    private var filteredServers: [MCPServerEntry] {
        if searchText.isEmpty {
            return appState.mcpServers
        }
        return appState.mcpServers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.server.url?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.server.command?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var groupedServers: [MCPScope: [MCPServerEntry]] {
        Dictionary(grouping: filteredServers) { $0.scope }
    }
}

// MARK: - Server Row

struct ServerRow: View {
    let entry: MCPServerEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.server.type?.icon ?? "questionmark.circle")
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .fontWeight(.medium)

                if let url = entry.server.url {
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let command = entry.server.command {
                    Text(command)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Server Detail Panel

struct ServerDetailPanel: View {
    let entry: MCPServerEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: entry.server.type?.icon ?? "server.rack")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(entry.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Link(destination: URL(string: "https://code.claude.com/docs/en/mcp")!) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .help("Open Claude Code MCP documentation")
                        }

                        HStack(spacing: 8) {
                            Label(entry.server.type?.displayName ?? "Unknown", systemImage: entry.server.type?.icon ?? "questionmark")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)

                            Label(entry.scope.rawValue, systemImage: entry.scope.icon)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    Spacer()

                    if entry.scope != .enterprise {
                        Button("Edit", action: onEdit)
                        Button("Delete", role: .destructive, action: onDelete)
                    }
                }

                Divider()

                // Connection Details
                DetailSection(title: "Connection") {
                    if let url = entry.server.url {
                        DetailItem(label: "URL", value: url)
                    }
                    if let command = entry.server.command {
                        DetailItem(label: "Command", value: command)
                    }
                    if let args = entry.server.args, !args.isEmpty {
                        DetailItem(label: "Arguments", value: args.joined(separator: " "))
                    }
                }

                // Environment Variables
                if let env = entry.server.env, !env.isEmpty {
                    DetailSection(title: "Environment Variables") {
                        ForEach(env.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailItem(label: key, value: value, isCode: true)
                        }
                    }
                }

                // Headers
                if let headers = entry.server.headers, !headers.isEmpty {
                    DetailSection(title: "Headers") {
                        ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailItem(label: key, value: value)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    var isCode: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(isCode ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Empty View

struct EmptyServerView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("MCP Servers")
                    .font(.headline)

                Link(destination: URL(string: "https://code.claude.com/docs/en/mcp")!) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .help("Open Claude Code MCP documentation")
            }

            Text("Select a server from the list or add a new one")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Add Server", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add Server Sheet

struct AddServerSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var type: MCPTransportType = .http
    @State private var url = ""
    @State private var command = ""
    @State private var args: [String] = []
    @State private var env: [String: String] = [:]
    @State private var scope: MCPScope = .user

    @State private var newArg = ""
    @State private var newEnvKey = ""
    @State private var newEnvValue = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("Add MCP Server")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Link(destination: URL(string: "https://code.claude.com/docs/en/mcp")!) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .help("Open Claude Code MCP documentation")
                }

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }

                Button("Add") {
                    addServer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdd)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Basic Info") {
                    TextField("Server Name", text: $name)

                    Picker("Transport", selection: $type) {
                        ForEach(MCPTransportType.allCases) { t in
                            Label(t.displayName, systemImage: t.icon).tag(t)
                        }
                    }

                    Picker("Scope", selection: $scope) {
                        ForEach(availableScopes) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                }

                Section("Connection") {
                    if type == .http || type == .sse {
                        TextField("URL", text: $url)
                            .textContentType(.URL)
                    } else {
                        TextField("Command", text: $command)

                        // Arguments
                        VStack(alignment: .leading) {
                            Text("Arguments")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(Array(args.enumerated()), id: \.offset) { index, arg in
                                HStack {
                                    Text(arg)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Button {
                                        args.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            HStack {
                                TextField("Add argument", text: $newArg)
                                    .onSubmit { addArg() }
                                Button("Add") { addArg() }
                                    .disabled(newArg.isEmpty)
                            }
                        }
                    }
                }

                if type == .stdio {
                    Section("Environment Variables") {
                        ForEach(env.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text("\(key)=\(value)")
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Button {
                                    env.removeValue(forKey: key)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("KEY", text: $newEnvKey)
                                .frame(width: 100)
                            Text("=")
                            TextField("value", text: $newEnvValue)
                            Button("Add") { addEnv() }
                                .disabled(newEnvKey.isEmpty)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 550)
    }

    private var availableScopes: [MCPScope] {
        if appState.currentProjectPath != nil {
            return [.user, .project]
        }
        return [.user]
    }

    private var canAdd: Bool {
        guard !name.isEmpty else { return false }
        switch type {
        case .http, .sse: return !url.isEmpty
        case .stdio: return !command.isEmpty
        }
    }

    private func addArg() {
        if !newArg.isEmpty {
            args.append(newArg)
            newArg = ""
        }
    }

    private func addEnv() {
        if !newEnvKey.isEmpty {
            env[newEnvKey] = newEnvValue
            newEnvKey = ""
            newEnvValue = ""
        }
    }

    private func addServer() {
        let server: MCPServer
        switch type {
        case .http, .sse:
            server = MCPServer(type: type, url: url)
        case .stdio:
            server = MCPServer(
                type: type,
                command: command,
                args: args.isEmpty ? nil : args,
                env: env.isEmpty ? nil : env
            )
        }

        appState.addMCPServer(name: name, server: server, scope: scope)
        isPresented = false
    }
}

// MARK: - Edit Server Sheet

struct EditServerSheet: View {
    let entry: MCPServerEntry
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var url: String = ""
    @State private var command: String = ""
    @State private var args: [String] = []
    @State private var env: [String: String] = [:]

    @State private var newArg = ""
    @State private var newEnvKey = ""
    @State private var newEnvValue = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit \(entry.name)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }

                Button("Save") {
                    saveServer()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            Form {
                if entry.server.type == .http || entry.server.type == .sse {
                    Section("Connection") {
                        TextField("URL", text: $url)
                    }
                } else {
                    Section("Connection") {
                        TextField("Command", text: $command)

                        VStack(alignment: .leading) {
                            Text("Arguments")
                            ForEach(Array(args.enumerated()), id: \.offset) { index, arg in
                                HStack {
                                    Text(arg)
                                    Spacer()
                                    Button { args.remove(at: index) } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            HStack {
                                TextField("Add argument", text: $newArg)
                                    .onSubmit {
                                        if !newArg.isEmpty {
                                            args.append(newArg)
                                            newArg = ""
                                        }
                                    }
                            }
                        }
                    }

                    Section("Environment Variables") {
                        ForEach(env.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text("\(key)=\(value)")
                                Spacer()
                                Button { env.removeValue(forKey: key) } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        HStack {
                            TextField("KEY", text: $newEnvKey)
                                .frame(width: 100)
                            Text("=")
                            TextField("value", text: $newEnvValue)
                            Button("Add") {
                                if !newEnvKey.isEmpty {
                                    env[newEnvKey] = newEnvValue
                                    newEnvKey = ""
                                    newEnvValue = ""
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 450)
        .onAppear {
            url = entry.server.url ?? ""
            command = entry.server.command ?? ""
            args = entry.server.args ?? []
            env = entry.server.env ?? [:]
        }
    }

    private func saveServer() {
        var server = entry.server
        server.url = url.isEmpty ? nil : url
        server.command = command.isEmpty ? nil : command
        server.args = args.isEmpty ? nil : args
        server.env = env.isEmpty ? nil : env

        appState.updateMCPServer(name: entry.name, server: server, scope: entry.scope)
        isPresented = false
        onComplete()
    }
}

// MARK: - Import Servers Sheet

struct ImportServersSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    @State private var availableServers: [(path: String, name: String, server: MCPServer)] = []
    @State private var selectedServers: Set<String> = []
    @State private var targetScope: MCPScope = .user

    private var availableScopes: [MCPScope] {
        if appState.currentProjectPath != nil {
            return [.user, .project]
        }
        return [.user]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import MCP Servers")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Scope selector
                Picker("Save to", selection: $targetScope) {
                    ForEach(availableScopes) { scope in
                        Label(scope.rawValue, systemImage: scope.icon).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Button("Cancel") {
                    isPresented = false
                }

                Button("Import Selected") {
                    importSelectedServers()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedServers.isEmpty)
            }
            .padding()

            Divider()

            if availableServers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No servers found in other projects")
                        .font(.headline)

                    Text("MCP servers configured in ~/.claude.json will appear here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedByProject, id: \.path) { group in
                        Section(header: Text(group.path).font(.caption)) {
                            ForEach(group.servers, id: \.name) { server in
                                ImportServerRow(
                                    name: server.name,
                                    server: server.server,
                                    isSelected: selectedServers.contains(server.name),
                                    onToggle: {
                                        if selectedServers.contains(server.name) {
                                            selectedServers.remove(server.name)
                                        } else {
                                            selectedServers.insert(server.name)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 500, height: 450)
        .onAppear {
            loadAvailableServers()
        }
    }

    private var groupedByProject: [(path: String, servers: [(name: String, server: MCPServer)])] {
        var groups: [String: [(name: String, server: MCPServer)]] = [:]

        for item in availableServers {
            let shortPath = item.path.replacingOccurrences(
                of: FileManager.default.homeDirectoryForCurrentUser.path,
                with: "~"
            )
            if groups[shortPath] == nil {
                groups[shortPath] = []
            }
            groups[shortPath]?.append((name: item.name, server: item.server))
        }

        return groups.map { (path: $0.key, servers: $0.value) }.sorted { $0.path < $1.path }
    }

    private func loadAvailableServers() {
        // Get all servers from ~/.claude.json
        guard let config = try? appState.configService.loadUserClaudeConfig() else {
            return
        }

        // Get currently loaded server names to filter them out
        let existingNames = Set(appState.mcpServers.map { $0.name })

        var servers: [(path: String, name: String, server: MCPServer)] = []

        // Load top-level mcpServers (User scope)
        if let topLevelServers = config.mcpServers {
            for (name, server) in topLevelServers {
                if !existingNames.contains(name) {
                    servers.append((path: "~/.claude.json (User)", name: name, server: server))
                }
            }
        }

        // Load project-specific servers
        if let projects = config.projects {
            for (path, projectConfig) in projects {
                if let mcpServers = projectConfig.mcpServers {
                    for (name, server) in mcpServers {
                        // Skip if already exists
                        if !existingNames.contains(name) {
                            servers.append((path: path, name: name, server: server))
                        }
                    }
                }
            }
        }

        // Remove duplicates by name (keep first occurrence)
        var seen: Set<String> = []
        availableServers = servers.filter { item in
            if seen.contains(item.name) {
                return false
            }
            seen.insert(item.name)
            return true
        }
    }

    private func importSelectedServers() {
        for serverName in selectedServers {
            if let serverInfo = availableServers.first(where: { $0.name == serverName }) {
                appState.addMCPServer(name: serverInfo.name, server: serverInfo.server, scope: targetScope)
            }
        }

        isPresented = false
    }
}

struct ImportServerRow: View {
    let name: String
    let server: MCPServer
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.title3)

                Image(systemName: server.type?.icon ?? "questionmark.circle")
                    .foregroundStyle(.blue)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let url = server.url {
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if let command = server.command {
                        Text(command)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(server.type?.displayName ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MCPView()
        .environmentObject(AppState.shared)
        .frame(width: 900, height: 600)
}
