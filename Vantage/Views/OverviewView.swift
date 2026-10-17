//
//  OverviewView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// The Overview Cockpit for Vantage.
/// Displays three summary metrics (Open Tasks, Due in Next 7 Days, Completed Tasks),
/// a list of upcoming incomplete tasks sorted by nearest due date,
/// and a compact "Balance Snapshot" showing remaining estimated effort for Academic vs. Work.
public struct OverviewView: View {
    @Query(sort: \Task.createdAt, order: .reverse) private var allTasks: [Task]
    @Query(sort: \ScheduleEvent.startTime) private var allEvents: [ScheduleEvent]
    @Query private var settingsList: [ApplicationSettings]
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    @State private var taskToEdit: Task?
    @State private var showCreateTaskSheet: Bool = false
    
    public init() {}
    
    // MARK: - Metric Calculations
    
    private var openTasks: [Task] {
        allTasks.filter { $0.status != .completed }
    }
    
    private var completedTasks: [Task] {
        allTasks.filter { $0.status == .completed }
    }
    
    private var settings: ApplicationSettings? {
        settingsList.first
    }
    
    private var isBurnoutThresholdExceeded: Bool {
        guard let s = settings, s.enableBurnoutAlerts else { return false }
        return remainingAcademicHours > s.maxDailyAcademicHours || remainingWorkHours > s.maxDailyWorkHours
    }
    
    private var tasksDueInNext7Days: [Task] {
        let now = Calendar.current.startOfDay(for: Date())
        guard let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now) else {
            return []
        }
        return openTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate <= sevenDaysFromNow
        }
    }
    
    /// Upcoming incomplete tasks sorted by nearest due date first
    private var upcomingIncompleteTasks: [Task] {
        openTasks.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.createdAt > rhs.createdAt
            }
        }
    }
    
    // MARK: - Balance Snapshot Effort Calculations
    
    private var remainingAcademicSeconds: TimeInterval {
        openTasks
            .filter { $0.category == .academic }
            .reduce(0) { $0 + $1.estimatedCompletionTime }
    }
    
    private var remainingWorkSeconds: TimeInterval {
        openTasks
            .filter { $0.category == .work }
            .reduce(0) { $0 + $1.estimatedCompletionTime }
    }
    
    private var remainingAcademicHours: Double {
        remainingAcademicSeconds / 3600.0
    }
    
    private var remainingWorkHours: Double {
        remainingWorkSeconds / 3600.0
    }
    
    private var totalRemainingHours: Double {
        remainingAcademicHours + remainingWorkHours
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Header Banner with Quick Add
                headerBanner
                
                // Cognitive Burnout Alert Banner
                if isBurnoutThresholdExceeded {
                    burnoutWarningBanner
                }
                
                // 1. Top Three Summary Metrics (Open Tasks, Due in Next 7 Days, Completed Tasks)
                threeSummaryMetrics
                
                // 2. Main Content Split: Upcoming Incomplete Tasks & Compact Balance Snapshot
                HStack(alignment: .top, spacing: 22) {
                    // Left Column: Upcoming Incomplete Tasks (Sorted by Nearest Due Date)
                    upcomingTasksSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right Column: Compact Balance Snapshot & Quick Timetable
                    VStack(spacing: 20) {
                        compactBalanceSnapshotCard
                        
                        todayTimetableCard
                    }
                    .frame(width: 390)
                }
            }
            .padding(28)
        }
        .navigationTitle("Overview")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateTaskSheet = true
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        // Modal Sheet for Task Creation
        .sheet(isPresented: $showCreateTaskSheet) {
            TaskEditorSheet(taskToEdit: nil, initialCategory: .academic)
        }
        // Modal Sheet for Task Editing
        .sheet(item: $taskToEdit) { task in
            TaskEditorSheet(taskToEdit: task, initialCategory: task.category)
        }
    }
    
    // MARK: - Subviews
    
    private var headerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vantage Command Center")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Unified overview of active workloads, approaching deadlines, and domain balance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            Button {
                showCreateTaskSheet = true
            } label: {
                Label("New Task", systemImage: "plus.circle.fill")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.workAccent)
        }
    }
    
    private var burnoutWarningBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Color.conflictWarning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Cognitive Overload Alert")
                    .font(.headline)
                    .foregroundStyle(Color.conflictWarning)
                Text("Your remaining study or work backlog exceeds daily target hours (\(String(format: "%.0fh study / %.0fh work", settings?.maxDailyAcademicHours ?? 6.0, settings?.maxDailyWorkHours ?? 8.0))).")
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
    
    // MARK: - Three Summary Metrics
    private var threeSummaryMetrics: some View {
        HStack(spacing: 16) {
            // Metric 1: Open Tasks
            let academicOpen = openTasks.filter { $0.category == .academic }.count
            let workOpen = openTasks.filter { $0.category == .work }.count
            metricCard(
                title: "Open Tasks",
                value: "\(openTasks.count)",
                subtitle: "\(academicOpen) Academic • \(workOpen) Work",
                icon: "circle.dashed",
                accentColor: Color(hex: "#0A84FF")
            )
            
            // Metric 2: Due in Next 7 Days
            let due7 = tasksDueInNext7Days.count
            metricCard(
                title: "Due in Next 7 Days",
                value: "\(due7)",
                subtitle: due7 == 0 ? "No immediate deadlines" : "\(due7) pending deadlines",
                icon: "calendar.badge.clock",
                accentColor: .orange
            )
            
            // Metric 3: Completed Tasks
            metricCard(
                title: "Completed Tasks",
                value: "\(completedTasks.count)",
                subtitle: "Resolved across all domains",
                icon: "checkmark.circle.fill",
                accentColor: .green
            )
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                Spacer()
                Text(value)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .vantageGlassCard()
    }
    
    // MARK: - Upcoming Incomplete Tasks Section
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Upcoming Incomplete Tasks")
                    .font(.title2.weight(.bold))
                Spacer()
                Text("Sorted by nearest due date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if upcomingIncompleteTasks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("All Tasks Completed!")
                        .font(.headline)
                    Text("Great job staying on top of your study and work commitments.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("Create New Task") {
                        showCreateTaskSheet = true
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.workAccent)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(36)
                .vantageGlassCard()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(upcomingIncompleteTasks.prefix(8)) { task in
                        TaskCardRow(task: task) {
                            taskToEdit = task
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Compact Balance Snapshot
    private var compactBalanceSnapshotCard: some View {
        let total = max(0.1, totalRemainingHours)
        let academicRatio = remainingAcademicHours / total
        let workRatio = remainingWorkHours / total
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Balance Snapshot", systemImage: "scale.3d")
                    .font(.title3.weight(.bold))
                Spacer()
                Text(String(format: "%.1fh total remaining", totalRemainingHours))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Text("Remaining estimated effort allocation between Academic and Work domains:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Dual Accent Proportion Bar
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.academicAccent)
                        .frame(width: max(4, geo.size.width * CGFloat(academicRatio)))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.workAccent)
                        .frame(width: max(4, geo.size.width * CGFloat(workRatio)))
                }
            }
            .frame(height: 12)
            
            // Domain Details
            VStack(spacing: 10) {
                // Academic Effort
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.academicAccent).frame(width: 8, height: 8)
                        Text("Academic")
                            .font(.callout.weight(.medium))
                    }
                    Spacer()
                    Text(String(format: "%.1f hrs", remainingAcademicHours))
                        .font(.callout.weight(.bold))
                        .foregroundStyle(Color.academicAccent)
                    Text(String(format: "(%.0f%%)", academicRatio * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                // Work Effort
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.workAccent).frame(width: 8, height: 8)
                        Text("Work")
                            .font(.callout.weight(.medium))
                    }
                    Spacer()
                    Text(String(format: "%.1f hrs", remainingWorkHours))
                        .font(.callout.weight(.bold))
                        .foregroundStyle(Color.workAccent)
                    Text(String(format: "(%.0f%%)", workRatio * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .vantageGlassCard()
    }
    
    // MARK: - Quick Timetable Preview Card
    private var todayTimetableCard: some View {
        let todayEvents = allEvents.filter { Calendar.current.isDateInToday($0.date) }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's Schedule", systemImage: "clock")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: VantageWindowID.standaloneCalendar)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Open Standalone Calendar")
            }
            
            if todayEvents.isEmpty {
                Text("No sessions scheduled for today.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayEvents.prefix(3)) { event in
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(event.category.accentColor)
                                .frame(width: 3)
                                .cornerRadius(1.5)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Text(event.formattedTimeRange)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                    }
                }
            }
        }
        .padding(18)
        .vantageGlassCard()
    }
}
