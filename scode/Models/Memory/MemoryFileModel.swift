//
//  MemoryFileModel.swift
//  scode
//
//  Memory file (CLAUDE.md) model
//

import Foundation

/// Represents a CLAUDE.md memory file
struct MemoryFile: Identifiable, Equatable, Hashable {
    var id = UUID()
    var path: URL
    var scope: MemoryScope
    var content: String
    var exists: Bool
    var isEditable: Bool

    init(path: URL, scope: MemoryScope, content: String = "", exists: Bool = false, isEditable: Bool = true) {
        self.path = path
        self.scope = scope
        self.content = content
        self.exists = exists
        self.isEditable = isEditable
    }

    var fileName: String {
        path.lastPathComponent
    }

    var displayPath: String {
        path.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
    }
}

/// Memory file scope
enum MemoryScope: String, CaseIterable, Identifiable {
    case enterprise = "Enterprise"
    case user = "User"
    case project = "Project"
    case local = "Local"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .enterprise:
            return "Organization-wide instructions"
        case .user:
            return "Personal preferences for all projects"
        case .project:
            return "Team-shared project instructions"
        case .local:
            return "Personal project-specific preferences"
        }
    }

    var icon: String {
        switch self {
        case .enterprise:
            return "building.2.fill"
        case .user:
            return "person.fill"
        case .project:
            return "folder.fill"
        case .local:
            return "laptopcomputer"
        }
    }

    var fileName: String {
        switch self {
        case .enterprise, .user, .project:
            return "CLAUDE.md"
        case .local:
            return "CLAUDE.local.md"
        }
    }
}

/// Rule file in .claude/rules/ directory
struct RuleFile: Identifiable, Equatable {
    var id = UUID()
    var path: URL
    var name: String
    var content: String
    var frontmatter: RuleFrontmatter?

    init(path: URL, content: String = "") {
        self.path = path
        self.name = path.deletingPathExtension().lastPathComponent
        self.content = content
        self.frontmatter = RuleFile.parseFrontmatter(from: content)
    }

    var displayPath: String {
        path.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
    }

    static func parseFrontmatter(from content: String) -> RuleFrontmatter? {
        guard content.hasPrefix("---") else { return nil }

        let lines = content.components(separatedBy: "\n")
        var inFrontmatter = false
        var frontmatterLines: [String] = []

        for line in lines {
            if line == "---" {
                if inFrontmatter {
                    break
                } else {
                    inFrontmatter = true
                    continue
                }
            }
            if inFrontmatter {
                frontmatterLines.append(line)
            }
        }

        guard !frontmatterLines.isEmpty else { return nil }

        // Simple YAML parsing for paths field
        for line in frontmatterLines {
            if line.hasPrefix("paths:") {
                let pathsValue = line.replacingOccurrences(of: "paths:", with: "").trimmingCharacters(in: .whitespaces)
                return RuleFrontmatter(paths: pathsValue)
            }
        }

        return nil
    }
}

/// Rule file frontmatter
struct RuleFrontmatter: Equatable {
    var paths: String?

    init(paths: String? = nil) {
        self.paths = paths
    }
}
