//
//  FileSystemService.swift
//  scode
//
//  File system operations and project management
//

import Foundation
import AppKit
import Combine

/// Service for file system operations
@MainActor
class FileSystemService: ObservableObject {
    static let shared = FileSystemService()

    @Published var currentProjectPath: URL?
    @Published var recentProjects: [URL] = []

    private let recentProjectsKey = "RecentProjects"
    private let maxRecentProjects = 10

    init() {
        loadRecentProjects()
    }

    // MARK: - Project Selection

    func selectProject() async -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Project Directory"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())

        if response == .OK, let url = panel.url {
            setCurrentProject(url)
            return url
        }

        return nil
    }

    func setCurrentProject(_ url: URL) {
        currentProjectPath = url
        addToRecentProjects(url)
    }

    func clearCurrentProject() {
        currentProjectPath = nil
    }

    // MARK: - Recent Projects

    private func loadRecentProjects() {
        if let data = UserDefaults.standard.data(forKey: recentProjectsKey),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            recentProjects = paths.compactMap { URL(fileURLWithPath: $0) }
                .filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    private func saveRecentProjects() {
        let paths = recentProjects.map { $0.path }
        if let data = try? JSONEncoder().encode(paths) {
            UserDefaults.standard.set(data, forKey: recentProjectsKey)
        }
    }

    private func addToRecentProjects(_ url: URL) {
        // Remove if already exists
        recentProjects.removeAll { $0 == url }

        // Add to front
        recentProjects.insert(url, at: 0)

        // Keep only max recent
        if recentProjects.count > maxRecentProjects {
            recentProjects = Array(recentProjects.prefix(maxRecentProjects))
        }

        saveRecentProjects()
    }

    func removeFromRecentProjects(_ url: URL) {
        recentProjects.removeAll { $0 == url }
        saveRecentProjects()
    }

    // MARK: - Project Detection

    func isClaudeCodeProject(_ url: URL) -> Bool {
        let claudeDir = url.appendingPathComponent(".claude")
        let claudeMd = url.appendingPathComponent("CLAUDE.md")
        let mcpJson = url.appendingPathComponent(".mcp.json")

        return FileManager.default.fileExists(atPath: claudeDir.path) ||
               FileManager.default.fileExists(atPath: claudeMd.path) ||
               FileManager.default.fileExists(atPath: mcpJson.path)
    }

    func projectDisplayName(_ url: URL) -> String {
        url.lastPathComponent
    }

    func projectDisplayPath(_ url: URL) -> String {
        url.path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }

    // MARK: - File Operations

    func readFile(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    func writeFile(_ content: String, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func deleteFile(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    func createDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func listFiles(in directory: URL, withExtension ext: String? = nil) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            if let ext = ext {
                if fileURL.pathExtension == ext {
                    files.append(fileURL)
                }
            } else {
                files.append(fileURL)
            }
        }

        return files
    }

    // MARK: - Backup

    func createBackup(of url: URL) throws -> URL {
        let backupDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/backups")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupName = "\(url.deletingPathExtension().lastPathComponent)_\(timestamp).\(url.pathExtension)"
        let backupPath = backupDir.appendingPathComponent(backupName)

        try FileManager.default.copyItem(at: url, to: backupPath)
        return backupPath
    }
}
