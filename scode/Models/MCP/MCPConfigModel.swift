//
//  MCPConfigModel.swift
//  scode
//
//  MCP configuration container model
//

import Foundation

/// Root MCP configuration structure (for .mcp.json and ~/.claude.json)
struct MCPConfig: Codable, Equatable {
    var mcpServers: [String: MCPServer]?

    init(mcpServers: [String: MCPServer]? = nil) {
        self.mcpServers = mcpServers
    }
}

/// User-level MCP configuration (~/.claude.json)
/// This file contains more than just MCP servers
/// Uses flexible decoding to handle unknown fields
struct UserClaudeConfig: Equatable {
    var mcpServers: [String: MCPServer]?
    var projects: [String: ProjectConfig]?

    init() {}

    struct ProjectConfig: Equatable {
        var mcpServers: [String: MCPServer]?
        var allowedTools: [String]?
    }
}

extension UserClaudeConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case mcpServers, projects
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mcpServers = try container.decodeIfPresent([String: MCPServer].self, forKey: .mcpServers)

        // Decode projects manually to handle complex structure
        if let projectsContainer = try? container.decodeIfPresent([String: ProjectConfigRaw].self, forKey: .projects) {
            var projectsDict: [String: ProjectConfig] = [:]
            for (key, rawConfig) in projectsContainer {
                projectsDict[key] = ProjectConfig(
                    mcpServers: rawConfig.mcpServers,
                    allowedTools: rawConfig.allowedTools
                )
            }
            projects = projectsDict
        }
    }

    // Raw struct for flexible decoding (ignores unknown fields)
    private struct ProjectConfigRaw: Decodable {
        var mcpServers: [String: MCPServer]?
        var allowedTools: [String]?

        enum CodingKeys: String, CodingKey {
            case mcpServers, allowedTools
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            mcpServers = try container.decodeIfPresent([String: MCPServer].self, forKey: .mcpServers)
            allowedTools = try container.decodeIfPresent([String].self, forKey: .allowedTools)
        }
    }
}

extension UserClaudeConfig: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(mcpServers, forKey: .mcpServers)
        // Note: We don't encode projects back to avoid losing other fields
    }
}

/// Popular MCP servers for quick add
struct PopularMCPServer: Identifiable {
    var id = UUID()
    var name: String
    var displayName: String
    var description: String
    var type: MCPTransportType
    var url: String?
    var command: String?
    var args: [String]?
    var requiresEnv: [String]?
    var documentation: String?

    static let popularServers: [PopularMCPServer] = [
        PopularMCPServer(
            name: "github",
            displayName: "GitHub",
            description: "GitHub repository operations",
            type: .http,
            url: "https://api.githubcopilot.com/mcp/",
            documentation: "https://docs.github.com"
        ),
        PopularMCPServer(
            name: "sentry",
            displayName: "Sentry",
            description: "Error monitoring and debugging",
            type: .http,
            url: "https://mcp.sentry.dev/mcp",
            documentation: "https://docs.sentry.io"
        ),
        PopularMCPServer(
            name: "notion",
            displayName: "Notion",
            description: "Notion workspace integration",
            type: .http,
            url: "https://mcp.notion.com/mcp",
            documentation: "https://developers.notion.com"
        ),
        PopularMCPServer(
            name: "slack",
            displayName: "Slack",
            description: "Slack workspace integration",
            type: .http,
            url: "https://api.slack.com/mcp",
            documentation: "https://api.slack.com"
        ),
        PopularMCPServer(
            name: "filesystem",
            displayName: "Filesystem",
            description: "Local filesystem access",
            type: .stdio,
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-filesystem"],
            documentation: "https://github.com/modelcontextprotocol/servers"
        ),
        PopularMCPServer(
            name: "memory",
            displayName: "Memory",
            description: "Persistent memory storage",
            type: .stdio,
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-memory"],
            documentation: "https://github.com/modelcontextprotocol/servers"
        )
    ]
}
