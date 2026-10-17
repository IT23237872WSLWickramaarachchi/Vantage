//
//  CalendarPlannerView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Integrated Monthly Calendar view featuring Task Deadlines, Schedule Events,
/// domain color coding (Academic: Indigo #7779C9, Work: Teal #2A9D98),
/// and automatic fixed-time schedule conflict detection with Coral warnings (#E46B72).
public struct CalendarPlannerView: View {
    @Query(sort: \ScheduleEvent.startTime) private var allEvents: [ScheduleEvent]
    @Query(sort: \Task.dueDate) private var allTasks: [Task]
    @Query private var settingsList: [ApplicationSettings]
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentMonthDate: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var showCreateEventSheet: Bool = false
    @State private var eventToEdit: ScheduleEvent? = nil
    @State private var taskToEdit: Task? = nil
    
    public init() {}
    
    private var calendar: Calendar {
        var cal = Calendar.current
        if let firstDay = settingsList.first?.firstDayOfWeek {
            cal.firstWeekday = firstDay
        }
        return cal
    }
    
    // MARK: - Month Calculation
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonthDate)
    }
    
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }
    
    private var daysInMonthGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        let startOfGrid = monthFirstWeek.start
        var days: [Date?] = []
        var cursor = startOfGrid
        
        // 6 weeks * 7 days = 42 cells maximum
        for _ in 0..<42 {
            if calendar.isDate(cursor, equalTo: currentMonthDate, toGranularity: .month) {
                days.append(cursor)
            } else {
                days.append(nil) // Empty cell outside current month
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
            
            // If we've passed the end of the month and completed a full row (multiple of 7), we can terminate
            if cursor > monthInterval.end && days.count % 7 == 0 {
                break
            }
        }
        return days
    }
    
    // MARK: - Items for Selected Day
    
    private var selectedDayEvents: [ScheduleEvent] {
        allEvents.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private var showCompletedTasks: Bool {
        settingsList.first?.showCompletedTasksInCalendar ?? false
    }
    
    private var selectedDayTasks: [Task] {
        allTasks.filter { task in
            guard let due = task.dueDate else { return false }
            if !showCompletedTasks && task.status == .completed { return false }
            return calendar.isDate(due, inSameDayAs: selectedDate)
        }
    }
    
    private var selectedDayConflicts: [(ScheduleEvent, ScheduleEvent)] {
        detectConflicts(among: selectedDayEvents)
    }
    
    private var hasConflictOnSelectedDay: Bool {
        !selectedDayConflicts.isEmpty
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Top Header with Navigation & Detach Window Button
                headerBanner
                
                // Calendar and Selected Day Detail Split
                HStack(alignment: .top, spacing: 22) {
                    // Left Column: Monthly Grid
                    VStack(alignment: .leading, spacing: 16) {
                        monthNavigatorBar
                        
                        monthlyGridView
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .vantageGlassCard()
                    
                    // Right Column: Selected Day Agenda & Conflict Inspector
                    dayAgendaInspector
                        .frame(width: 420)
                }
            }
            .padding(28)
        }
        .navigationTitle("Calendar")
        .sheet(isPresented: $showCreateEventSheet) {
            ScheduleEventEditorSheet(initialDate: selectedDate)
        }
        .sheet(item: $eventToEdit) { event in
            ScheduleEventEditorSheet(eventToEdit: event)
        }
        .sheet(item: $taskToEdit) { task in
            TaskEditorSheet(taskToEdit: task)
        }
    }
    
    // MARK: - Header
    
    private var headerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Schedule & Timetable")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Unified monthly view combining Task Deadlines and Schedule Events with conflict detection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            // Pop out Standalone Calendar Window Action
            Button {
                openWindow(id: VantageWindowID.standaloneCalendar)
            } label: {
                Label("Open Standalone Window", systemImage: "macwindow.on.rectangle")
                    .font(.callout.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.workAccent)
        }
    }
    
    // MARK: - Month Navigator Bar
    
    private var monthNavigatorBar: some View {
        HStack {
            Text(monthYearString)
                .font(.title2.weight(.bold))
            
            Spacer()
            
            Button("Today") {
                withAnimation {
                    currentMonthDate = Date()
                    selectedDate = Date()
                }
            }
            .buttonStyle(.bordered)
            
            HStack(spacing: 8) {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .padding(8)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.bold))
                        .padding(8)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Monthly Calendar Grid
    
    private var monthlyGridView: some View {
        VStack(spacing: 8) {
            // Weekday Symbol Headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(0..<daysInMonthGrid.count, id: \.self) { index in
                    if let date = daysInMonthGrid[index] {
                        dayCell(for: date)
                    } else {
                        // Empty slot
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                            .frame(height: 78)
                    }
                }
            }
        }
    }
    
    // Single Day Cell in Monthly Grid
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        let eventsOnDay = allEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let tasksOnDay = allTasks.filter { task in
            guard let due = task.dueDate else { return false }
            if !showCompletedTasks && task.status == .completed { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }
        
        let hasConflict = hasTimeConflict(events: eventsOnDay)
        
        // Marker breakdown
        let academicEvents = eventsOnDay.filter { $0.category == .academic }.count
        let workEvents = eventsOnDay.filter { $0.category == .work }.count
        let academicTasks = tasksOnDay.filter { $0.category == .academic }.count
        let workTasks = tasksOnDay.filter { $0.category == .work }.count
        
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedDate = date
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Day Number & Conflict Badge Header
                HStack {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(.callout, design: .rounded, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? Color.workAccent : (isSelected ? .white : .primary))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(isToday ? Color.workAccent.opacity(0.25) : (isSelected ? Color.white.opacity(0.18) : Color.clear))
                        )
                    
                    Spacer()
                    
                    // Coral Conflict Warning Icon (#E46B72)
                    if hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.conflictWarning)
                            .help("Time overlap conflict detected on this date")
                    }
                }
                
                Spacer()
                
                // Item Indicators: Task Deadlines & Schedule Events
                VStack(alignment: .leading, spacing: 2) {
                    // Academic Items Marker (Indigo #7779C9)
                    if academicEvents > 0 || academicTasks > 0 {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.academicAccent)
                                .frame(width: 5, height: 5)
                            
                            if academicEvents + academicTasks > 1 {
                                Text("\(academicEvents + academicTasks)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.academicAccent)
                            }
                        }
                    }
                    
                    // Work Items Marker (Teal #2A9D98)
                    if workEvents > 0 || workTasks > 0 {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.workAccent)
                                .frame(width: 5, height: 5)
                            
                            if workEvents + workTasks > 1 {
                                Text("\(workEvents + workTasks)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.workAccent)
                            }
                        }
                    }
                }
            }
            .padding(7)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                hasConflict ? Color.conflictWarning : (isSelected ? Color.workAccent : Color.white.opacity(0.08)),
                                lineWidth: hasConflict ? 1.5 : (isSelected ? 1.5 : 1)
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Day Agenda & Conflict Inspector Panel
    
    private var dayAgendaInspector: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Selected Day Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.isDateInToday(selectedDate) ? "Today's Agenda" : selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                        .font(.title3.weight(.bold))
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Button {
                    showCreateEventSheet = true
                } label: {
                    Label("Add Event", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Color.workAccent)
            }
            
            // Coral Conflict Warning Banner
            if hasConflictOnSelectedDay {
                coralConflictAlertBanner
            }
            
            // Section 1: Fixed Schedule Events
            VStack(alignment: .leading, spacing: 10) {
                Label("Schedule Events (\(selectedDayEvents.count))", systemImage: "clock")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                if selectedDayEvents.isEmpty {
                    Text("No events scheduled on this day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(selectedDayEvents) { event in
                            let isConflicting = isEventConflicting(event, in: selectedDayEvents)
                            agendaEventRow(event: event, hasConflict: isConflicting)
                        }
                    }
                }
            }
            
            Divider().overlay(.white.opacity(0.1))
            
            // Section 2: Task Deadlines Due on This Date
            VStack(alignment: .leading, spacing: 10) {
                Label("Task Deadlines (\(selectedDayTasks.count))", systemImage: "calendar.badge.exclamationmark")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                if selectedDayTasks.isEmpty {
                    Text("No task deadlines falling on this date.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(selectedDayTasks) { task in
                            agendaTaskRow(task: task)
                        }
                    }
                }
            }
        }
        .padding(20)
        .vantageGlassCard()
    }
    
    // Coral Conflict Alert Banner (#E46B72)
    private var coralConflictAlertBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(Color.conflictWarning)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Schedule Conflict Detected")
                    .font(.headline)
                    .foregroundStyle(Color.conflictWarning)
                
                Text("Two or more fixed-time events overlap during this day. Please adjust start or end times to prevent double-booking.")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.85))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.conflictWarning.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.conflictWarning.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private func agendaEventRow(event: ScheduleEvent, hasConflict: Bool) -> some View {
        Button {
            eventToEdit = event
        } label: {
            HStack(alignment: .center, spacing: 12) {
                // Category Vertical Bar
                Rectangle()
                    .fill(event.category.accentColor)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(event.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        CategoryBadge(category: event.category, isCompact: true)
                    }
                    
                    HStack(spacing: 6) {
                        Text(event.formattedTimeRange)
                            .font(.caption)
                            .foregroundStyle(hasConflict ? Color.conflictWarning : .secondary)
                            .fontWeight(hasConflict ? .bold : .regular)
                        
                        if let location = event.location {
                            Text("• \(location)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if hasConflict {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .font(.caption2)
                            Text("Overlapping commitment")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(Color.conflictWarning)
                        .padding(.top, 1)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(hasConflict ? Color.conflictWarning.opacity(0.1) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(hasConflict ? Color.conflictWarning.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                eventToEdit = event
            } label: {
                Label("Edit Event", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                modelContext.delete(event)
                try? modelContext.save()
            } label: {
                Label("Delete Event", systemImage: "trash")
            }
        }
    }
    
    private func agendaTaskRow(task: Task) -> some View {
        Button {
            taskToEdit = task
        } label: {
            HStack(spacing: 10) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .completed ? .green : .secondary)
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(task.status == .completed)
                    
                    HStack(spacing: 6) {
                        CategoryBadge(category: task.category, isCompact: true)
                        Text("Est: \(task.formattedDuration)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                PriorityBadge(priority: task.priority)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                taskToEdit = task
            } label: {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button {
                task.status = (task.status == .completed ? .inProgress : .completed)
                try? modelContext.save()
            } label: {
                Label(task.status == .completed ? "Mark Incomplete" : "Mark Complete", systemImage: task.status == .completed ? "circle" : "checkmark.circle")
            }
            
            Divider()
            
            Button(role: .destructive) {
                modelContext.delete(task)
                try? modelContext.save()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Conflict Detection Logic
    
    /// Detects all pairs of fixed-time Schedule Events that overlap on the same date
    private func detectConflicts(among events: [ScheduleEvent]) -> [(ScheduleEvent, ScheduleEvent)] {
        let fixed = events.filter { !$0.isAllDay }
        guard fixed.count > 1 else { return [] }
        
        var conflicts: [(ScheduleEvent, ScheduleEvent)] = []
        for i in 0..<fixed.count {
            for j in (i + 1)..<fixed.count {
                let e1 = fixed[i]
                let e2 = fixed[j]
                if e1.startTime < e2.endTime && e2.startTime < e1.endTime {
                    conflicts.append((e1, e2))
                }
            }
        }
        return conflicts
    }
    
    private func hasTimeConflict(events: [ScheduleEvent]) -> Bool {
        !detectConflicts(among: events).isEmpty
    }
    
    private func isEventConflicting(_ event: ScheduleEvent, in events: [ScheduleEvent]) -> Bool {
        guard !event.isAllDay else { return false }
        return events.contains { other in
            other.id != event.id && !other.isAllDay &&
            event.startTime < other.endTime && other.startTime < event.endTime
        }
    }
    
    private func changeMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: currentMonthDate) {
            currentMonthDate = next
        }
    }
}
