//
//  ConfigTab.swift
//  scode
//
//  Navigation tab enum for configuration sections
//

import Foundation

/// Represents the main configuration tabs in the app
enum ConfigTab: String, CaseIterable, Identifiable {
    case settings = "Settings"
    case mcp = "MCP Servers"
    case memory = "Memory"
    case hooks = "Hooks"
    case usage = "Usage"
    case raw = "Raw"
    case history = "History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .settings: return "gearshape.fill"
        case .mcp: return "server.rack"
        case .memory: return "brain.head.profile"
        case .hooks: return "link"
        case .usage: return "chart.bar.fill"
        case .raw: return "doc.text"
        case .history: return "clock.arrow.circlepath"
        }
    }
}
