//
//  SandboxModel.swift
//  scode
//
//  Sandbox configuration model
//

import Foundation

/// Sandbox settings structure
struct SandboxSettings: Codable, Equatable {
    var enabled: Bool?
    var autoAllowBashIfSandboxed: Bool?
    var excludedCommands: [String]?
    var allowUnsandboxedCommands: Bool?
    var network: NetworkSettings?
    var enableWeakerNestedSandbox: Bool?

    init() {}
}

/// Network settings within sandbox
struct NetworkSettings: Codable, Equatable {
    var allowUnixSockets: [String]?
    var allowLocalBinding: Bool?
    var httpProxyPort: Int?
    var socksProxyPort: Int?

    init() {}
}
