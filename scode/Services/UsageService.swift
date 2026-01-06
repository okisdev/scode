//
//  UsageService.swift
//  scode
//
//  Service for loading and aggregating Claude Code usage data from JSONL files
//

import Foundation
import Combine

/// Service for managing Claude Code usage statistics
@MainActor
class UsageService: ObservableObject {
    static let shared = UsageService()

    // MARK: - Path Constants

    private var homeDirectory: URL {
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: home))
        }
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            return URL(fileURLWithPath: home)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    /// Default Claude projects directory: ~/.claude/projects/
    private var defaultProjectsPath: URL {
        homeDirectory.appendingPathComponent(".claude/projects")
    }

    /// XDG config Claude projects directory: ~/.config/claude/projects/
    private var xdgProjectsPath: URL {
        let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
            ?? homeDirectory.appendingPathComponent(".config").path
        return URL(fileURLWithPath: xdgConfig).appendingPathComponent("claude/projects")
    }

    // MARK: - Data Loading

    /// Load all usage entries from JSONL files
    func loadUsageEntries() -> [UsageEntry] {
        var entries: [UsageEntry] = []

        // Load from both possible locations
        let directories = [defaultProjectsPath, xdgProjectsPath]

        for directory in directories {
            guard FileManager.default.fileExists(atPath: directory.path) else { continue }

            do {
                let projectDirs = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                for projectDir in projectDirs {
                    var isDir: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: projectDir.path, isDirectory: &isDir),
                          isDir.boolValue else { continue }

                    let projectPath = projectDir.lastPathComponent
                    let jsonlFiles = try FileManager.default.contentsOfDirectory(
                        at: projectDir,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    ).filter { $0.pathExtension == "jsonl" }

                    for jsonlFile in jsonlFiles {
                        let fileEntries = parseJSONLFile(at: jsonlFile, projectPath: projectPath)
                        entries.append(contentsOf: fileEntries)
                    }
                }
            } catch {
                print("[UsageService] Error reading directory \(directory): \(error)")
            }
        }

        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    /// Parse a single JSONL file
    private func parseJSONLFile(at url: URL, projectPath: String) -> [UsageEntry] {
        var entries: [UsageEntry] = []

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return entries
        }

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            guard !line.isEmpty,
                  let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            // Only process assistant messages with usage data
            guard let type = json["type"] as? String,
                  type == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any],
                  let model = message["model"] as? String,
                  let sessionId = json["sessionId"] as? String,
                  let timestampStr = json["timestamp"] as? String else {
                continue
            }

            // Parse timestamp
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let timestamp = formatter.date(from: timestampStr)
                    ?? ISO8601DateFormatter().date(from: timestampStr) else {
                continue
            }

            // Extract token counts
            let inputTokens = usage["input_tokens"] as? Int ?? 0
            let outputTokens = usage["output_tokens"] as? Int ?? 0
            let cacheCreationTokens = usage["cache_creation_input_tokens"] as? Int ?? 0
            let cacheReadTokens = usage["cache_read_input_tokens"] as? Int ?? 0

            let entry = UsageEntry(
                sessionId: sessionId,
                projectPath: projectPath,
                timestamp: timestamp,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheCreationTokens: cacheCreationTokens,
                cacheReadTokens: cacheReadTokens
            )

            entries.append(entry)
        }

        return entries
    }

    // MARK: - Aggregation

    /// Aggregate entries by day
    func aggregateByDay(_ entries: [UsageEntry]) -> [UsageStats] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var grouped: [String: (input: Int, output: Int, cacheCreate: Int, cacheRead: Int, models: Set<String>, entries: [UsageEntry])] = [:]

        for entry in entries {
            let dateStr = formatter.string(from: entry.timestamp)
            var group = grouped[dateStr] ?? (0, 0, 0, 0, [], [])
            group.input += entry.inputTokens
            group.output += entry.outputTokens
            group.cacheCreate += entry.cacheCreationTokens
            group.cacheRead += entry.cacheReadTokens
            group.models.insert(entry.model)
            group.entries.append(entry)
            grouped[dateStr] = group
        }

        return grouped.map { dateStr, data in
            let cost = calculateCost(entries: data.entries)
            let times = data.entries.map { $0.timestamp }
            return UsageStats(
                id: dateStr,
                label: dateStr,
                inputTokens: data.input,
                outputTokens: data.output,
                cacheCreationTokens: data.cacheCreate,
                cacheReadTokens: data.cacheRead,
                estimatedCost: cost,
                modelsUsed: data.models,
                startTime: times.min(),
                endTime: times.max(),
                messageCount: data.entries.count
            )
        }.sorted { $0.id > $1.id }
    }

    /// Aggregate entries by week
    func aggregateByWeek(_ entries: [UsageEntry]) -> [UsageStats] {
        let calendar = Calendar.current

        var grouped: [String: (input: Int, output: Int, cacheCreate: Int, cacheRead: Int, models: Set<String>, entries: [UsageEntry])] = [:]

        for entry in entries {
            let weekOfYear = calendar.component(.weekOfYear, from: entry.timestamp)
            let year = calendar.component(.yearForWeekOfYear, from: entry.timestamp)
            let weekStr = String(format: "%04d-W%02d", year, weekOfYear)

            var group = grouped[weekStr] ?? (0, 0, 0, 0, [], [])
            group.input += entry.inputTokens
            group.output += entry.outputTokens
            group.cacheCreate += entry.cacheCreationTokens
            group.cacheRead += entry.cacheReadTokens
            group.models.insert(entry.model)
            group.entries.append(entry)
            grouped[weekStr] = group
        }

        return grouped.map { weekStr, data in
            let cost = calculateCost(entries: data.entries)
            let times = data.entries.map { $0.timestamp }
            return UsageStats(
                id: weekStr,
                label: weekStr,
                inputTokens: data.input,
                outputTokens: data.output,
                cacheCreationTokens: data.cacheCreate,
                cacheReadTokens: data.cacheRead,
                estimatedCost: cost,
                modelsUsed: data.models,
                startTime: times.min(),
                endTime: times.max(),
                messageCount: data.entries.count
            )
        }.sorted { $0.id > $1.id }
    }

    /// Aggregate entries by month
    func aggregateByMonth(_ entries: [UsageEntry]) -> [UsageStats] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        var grouped: [String: (input: Int, output: Int, cacheCreate: Int, cacheRead: Int, models: Set<String>, entries: [UsageEntry])] = [:]

        for entry in entries {
            let monthStr = formatter.string(from: entry.timestamp)

            var group = grouped[monthStr] ?? (0, 0, 0, 0, [], [])
            group.input += entry.inputTokens
            group.output += entry.outputTokens
            group.cacheCreate += entry.cacheCreationTokens
            group.cacheRead += entry.cacheReadTokens
            group.models.insert(entry.model)
            group.entries.append(entry)
            grouped[monthStr] = group
        }

        return grouped.map { monthStr, data in
            let cost = calculateCost(entries: data.entries)
            let times = data.entries.map { $0.timestamp }
            return UsageStats(
                id: monthStr,
                label: monthStr,
                inputTokens: data.input,
                outputTokens: data.output,
                cacheCreationTokens: data.cacheCreate,
                cacheReadTokens: data.cacheRead,
                estimatedCost: cost,
                modelsUsed: data.models,
                startTime: times.min(),
                endTime: times.max(),
                messageCount: data.entries.count
            )
        }.sorted { $0.id > $1.id }
    }

    /// Aggregate entries by session
    func aggregateBySession(_ entries: [UsageEntry]) -> [UsageStats] {
        var grouped: [String: (project: String, input: Int, output: Int, cacheCreate: Int, cacheRead: Int, models: Set<String>, entries: [UsageEntry])] = [:]

        for entry in entries {
            let key = "\(entry.projectPath)/\(entry.sessionId)"

            var group = grouped[key] ?? (entry.projectPath, 0, 0, 0, 0, [], [])
            group.input += entry.inputTokens
            group.output += entry.outputTokens
            group.cacheCreate += entry.cacheCreationTokens
            group.cacheRead += entry.cacheReadTokens
            group.models.insert(entry.model)
            group.entries.append(entry)
            grouped[key] = group
        }

        return grouped.map { key, data in
            let cost = calculateCost(entries: data.entries)
            let shortSession = key.components(separatedBy: "/").last?.prefix(8) ?? ""
            let times = data.entries.map { $0.timestamp }
            return UsageStats(
                id: key,
                label: "\(data.project) (\(shortSession)...)",
                inputTokens: data.input,
                outputTokens: data.output,
                cacheCreationTokens: data.cacheCreate,
                cacheReadTokens: data.cacheRead,
                estimatedCost: cost,
                modelsUsed: data.models,
                startTime: times.min(),
                endTime: times.max(),
                messageCount: data.entries.count
            )
        }.sorted { $0.estimatedCost > $1.estimatedCost }
    }

    /// Aggregate entries by 5-hour billing blocks
    func aggregateByBlocks(_ entries: [UsageEntry]) -> [UsageStats] {
        let blockDuration: TimeInterval = 5 * 60 * 60 // 5 hours in seconds

        var grouped: [String: (start: Date, input: Int, output: Int, cacheCreate: Int, cacheRead: Int, models: Set<String>, entries: [UsageEntry])] = [:]

        for entry in entries {
            // Calculate block start time
            let timestamp = entry.timestamp.timeIntervalSince1970
            let blockIndex = Int(timestamp / blockDuration)
            let blockStart = Date(timeIntervalSince1970: Double(blockIndex) * blockDuration)
            let blockEnd = Date(timeIntervalSince1970: Double(blockIndex + 1) * blockDuration)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let blockStr = formatter.string(from: blockStart)

            var group = grouped[blockStr] ?? (blockStart, 0, 0, 0, 0, [], [])
            group.input += entry.inputTokens
            group.output += entry.outputTokens
            group.cacheCreate += entry.cacheCreationTokens
            group.cacheRead += entry.cacheReadTokens
            group.models.insert(entry.model)
            group.entries.append(entry)
            grouped[blockStr] = group
        }

        return grouped.map { blockStr, data in
            let cost = calculateCost(entries: data.entries)
            let blockEnd = data.start.addingTimeInterval(blockDuration)
            return UsageStats(
                id: blockStr,
                label: blockStr,
                inputTokens: data.input,
                outputTokens: data.output,
                cacheCreationTokens: data.cacheCreate,
                cacheReadTokens: data.cacheRead,
                estimatedCost: cost,
                modelsUsed: data.models,
                startTime: data.start,
                endTime: blockEnd,
                messageCount: data.entries.count
            )
        }.sorted { $0.id > $1.id }
    }

    /// Aggregate entries by model
    func aggregateByModel(_ entries: [UsageEntry]) -> [UsageStats] {
        var grouped: [String: (input: Int, output: Int, cacheCreate: Int, cacheRead: Int, count: Int, entries: [UsageEntry])] = [:]

        for entry in entries {
            var group = grouped[entry.model] ?? (0, 0, 0, 0, 0, [])
            group.input += entry.inputTokens
            group.output += entry.outputTokens
            group.cacheCreate += entry.cacheCreationTokens
            group.cacheRead += entry.cacheReadTokens
            group.count += 1
            group.entries.append(entry)
            grouped[entry.model] = group
        }

        return grouped.map { model, data in
            let cost = calculateCost(entries: data.entries)
            let times = data.entries.map { $0.timestamp }
            return UsageStats(
                id: model,
                label: formatModelName(model),
                inputTokens: data.input,
                outputTokens: data.output,
                cacheCreationTokens: data.cacheCreate,
                cacheReadTokens: data.cacheRead,
                estimatedCost: cost,
                modelsUsed: [model],
                startTime: times.min(),
                endTime: times.max(),
                messageCount: data.entries.count
            )
        }.sorted { $0.estimatedCost > $1.estimatedCost }
    }

    /// Format model name for display
    private func formatModelName(_ model: String) -> String {
        // Remove date suffix for cleaner display
        let parts = model.components(separatedBy: "-")
        if parts.count >= 3 {
            // Check if last part looks like a date (8 digits)
            if let last = parts.last, last.count == 8, Int(last) != nil {
                return parts.dropLast().joined(separator: "-")
            }
        }
        return model
    }

    // MARK: - Cost Calculation

    /// Calculate total cost for a set of entries
    private func calculateCost(entries: [UsageEntry]) -> Double {
        var totalCost: Double = 0

        for entry in entries {
            let pricing = ModelPricing.getPrice(for: entry.model)
            totalCost += pricing.calculateCost(inputTokens: entry.inputTokens, outputTokens: entry.outputTokens)
        }

        return totalCost
    }

    /// Calculate total stats from multiple UsageStats
    func calculateTotals(_ stats: [UsageStats]) -> UsageStats {
        var totalInput = 0
        var totalOutput = 0
        var totalCacheCreate = 0
        var totalCacheRead = 0
        var totalCost: Double = 0
        var allModels: Set<String> = []
        var totalMessages = 0
        var allStartTimes: [Date] = []
        var allEndTimes: [Date] = []

        for stat in stats {
            totalInput += stat.inputTokens
            totalOutput += stat.outputTokens
            totalCacheCreate += stat.cacheCreationTokens
            totalCacheRead += stat.cacheReadTokens
            totalCost += stat.estimatedCost
            allModels.formUnion(stat.modelsUsed)
            totalMessages += stat.messageCount
            if let start = stat.startTime { allStartTimes.append(start) }
            if let end = stat.endTime { allEndTimes.append(end) }
        }

        return UsageStats(
            id: "total",
            label: "Total",
            inputTokens: totalInput,
            outputTokens: totalOutput,
            cacheCreationTokens: totalCacheCreate,
            cacheReadTokens: totalCacheRead,
            estimatedCost: totalCost,
            modelsUsed: allModels,
            startTime: allStartTimes.min(),
            endTime: allEndTimes.max(),
            messageCount: totalMessages
        )
    }

    /// Filter entries by time range
    func filterByTimeRange(_ entries: [UsageEntry], range: UsageTimeRange) -> [UsageEntry] {
        guard let startDate = range.startDate else { return entries }
        return entries.filter { $0.timestamp >= startDate }
    }
}
