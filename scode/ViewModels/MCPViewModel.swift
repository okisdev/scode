//
//  MCPViewModel.swift
//  scode
//
//  MCP servers view model
//

import Foundation
import SwiftUI
import Combine

/// View model for MCP server management
@MainActor
class MCPViewModel: ObservableObject {
    @Published var servers: [MCPServerEntry] = []
    @Published var selectedServer: MCPServerEntry?
    @Published var filterScope: MCPScope?
    @Published var searchText = ""

    @Published var isAddingServer = false
    @Published var isEditingServer = false

    // New server form
    @Published var newServerName = ""
    @Published var newServerType: MCPTransportType = .http
    @Published var newServerUrl = ""
    @Published var newServerCommand = ""
    @Published var newServerArgs: [String] = []
    @Published var newServerEnv: [String: String] = [:]
    @Published var newServerHeaders: [String: String] = [:]
    @Published var newServerScope: MCPScope = .user

    private let appState: AppState

    init(appState: AppState = .shared) {
        self.appState = appState
        loadServers()
    }

    // MARK: - Filtered Servers

    var filteredServers: [MCPServerEntry] {
        var result = servers

        if let scope = filterScope {
            result = result.filter { $0.scope == scope }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.server.url?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.server.command?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    var serversByScope: [MCPScope: [MCPServerEntry]] {
        Dictionary(grouping: filteredServers) { $0.scope }
    }

    // MARK: - Load

    func loadServers() {
        servers = appState.mcpServers
    }

    func refresh() {
        appState.refresh()
        loadServers()
    }

    // MARK: - Add Server

    func resetNewServerForm() {
        newServerName = ""
        newServerType = .http
        newServerUrl = ""
        newServerCommand = ""
        newServerArgs = []
        newServerEnv = [:]
        newServerHeaders = [:]
        newServerScope = appState.currentProjectPath != nil ? .project : .user
    }

    func addServer() {
        guard !newServerName.isEmpty else { return }

        let server: MCPServer
        switch newServerType {
        case .http, .sse:
            server = MCPServer(
                type: newServerType,
                url: newServerUrl.isEmpty ? nil : newServerUrl,
                headers: newServerHeaders.isEmpty ? nil : newServerHeaders
            )
        case .stdio:
            server = MCPServer(
                type: newServerType,
                command: newServerCommand.isEmpty ? nil : newServerCommand,
                args: newServerArgs.isEmpty ? nil : newServerArgs,
                env: newServerEnv.isEmpty ? nil : newServerEnv
            )
        }

        appState.addMCPServer(name: newServerName, server: server, scope: newServerScope)
        loadServers()
        resetNewServerForm()
        isAddingServer = false
    }

    func addFromPopular(_ popular: PopularMCPServer) {
        newServerName = popular.name
        newServerType = popular.type
        newServerUrl = popular.url ?? ""
        newServerCommand = popular.command ?? ""
        newServerArgs = popular.args ?? []
        newServerEnv = [:]
        newServerHeaders = [:]
        isAddingServer = true
    }

    // MARK: - Edit Server

    func selectServer(_ server: MCPServerEntry) {
        selectedServer = server
        newServerName = server.name
        newServerType = server.server.type ?? .http
        newServerUrl = server.server.url ?? ""
        newServerCommand = server.server.command ?? ""
        newServerArgs = server.server.args ?? []
        newServerEnv = server.server.env ?? [:]
        newServerHeaders = server.server.headers ?? [:]
        newServerScope = server.scope
    }

    func updateSelectedServer() {
        guard let selected = selectedServer else { return }

        // Remove old server
        appState.removeMCPServer(selected)

        // Add updated server
        let server: MCPServer
        switch newServerType {
        case .http, .sse:
            server = MCPServer(
                type: newServerType,
                url: newServerUrl.isEmpty ? nil : newServerUrl,
                headers: newServerHeaders.isEmpty ? nil : newServerHeaders
            )
        case .stdio:
            server = MCPServer(
                type: newServerType,
                command: newServerCommand.isEmpty ? nil : newServerCommand,
                args: newServerArgs.isEmpty ? nil : newServerArgs,
                env: newServerEnv.isEmpty ? nil : newServerEnv
            )
        }

        appState.addMCPServer(name: newServerName, server: server, scope: newServerScope)
        loadServers()
        selectedServer = nil
        isEditingServer = false
    }

    // MARK: - Remove Server

    func removeServer(_ server: MCPServerEntry) {
        appState.removeMCPServer(server)
        loadServers()
        if selectedServer?.id == server.id {
            selectedServer = nil
        }
    }

    // MARK: - Validation

    var canAddServer: Bool {
        guard !newServerName.isEmpty else { return false }

        switch newServerType {
        case .http, .sse:
            return !newServerUrl.isEmpty
        case .stdio:
            return !newServerCommand.isEmpty
        }
    }

    var validationResult: ValidationService.ValidationResult {
        let server: MCPServer
        switch newServerType {
        case .http, .sse:
            server = MCPServer(
                type: newServerType,
                url: newServerUrl.isEmpty ? nil : newServerUrl
            )
        case .stdio:
            server = MCPServer(
                type: newServerType,
                command: newServerCommand.isEmpty ? nil : newServerCommand
            )
        }
        return ValidationService.shared.validateMCPServer(server)
    }

    // MARK: - Available Scopes

    var availableScopes: [MCPScope] {
        if appState.currentProjectPath != nil {
            return [.user, .project]
        } else {
            return [.user]
        }
    }
}
