//
//  UsageView.swift
//  scode
//
//  Usage statistics view with charts and tables
//

import SwiftUI
import Charts

struct UsageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = UsageViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            UsageHeaderView(
                selectedType: $viewModel.selectedStatType,
                selectedTimeRange: $viewModel.selectedTimeRange,
                isLoading: viewModel.isLoading,
                onRefresh: { viewModel.refreshData() },
                onStatTypeChange: { viewModel.selectStatType($0) },
                onTimeRangeChange: { viewModel.selectTimeRange($0) }
            )

            Divider()

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading usage data...")
                Spacer()
            } else if viewModel.stats.isEmpty {
                Spacer()
                EmptyUsageView()
                Spacer()
            } else {
                // Main content with chart and table
                HSplitView {
                    // Left: Chart and Summary
                    VStack(spacing: 16) {
                        UsageChartView(stats: viewModel.stats, statType: viewModel.selectedStatType)
                            .frame(minHeight: 200, maxHeight: 250)

                        if let totals = viewModel.totals {
                            UsageSummaryView(totals: totals)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .frame(minWidth: 300, idealWidth: 400)

                    // Right: Table
                    UsageTableView(
                        stats: viewModel.stats,
                        statType: viewModel.selectedStatType,
                        selectedId: $viewModel.selectedStatId,
                        sortField: viewModel.sortField,
                        sortAscending: viewModel.sortAscending,
                        onSort: { viewModel.setSortField($0) }
                    )
                }
            }
        }
    }
}

// MARK: - Header

struct UsageHeaderView: View {
    @Binding var selectedType: UsageStatType
    @Binding var selectedTimeRange: UsageTimeRange
    let isLoading: Bool
    let onRefresh: () -> Void
    let onStatTypeChange: (UsageStatType) -> Void
    let onTimeRangeChange: (UsageTimeRange) -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Usage Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Token usage and cost estimates")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Time Range Picker
            Picker("Range", selection: $selectedTimeRange) {
                ForEach(UsageTimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)
            .onChange(of: selectedTimeRange) { _, newRange in
                onTimeRangeChange(newRange)
            }

            Divider()
                .frame(height: 24)

            // Stat Type Picker
            Picker("Type", selection: $selectedType) {
                ForEach(UsageStatType.allCases) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .onChange(of: selectedType) { _, newType in
                onStatTypeChange(newType)
            }

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Chart

struct UsageChartView: View {
    let stats: [UsageStats]
    let statType: UsageStatType

    private var chartData: [UsageStats] {
        // Limit to last 14 items for better readability, reversed for chronological order
        Array(stats.prefix(14).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Token Usage Over Time")
                .font(.headline)
                .foregroundStyle(.secondary)

            Chart(chartData) { stat in
                BarMark(
                    x: .value("Period", stat.label),
                    y: .value("Input", stat.inputTokens)
                )
                .foregroundStyle(Color.blue)

                BarMark(
                    x: .value("Period", stat.label),
                    y: .value("Output", stat.outputTokens)
                )
                .foregroundStyle(Color.green)
            }
            .chartLegend(position: .top) {
                HStack(spacing: 16) {
                    LegendItem(color: .blue, label: "Input")
                    LegendItem(color: .green, label: "Output")
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(formatAxisLabel(label))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(formatNumber(intValue))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private func formatAxisLabel(_ label: String) -> String {
        if label.count > 10 {
            return String(label.suffix(5))
        }
        return label
    }

    private func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Table

struct UsageTableView: View {
    let stats: [UsageStats]
    let statType: UsageStatType
    @Binding var selectedId: String?
    let sortField: UsageSortField
    let sortAscending: Bool
    let onSort: (UsageSortField) -> Void

    private var showTimeColumn: Bool {
        statType == .session || statType == .blocks || statType == .daily
    }

    private var showModelColumn: Bool {
        statType != .model
    }

    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                SortableHeader(title: headerLabel, field: .date, currentField: sortField, ascending: sortAscending, onSort: onSort)
                    .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)

                if showTimeColumn {
                    Text("Time")
                        .frame(width: 100, alignment: .leading)
                }

                if showModelColumn {
                    Text("Models")
                        .frame(width: 80, alignment: .leading)
                }

                SortableHeader(title: "Messages", field: .messages, currentField: sortField, ascending: sortAscending, onSort: onSort)
                    .frame(width: 70, alignment: .trailing)

                SortableHeader(title: "Input", field: .inputTokens, currentField: sortField, ascending: sortAscending, onSort: onSort)
                    .frame(width: 90, alignment: .trailing)

                SortableHeader(title: "Output", field: .outputTokens, currentField: sortField, ascending: sortAscending, onSort: onSort)
                    .frame(width: 90, alignment: .trailing)

                Text("Cache")
                    .frame(width: 80, alignment: .trailing)

                SortableHeader(title: "Total", field: .totalTokens, currentField: sortField, ascending: sortAscending, onSort: onSort)
                    .frame(width: 90, alignment: .trailing)

                SortableHeader(title: "Cost", field: .cost, currentField: sortField, ascending: sortAscending, onSort: onSort)
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))

            Divider()

            // Table Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(stats) { stat in
                        UsageTableRow(
                            stat: stat,
                            showTimeColumn: showTimeColumn,
                            showModelColumn: showModelColumn,
                            isSelected: selectedId == stat.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedId = selectedId == stat.id ? nil : stat.id
                        }

                        Divider()
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var headerLabel: String {
        switch statType {
        case .session: return "Session"
        case .model: return "Model"
        default: return "Period"
        }
    }
}

struct SortableHeader: View {
    let title: String
    let field: UsageSortField
    let currentField: UsageSortField
    let ascending: Bool
    let onSort: (UsageSortField) -> Void

    var body: some View {
        Button(action: { onSort(field) }) {
            HStack(spacing: 2) {
                Text(title)
                if currentField == field {
                    Image(systemName: ascending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct UsageTableRow: View {
    let stat: UsageStats
    let showTimeColumn: Bool
    let showModelColumn: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(stat.label)
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            if showTimeColumn {
                Text(stat.timeRangeText ?? "-")
                    .frame(width: 100, alignment: .leading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showModelColumn {
                Text(modelsText)
                    .frame(width: 80, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(stat.messageCount)")
                .frame(width: 70, alignment: .trailing)
                .foregroundStyle(.purple)

            Text(formatNumber(stat.inputTokens))
                .frame(width: 90, alignment: .trailing)
                .foregroundStyle(.blue)

            Text(formatNumber(stat.outputTokens))
                .frame(width: 90, alignment: .trailing)
                .foregroundStyle(.green)

            Text(formatNumber(stat.cacheCreationTokens + stat.cacheReadTokens))
                .frame(width: 80, alignment: .trailing)
                .foregroundStyle(.orange)

            Text(formatNumber(stat.totalTokens))
                .frame(width: 90, alignment: .trailing)
                .fontWeight(.medium)

            Text(formatCost(stat.estimatedCost))
                .frame(width: 80, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
        .font(.system(.body, design: .monospaced))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
    }

    private var modelsText: String {
        let models = stat.modelsUsed.map { formatModelShort($0) }
        return models.joined(separator: ", ")
    }

    private func formatModelShort(_ model: String) -> String {
        if model.contains("opus") { return "opus" }
        if model.contains("sonnet") { return "sonnet" }
        if model.contains("haiku") { return "haiku" }
        return model.components(separatedBy: "-").prefix(2).joined(separator: "-")
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formatCost(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Summary

struct UsageSummaryView: View {
    let totals: UsageStats

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                SummaryCard(title: "Total Tokens", value: formatNumber(totals.totalTokens), icon: "number")
                SummaryCard(title: "Messages", value: "\(totals.messageCount)", icon: "bubble.left.and.bubble.right", color: .purple)
            }

            HStack(spacing: 16) {
                SummaryCard(title: "Input", value: formatNumber(totals.inputTokens), icon: "arrow.down.circle", color: .blue)
                SummaryCard(title: "Output", value: formatNumber(totals.outputTokens), icon: "arrow.up.circle", color: .green)
            }

            HStack(spacing: 16) {
                SummaryCard(title: "Cache", value: formatNumber(totals.cacheCreationTokens + totals.cacheReadTokens), icon: "memorychip", color: .orange)
                SummaryCard(title: "Est. Cost", value: formatCost(totals.estimatedCost), icon: "dollarsign.circle", color: .red)
            }
        }
    }

    private func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private func formatCost(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Empty State

struct EmptyUsageView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Usage Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Usage data will appear here after you start using Claude Code.\nData is loaded from ~/.claude/projects/")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    UsageView()
        .environmentObject(AppState.shared)
        .frame(width: 1000, height: 700)
}
