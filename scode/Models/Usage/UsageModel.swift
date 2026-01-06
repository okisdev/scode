//
//  UsageModel.swift
//  scode
//
//  Data models for Claude Code usage statistics
//

import Foundation

/// Single usage entry parsed from JSONL
struct UsageEntry: Identifiable {
    let id: UUID
    let sessionId: String
    let projectPath: String
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }

    init(
        id: UUID = UUID(),
        sessionId: String,
        projectPath: String,
        timestamp: Date,
        model: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheCreationTokens: Int = 0,
        cacheReadTokens: Int = 0
    ) {
        self.id = id
        self.sessionId = sessionId
        self.projectPath = projectPath
        self.timestamp = timestamp
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.cacheReadTokens = cacheReadTokens
    }
}

/// Aggregated usage statistics
struct UsageStats: Identifiable {
    let id: String
    let label: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let estimatedCost: Double
    let modelsUsed: Set<String>
    let startTime: Date?
    let endTime: Date?
    let messageCount: Int

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }

    var timeRangeText: String? {
        guard let start = startTime, let end = endTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    var dateText: String? {
        guard let start = startTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: start)
    }

    init(
        id: String,
        label: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheCreationTokens: Int = 0,
        cacheReadTokens: Int = 0,
        estimatedCost: Double = 0,
        modelsUsed: Set<String> = [],
        startTime: Date? = nil,
        endTime: Date? = nil,
        messageCount: Int = 0
    ) {
        self.id = id
        self.label = label
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.cacheReadTokens = cacheReadTokens
        self.estimatedCost = estimatedCost
        self.modelsUsed = modelsUsed
        self.startTime = startTime
        self.endTime = endTime
        self.messageCount = messageCount
    }
}

/// Statistics aggregation type
enum UsageStatType: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case session = "Session"
    case model = "Model"
    case blocks = "Blocks"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .session: return "bubble.left.and.bubble.right"
        case .model: return "cpu"
        case .blocks: return "square.stack.3d.up"
        }
    }
}

/// Time range filter for usage data
enum UsageTimeRange: String, CaseIterable, Identifiable {
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case all = "All Time"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .all: return nil
        }
    }

    var startDate: Date? {
        guard let days = days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }
}

/// Sort options for usage table
enum UsageSortField: String, CaseIterable {
    case date = "Date"
    case inputTokens = "Input"
    case outputTokens = "Output"
    case totalTokens = "Total"
    case cost = "Cost"
    case messages = "Messages"
}

/// Model pricing information (per million tokens)
struct ModelPricing {
    let inputPrice: Double
    let outputPrice: Double

    static let pricing: [String: ModelPricing] = [
        // Claude 4 models
        "claude-sonnet-4-5-thinking": ModelPricing(inputPrice: 3.0, outputPrice: 15.0),
        "claude-sonnet-4-20250514": ModelPricing(inputPrice: 3.0, outputPrice: 15.0),
        "claude-opus-4-20250514": ModelPricing(inputPrice: 15.0, outputPrice: 75.0),
        "claude-opus-4-5-20251101": ModelPricing(inputPrice: 15.0, outputPrice: 75.0),
        // Claude 3.5 models
        "claude-3-5-sonnet-20241022": ModelPricing(inputPrice: 3.0, outputPrice: 15.0),
        "claude-3-5-haiku-20241022": ModelPricing(inputPrice: 0.80, outputPrice: 4.0),
        // Default fallback
        "default": ModelPricing(inputPrice: 3.0, outputPrice: 15.0)
    ]

    static func getPrice(for model: String) -> ModelPricing {
        // Try exact match first
        if let price = pricing[model] {
            return price
        }
        // Try prefix match for model variants
        for (key, price) in pricing {
            if model.hasPrefix(key.components(separatedBy: "-").prefix(3).joined(separator: "-")) {
                return price
            }
        }
        return pricing["default"]!
    }

    func calculateCost(inputTokens: Int, outputTokens: Int) -> Double {
        let inputCost = Double(inputTokens) / 1_000_000 * inputPrice
        let outputCost = Double(outputTokens) / 1_000_000 * outputPrice
        return inputCost + outputCost
    }
}
