//
//  StandaloneCalendarView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Dedicated standalone calendar window presentation (without the NavigationSplitView sidebar).
/// Designed for persistent spatial placement in visionOS alongside other workspaces.
public struct StandaloneCalendarView: View {
    @Query(sort: \ScheduleEvent.startTime) private var allEvents: [ScheduleEvent]
    @Query(sort: \Task.dueDate) private var allTasks: [Task]
    @Query private var settingsList: [ApplicationSettings]
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedDate: Date = Date()
    @State private var selectedFilter: CalendarCategoryFilter = .all
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
    
    private var showCompletedTasks: Bool {
        settingsList.first?.showCompletedTasksInCalendar ?? false
    }
    
    private var weekDays: [Date] {
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var eventsForSelectedDate: [ScheduleEvent] {
        allEvents.filter { event in
            guard calendar.isDate(event.date, inSameDayAs: selectedDate) else { return false }
            switch selectedFilter {
            case .all: return true
            case .academic: return event.category == .academic
            case .work: return event.category == .work
            }
        }
    }
    
    private var tasksDueOnSelectedDate: [Task] {
        allTasks.filter { task in
            guard let dueDate = task.dueDate, calendar.isDate(dueDate, inSameDayAs: selectedDate) else { return false }
            if !showCompletedTasks && task.status == .completed { return false }
            switch selectedFilter {
            case .all: return true
            case .academic: return task.category == .academic
            case .work: return task.category == .work
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Standalone Header Bar
            topBar
            
            Divider().overlay(.white.opacity(0.12))
            
            // Weekly Date Picker Ribbon
            weekRibbon
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            
            Divider().overlay(.white.opacity(0.08))
            
            // Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Day Commitments Summary Pill
                    daySummaryHeader
                    
                    // Tasks Due Section
                    if !tasksDueOnSelectedDate.isEmpty {
                        tasksDueSection
                    }
                    
                    // Scheduled Events Timeline
                    eventsTimelineSection
                }
                .padding(24)
            }
        }
        .preferredColorScheme(settingsList.first?.appearanceTheme == "Light" ? .light : (settingsList.first?.appearanceTheme == "System" ? nil : .dark))
        // visionOS bottom ornament for persistent control
        .ornament(attachmentAnchor: .scene(.bottom)) {
            ornamentControls
        }
        .sheet(isPresented: $showCreateEventSheet) {
            ScheduleEventEditorSheet(initialDate: selectedDate, initialCategory: selectedFilter == .academic ? .academic : .work)
        }
        .sheet(item: $eventToEdit) { event in
            ScheduleEventEditorSheet(eventToEdit: event)
        }
        .sheet(item: $taskToEdit) { task in
            TaskEditorSheet(taskToEdit: task)
        }
    }
    
    // MARK: - Subviews
    
    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(Color.workAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vantage Spatial Timetable")
                        .font(.headline)
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Category Filter Pills
            HStack(spacing: 8) {
                ForEach(CalendarCategoryFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.caption.weight(selectedFilter == filter ? .bold : .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? filter.color.opacity(0.2) : Color.white.opacity(0.05))
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedFilter == filter ? filter.color : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(selectedFilter == filter ? filter.color : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Focus Main Window Button
            Button {
                openWindow(id: VantageWindowID.main)
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.subheadline)
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Open Main Vantage Workspace")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var weekRibbon: some View {
        HStack(spacing: 12) {
            ForEach(weekDays, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(day)
                
                Button {
                    selectedDate = day
                } label: {
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(isSelected ? .white : .secondary)
                        
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(.title3, design: .rounded, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isToday && !isSelected ? Color.workAccent : (isSelected ? .white : .primary))
                        
                        // Dots for events on that day
                        HStack(spacing: 3) {
                            if hasAcademicEvents(on: day) {
                                Circle().fill(Color.academicAccent).frame(width: 4, height: 4)
                            }
                            if hasWorkEvents(on: day) {
                                Circle().fill(Color.workAccent).frame(width: 4, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? Color.workAccent.opacity(0.3) : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color.workAccent : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var daySummaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(calendar.isDateInToday(selectedDate) ? "Today's Agenda" : selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.title2.weight(.bold))
                Text("\(eventsForSelectedDate.count) scheduled sessions • \(tasksDueOnSelectedDate.count) deadlines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private var tasksDueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tasks Due Today", systemImage: "checklist")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                ForEach(tasksDueOnSelectedDate) { task in
                    TaskCardRow(task: task)
                }
            }
        }
    }
    
    private var eventsTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Timetable Schedule", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if eventsForSelectedDate.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "sun.max.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow.opacity(0.7))
                    Text("No events scheduled for this day")
                        .font(.headline)
                    Text("Enjoy the focused block or allocate time for study & deep work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(36)
                .vantageGlassCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(eventsForSelectedDate) { event in
                        standaloneEventCard(event: event)
                    }
                }
            }
        }
    }
    
    private func standaloneEventCard(event: ScheduleEvent) -> some View {
        Button {
            eventToEdit = event
        } label: {
            HStack(alignment: .center, spacing: 16) {
                // Time Pill
                VStack(alignment: .center, spacing: 2) {
                    Text(event.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.callout.weight(.bold))
                    Text(event.endTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 75)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(event.category.accentColor.opacity(0.12))
                )
                
                // Vertical bar
                Rectangle()
                    .fill(event.category.accentColor)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                // Information
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.title)
                            .font(.headline)
                        Spacer()
                        CategoryBadge(category: event.category)
                    }
                    
                    if let project = event.courseProject {
                        Text("\(project.identifier) • \(project.name)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(event.category.accentColor)
                    }
                    
                    if !event.notes.isEmpty {
                        Text(event.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let location = event.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                            Text(location)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .vantageGlassCard(borderColor: event.category.accentColor.opacity(0.25))
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
    
    private var ornamentControls: some View {
        HStack(spacing: 14) {
            Button("Today") {
                withAnimation { selectedDate = Date() }
            }
            .buttonStyle(.bordered)
            
            Divider().frame(height: 20)
            
            Button {
                showCreateEventSheet = true
            } label: {
                Label("Add Event", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.workAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassBackgroundEffect()
    }
    
    private func hasAcademicEvents(on day: Date) -> Bool {
        allEvents.contains { $0.category == .academic && calendar.isDate($0.date, inSameDayAs: day) }
    }
    
    private func hasWorkEvents(on day: Date) -> Bool {
        allEvents.contains { $0.category == .work && calendar.isDate($0.date, inSameDayAs: day) }
    }
}
