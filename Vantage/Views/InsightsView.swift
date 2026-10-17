//
//  InsightsView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData
import Charts

/// Unified Workload Intelligence and Analytics using Swift Charts.
/// Displays:
/// 1. Horizontal Bar Chart comparing remaining estimated effort (Academic vs. Work).
/// 2. Stacked Bar Chart showing remaining workload distribution grouped by due date.
/// 3. Donut Chart visualizing overall task completion rate.
///
/// NOTE: Completed tasks are strictly excluded from all remaining-workload calculations.
public struct InsightsView: View {
    @Query private var tasks: [Task]
    @Query private var settingsList: [ApplicationSettings]
    
    public init() {}
    
    private var settings: ApplicationSettings? {
        settingsList.first
    }
    
    // Incomplete tasks only for remaining-workload calculations
    private var openTasks: [Task] {
        tasks.filter { $0.status != .completed }
    }
    
    private var completedTasks: [Task] {
        tasks.filter { $0.status == .completed }
    }
    
    // MARK: - Chart 1: Remaining Estimated Effort by Domain
    
    private struct RemainingEffortItem: Identifiable {
        let id = UUID()
        let domain: String
        let hours: Double
        let color: Color
    }
    
    private var remainingEffortData: [RemainingEffortItem] {
        let academicHours = openTasks
            .filter { $0.category == .academic }
            .reduce(0.0) { $0 + $1.estimatedCompletionTime } / 3600.0
        
        let workHours = openTasks
            .filter { $0.category == .work }
            .reduce(0.0) { $0 + $1.estimatedCompletionTime } / 3600.0
        
        return [
            RemainingEffortItem(domain: "Academic", hours: academicHours, color: Color.academicAccent),
            RemainingEffortItem(domain: "Work", hours: workHours, color: Color.workAccent)
        ]
    }
    
    private var totalRemainingAcademicHours: Double {
        remainingEffortData.first(where: { $0.domain == "Academic" })?.hours ?? 0.0
    }
    
    private var totalRemainingWorkHours: Double {
        remainingEffortData.first(where: { $0.domain == "Work" })?.hours ?? 0.0
    }
    
    private var combinedRemainingHours: Double {
        totalRemainingAcademicHours + totalRemainingWorkHours
    }
    
    // MARK: - Chart 2: Stacked Workload Grouped by Due Date
    
    private struct DateWorkloadItem: Identifiable {
        let id = UUID()
        let dateLabel: String
        let domain: String
        let hours: Double
        let category: PlannerCategory
    }
    
    private var workloadByDueDateData: [DateWorkloadItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate upcoming 7 days buckets
        let upcomingDays: [Date] = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        
        var items: [DateWorkloadItem] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE d"
        
        for day in upcomingDays {
            let label = calendar.isDateInToday(day) ? "Today" : (calendar.isDateInTomorrow(day) ? "Tomorrow" : dateFormatter.string(from: day))
            
            // Only incomplete tasks matching this due date
            let tasksOnDay = openTasks.filter { task in
                guard let due = task.dueDate else { return false }
                return calendar.isDate(due, inSameDayAs: day)
            }
            
            let academicHours = tasksOnDay
                .filter { $0.category == .academic }
                .reduce(0.0) { $0 + $1.estimatedCompletionTime } / 3600.0
            
            let workHours = tasksOnDay
                .filter { $0.category == .work }
                .reduce(0.0) { $0 + $1.estimatedCompletionTime } / 3600.0
            
            if academicHours > 0 {
                items.append(DateWorkloadItem(dateLabel: label, domain: "Academic", hours: academicHours, category: .academic))
            }
            if workHours > 0 {
                items.append(DateWorkloadItem(dateLabel: label, domain: "Work", hours: workHours, category: .work))
            }
            
            // If both are 0, add a zero placeholder to keep the day on the axis
            if academicHours == 0 && workHours == 0 {
                items.append(DateWorkloadItem(dateLabel: label, domain: "Academic", hours: 0, category: .academic))
            }
        }
        return items
    }
    
    // MARK: - Chart 3: Completion Rate Donut Data
    
    private struct CompletionSlice: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: Color
    }
    
    private var completionSlices: [CompletionSlice] {
        if tasks.isEmpty {
            return [CompletionSlice(label: "No Tasks", count: 1, color: Color.white.opacity(0.1))]
        }
        return [
            CompletionSlice(label: "Completed", count: completedTasks.count, color: .green),
            CompletionSlice(label: "Open", count: openTasks.count, color: Color(hex: "#0A84FF"))
        ]
    }
    
    private var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0.0 }
        return (Double(completedTasks.count) / Double(tasks.count)) * 100.0
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Header
                headerSection
                
                // Top Row: Remaining Effort Horizontal Bar Chart & Completion Donut Chart
                HStack(alignment: .top, spacing: 20) {
                    // Chart 1: Horizontal Bar Chart (Remaining Effort: Academic vs Work)
                    remainingEffortCard
                        .frame(maxWidth: .infinity)
                    
                    // Chart 3: Donut Chart (Overall Task Completion Rate)
                    completionDonutCard
                        .frame(width: 360)
                }
                
                // Chart 2: Stacked Bar Chart (Workload Grouped by Due Date)
                stackedWorkloadByDateCard
                
                // Burnout Alert Banner (if enabled and thresholds exceeded)
                if (settings?.enableBurnoutAlerts ?? true) && (totalRemainingAcademicHours > (settings?.maxDailyAcademicHours ?? 6.0) || totalRemainingWorkHours > (settings?.maxDailyWorkHours ?? 8.0)) {
                    burnoutAlertBanner
                }
                
                // Workload Guardrail Threshold Telemetry
                thresholdGuardrailsSection
            }
            .padding(28)
        }
        .navigationTitle("Insights")
    }
    
    private var burnoutAlertBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Color.conflictWarning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Cognitive Overload Warning")
                    .font(.headline)
                    .foregroundStyle(Color.conflictWarning)
                Text("Active backlog exceeds your configured threshold (\(String(format: "%.0fh study / %.0fh work", settings?.maxDailyAcademicHours ?? 6.0, settings?.maxDailyWorkHours ?? 8.0))). Consider rescheduling or deferring non-critical action items.")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.85))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.conflictWarning.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.conflictWarning.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Workload Intelligence & Analytics")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Visual telemetry of remaining commitments, scheduled due dates, and completion velocity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Chart 1: Remaining Estimated Effort Horizontal Bar Chart
    private var remainingEffortCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Remaining Estimated Effort", systemImage: "chart.bar.fill")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("Incomplete Tasks Only")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white.opacity(0.08)))
                    .foregroundStyle(.secondary)
            }
            
            Text("Comparing active study hours against professional work backlog (completed tasks excluded):")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if combinedRemainingHours == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundStyle(.green)
                    Text("No remaining workload")
                        .font(.headline)
                    Text("All assigned tasks have been completed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                Chart(remainingEffortData) { item in
                    BarMark(
                        x: .value("Remaining Hours", item.hours),
                        y: .value("Domain", item.domain)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text(String(format: "%.1f hrs", item.hours))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(item.color)
                            .padding(.leading, 4)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(.white.opacity(0.15))
                        AxisTick()
                        AxisValueLabel(format: Decimal.FormatStyle.number)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .font(.callout.weight(.medium))
                    }
                }
                .frame(height: 140)
                .padding(.top, 4)
            }
            
            // Metrics Summary Pill
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(Color.academicAccent).frame(width: 8, height: 8)
                    Text("Academic:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f hrs", totalRemainingAcademicHours))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.academicAccent)
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color.workAccent).frame(width: 8, height: 8)
                    Text("Work:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f hrs", totalRemainingWorkHours))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.workAccent)
                }
                
                Spacer()
                
                Text("Total: \(String(format: "%.1f hrs", combinedRemainingHours))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .vantageGlassCard()
    }
    
    // MARK: - Chart 3: Completion Rate Donut Chart
    private var completionDonutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Completion Velocity", systemImage: "chart.pie.fill")
                .font(.title3.weight(.bold))
            
            Text("Overall task resolution across study and work:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Donut Chart with SectorMark
            Chart(completionSlices) { slice in
                SectorMark(
                    angle: .value("Task Count", slice.count),
                    innerRadius: .ratio(0.65),
                    angularInset: 2.5
                )
                .foregroundStyle(slice.color)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", completionPercentage))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Resolved")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Completed (\(completedTasks.count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "#0A84FF")).frame(width: 8, height: 8)
                    Text("Open (\(openTasks.count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .vantageGlassCard()
    }
    
    // MARK: - Chart 2: Stacked Bar Chart Grouped by Due Date
    private var stackedWorkloadByDateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Upcoming Workload Distribution by Due Date", systemImage: "chart.bar.xaxis")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("Stacked by Academic & Work")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Remaining estimated hours for incomplete tasks due over the next 7 days:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Chart(workloadByDueDateData) { item in
                BarMark(
                    x: .value("Due Date", item.dateLabel),
                    y: .value("Remaining Hours", item.hours)
                )
                .foregroundStyle(by: .value("Domain", item.domain))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "Academic": Color.academicAccent,
                "Work": Color.workAccent
            ])
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisTick()
                    AxisValueLabel()
                        .font(.caption.weight(.medium))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisTick()
                    AxisValueLabel(format: Decimal.FormatStyle.number)
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: 220)
            .padding(.top, 4)
        }
        .padding(20)
        .vantageGlassCard()
    }
    
    // MARK: - Workload Thresholds Section
    private var thresholdGuardrailsSection: some View {
        let maxStudy = settings?.maxDailyAcademicHours ?? 6.0
        let maxWork = settings?.maxDailyWorkHours ?? 8.0
        
        return VStack(alignment: .leading, spacing: 14) {
            Text("Cognitive Load Thresholds")
                .font(.title3.weight(.bold))
            
            HStack(spacing: 16) {
                thresholdTile(
                    title: "Academic Remaining",
                    hours: totalRemainingAcademicHours,
                    threshold: maxStudy,
                    color: Color.academicAccent,
                    icon: "graduationcap.fill"
                )
                
                thresholdTile(
                    title: "Work Remaining",
                    hours: totalRemainingWorkHours,
                    threshold: maxWork,
                    color: Color.workAccent,
                    icon: "briefcase.fill"
                )
            }
        }
    }
    
    private func thresholdTile(title: String, hours: Double, threshold: Double, color: Color, icon: String) -> some View {
        let percentage = min(1.0, hours / max(1.0, threshold))
        let isOver = hours > threshold
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(isOver ? "Exceeds Daily Target" : "Within Budget")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOver ? Color.conflictWarning : .green)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", hours))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("/ \(String(format: "%.0fh target", threshold))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: percentage)
                .tint(isOver ? Color.conflictWarning : color)
        }
        .padding(16)
        .vantageGlassCard(borderColor: color.opacity(0.25))
    }
}
