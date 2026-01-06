//
//  UsageViewModel.swift
//  scode
//
//  ViewModel for usage statistics view
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    @Published var entries: [UsageEntry] = []
    @Published var stats: [UsageStats] = []
    @Published var totals: UsageStats?
    @Published var selectedStatType: UsageStatType = .daily
    @Published var selectedTimeRange: UsageTimeRange = .all
    @Published var sortField: UsageSortField = .date
    @Published var sortAscending: Bool = false
    @Published var selectedStatId: String?
    @Published var isLoading = false
    @Published var error: String?

    private let usageService = UsageService.shared

    init() {
        loadData()
    }

    func loadData() {
        isLoading = true
        error = nil

        // Load entries in background
        Task {
            let loadedEntries = usageService.loadUsageEntries()
            self.entries = loadedEntries
            self.aggregateData()
            self.isLoading = false
        }
    }

    func refreshData() {
        loadData()
    }

    func selectStatType(_ type: UsageStatType) {
        selectedStatType = type
        aggregateData()
    }

    func selectTimeRange(_ range: UsageTimeRange) {
        selectedTimeRange = range
        aggregateData()
    }

    func setSortField(_ field: UsageSortField) {
        if sortField == field {
            sortAscending.toggle()
        } else {
            sortField = field
            sortAscending = false
        }
        sortStats()
    }

    private func aggregateData() {
        let filteredEntries = usageService.filterByTimeRange(entries, range: selectedTimeRange)

        switch selectedStatType {
        case .daily:
            stats = usageService.aggregateByDay(filteredEntries)
        case .weekly:
            stats = usageService.aggregateByWeek(filteredEntries)
        case .monthly:
            stats = usageService.aggregateByMonth(filteredEntries)
        case .session:
            stats = usageService.aggregateBySession(filteredEntries)
        case .model:
            stats = usageService.aggregateByModel(filteredEntries)
        case .blocks:
            stats = usageService.aggregateByBlocks(filteredEntries)
        }

        sortStats()
        totals = usageService.calculateTotals(stats)
    }

    private func sortStats() {
        stats.sort { a, b in
            let result: Bool
            switch sortField {
            case .date:
                result = a.id < b.id
            case .inputTokens:
                result = a.inputTokens < b.inputTokens
            case .outputTokens:
                result = a.outputTokens < b.outputTokens
            case .totalTokens:
                result = a.totalTokens < b.totalTokens
            case .cost:
                result = a.estimatedCost < b.estimatedCost
            case .messages:
                result = a.messageCount < b.messageCount
            }
            return sortAscending ? result : !result
        }
    }
}
