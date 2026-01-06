//
//  MCPServerModel.swift
//  scode
//
//  MCP Server configuration model
//

import Foundation

/// MCP server configuration
struct MCPServer: Codable, Equatable, Hashable, Identifiable {
    var id = UUID()
    var type: MCPTransportType?
    var url: String?
    var command: String?
    var args: [String]?
    var env: [String: String]?
    var headers: [String: String]?

    enum CodingKeys: String, CodingKey {
        case type, url, command, args, env, headers
    }

    init(
        type: MCPTransportType? = nil,
        url: String? = nil,
        command: String? = nil,
        args: [String]? = nil,
        env: [String: String]? = nil,
        headers: [String: String]? = nil
    ) {
        self.type = type
        self.url = url
        self.command = command
        self.args = args
        self.env = env
        self.headers = headers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(MCPTransportType.self, forKey: .type)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent([String].self, forKey: .args)
        env = try container.decodeIfPresent([String: String].self, forKey: .env)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(env, forKey: .env)
        try container.encodeIfPresent(headers, forKey: .headers)
    }
}

/// MCP transport type
enum MCPTransportType: String, Codable, CaseIterable, Identifiable {
    case http
    case sse
    case stdio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .http:
            return "HTTP"
        case .sse:
            return "SSE (Deprecated)"
        case .stdio:
            return "Stdio"
        }
    }

    var description: String {
        switch self {
        case .http:
            return "Remote HTTP server - recommended for cloud services"
        case .sse:
            return "Server-Sent Events - deprecated, use HTTP instead"
        case .stdio:
            return "Local process via standard I/O"
        }
    }

    var icon: String {
        switch self {
        case .http:
            return "globe"
        case .sse:
            return "antenna.radiowaves.left.and.right"
        case .stdio:
            return "terminal"
        }
    }
}

/// Named MCP server entry (name -> server config)
struct MCPServerEntry: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var server: MCPServer
    var scope: MCPScope

    init(name: String, server: MCPServer, scope: MCPScope) {
        self.name = name
        self.server = server
        self.scope = scope
    }
}

/// MCP configuration scope
enum MCPScope: String, CaseIterable, Identifiable {
    case user = "User"
    case project = "Project"
    case local = "Local"
    case enterprise = "Enterprise"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .user:
            return "Available across all projects"
        case .project:
            return "Shared with team via .mcp.json"
        case .local:
            return "Only for you in this project"
        case .enterprise:
            return "Managed by organization"
        }
    }

    var icon: String {
        switch self {
        case .user:
            return "person.fill"
        case .project:
            return "folder.fill"
        case .local:
            return "laptopcomputer"
        case .enterprise:
            return "building.2.fill"
        }
    }
}
