//
//  SettingsView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Settings destination for editing appearance, calendar preferences, workload thresholds,
/// and executing system maintenance operations (CRUD for settings and batch operations).
public struct SettingsView: View {
    @Query private var settingsList: [ApplicationSettings]
    @Query private var allTasks: [Task]
    @Query private var allEvents: [ScheduleEvent]
    @Query private var allProjects: [CourseProject]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var showResetAlert: Bool = false
    @State private var showPurgeCompletedAlert: Bool = false
    @State private var statusToastMessage: String? = nil
    
    public init() {}
    
    private var settings: ApplicationSettings {
        if let first = settingsList.first {
            return first
        }
        return ApplicationSettings.fetchOrCreate(in: modelContext)
    }
    
    public var body: some View {
        @Bindable var boundSettings = settings
        
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                headerSection
                
                // Status Toast
                if let message = statusToastMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.15)))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 1. Appearance Preferences
                appearanceSection(settings: boundSettings)
                
                // 2. Calendar Preferences
                calendarSection(settings: boundSettings)
                
                // 3. Workload & Burnout Thresholds
                workloadSection(settings: boundSettings)
                
                // 4. Maintenance & Factory Reset
                maintenanceSection(settings: boundSettings)
            }
            .padding(28)
        }
        .navigationTitle("Settings")
        .alert("Reset Settings to Factory Defaults?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to Defaults", role: .destructive) {
                resetSettingsToDefaults(settings: boundSettings)
            }
        } message: {
            Text("This will restore default appearance theme, calendar settings, and workload limits.")
        }
        .alert("Purge Completed Tasks?", isPresented: $showPurgeCompletedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Purge Tasks", role: .destructive) {
                purgeCompletedTasks()
            }
        } message: {
            Text("This will permanently remove all tasks marked as completed. This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vantage Configuration")
                .font(.system(.title, design: .rounded, weight: .bold))
            Text("Tailor visionOS spatial window behaviors, calendar scheduling defaults, and cognitive workload guardrails.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func appearanceSection(settings: ApplicationSettings) -> some View {
        @Bindable var item = settings
        return VStack(alignment: .leading, spacing: 14) {
            Label("Appearance & Spatial Environment", systemImage: "sparkles")
                .font(.title3.weight(.bold))
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme Style")
                            .font(.body.weight(.medium))
                        Text("Controls the global color scheme for all windows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Theme Style", selection: $item.appearanceTheme) {
                        Text("Dark Glass").tag("Dark")
                        Text("Light Glass").tag("Light")
                        Text("System").tag("System")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                    .onChange(of: item.appearanceTheme) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Window Density")
                            .font(.body.weight(.medium))
                        Text("Density of cards and list spacing across visionOS spaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Content Density", selection: $item.contentDensity) {
                        Text("Comfortable").tag("Comfortable")
                        Text("Compact").tag("Compact")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    .onChange(of: item.contentDensity) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                Toggle(isOn: $item.enableGlassmorphicGlow) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ambient Glassmorphic Glow")
                        Text("Enables subtle spatial edge luminescence on active cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: item.enableGlassmorphicGlow) { _, _ in autoSave() }
                
                Divider().overlay(.white.opacity(0.1))
                
                Toggle(isOn: $item.enableSpatialSoundFeedback) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spatial Audio Feedback")
                        Text("Play directional acoustic haptics upon completing tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: item.enableSpatialSoundFeedback) { _, _ in autoSave() }
            }
            .padding(18)
            .vantageGlassCard()
        }
    }
    
    private func calendarSection(settings: ApplicationSettings) -> some View {
        @Bindable var item = settings
        return VStack(alignment: .leading, spacing: 14) {
            Label("Calendar & Timetable", systemImage: "calendar")
                .font(.title3.weight(.bold))
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("First Day of Week")
                            .font(.body.weight(.medium))
                        Text("Controls calendar grid start column and week calculation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("First Day", selection: $item.firstDayOfWeek) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onChange(of: item.firstDayOfWeek) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Event Duration")
                            .font(.body.weight(.medium))
                        Text("Initial length for newly scheduled lectures, shifts, and meetings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Stepper("\(item.defaultEventDurationMinutes) min", value: $item.defaultEventDurationMinutes, in: 15...180, step: 15)
                        .onChange(of: item.defaultEventDurationMinutes) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                Toggle(isOn: $item.showCompletedTasksInCalendar) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Display Finished Tasks on Calendar")
                        Text("Overlay completed assignments and work deliverables on the timetable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: item.showCompletedTasksInCalendar) { _, _ in autoSave() }
            }
            .padding(18)
            .vantageGlassCard()
        }
    }
    
    private func workloadSection(settings: ApplicationSettings) -> some View {
        @Bindable var item = settings
        return VStack(alignment: .leading, spacing: 14) {
            Label("Cognitive Workload Guardrails", systemImage: "brain.head.profile")
                .font(.title3.weight(.bold))
            
            VStack(spacing: 18) {
                // Max Academic Hours
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Max Daily Study Target")
                        Spacer()
                        Text(String(format: "%.1f hours", item.maxDailyAcademicHours))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.academicAccent)
                    }
                    Slider(value: $item.maxDailyAcademicHours, in: 2.0...12.0, step: 0.5)
                        .tint(Color.academicAccent)
                        .onChange(of: item.maxDailyAcademicHours) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                // Max Work Hours
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Max Daily Work Target")
                        Spacer()
                        Text(String(format: "%.1f hours", item.maxDailyWorkHours))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.workAccent)
                    }
                    Slider(value: $item.maxDailyWorkHours, in: 2.0...14.0, step: 0.5)
                        .tint(Color.workAccent)
                        .onChange(of: item.maxDailyWorkHours) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Max Active Tasks Concurrency")
                            .font(.body.weight(.medium))
                        Text("Threshold of concurrent in-progress items before cognitive warning")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Stepper("\(item.maxConcurrentActiveTasks) tasks", value: $item.maxConcurrentActiveTasks, in: 1...15)
                        .onChange(of: item.maxConcurrentActiveTasks) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Urgent Due Date Alert Window")
                            .font(.body.weight(.medium))
                        Text("Hours prior to deadline when task is flagged as imminent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Stepper("\(item.overdueWarningThresholdHours) hrs", value: $item.overdueWarningThresholdHours, in: 6...72, step: 6)
                        .onChange(of: item.overdueWarningThresholdHours) { _, _ in autoSave() }
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                Toggle(isOn: $item.enableBurnoutAlerts) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Intelligent Burnout Warnings")
                        Text("Proactively notify across Overview and Insights when backlog exceeds thresholds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: item.enableBurnoutAlerts) { _, _ in autoSave() }
            }
            .padding(18)
            .vantageGlassCard()
        }
    }
    
    private func maintenanceSection(settings: ApplicationSettings) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Data Management & Maintenance", systemImage: "wrench.and.screwdriver")
                .font(.title3.weight(.bold))
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Purge Completed Tasks")
                            .font(.body.weight(.medium))
                        Text("\(allTasks.filter { $0.status == .completed }.count) finished tasks currently stored in SwiftData")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        showPurgeCompletedAlert = true
                    } label: {
                        Label("Purge Completed", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(allTasks.filter { $0.status == .completed }.isEmpty)
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Factory Reset Settings")
                            .font(.body.weight(.medium))
                        Text("Restore visual theme, calendar preferences, and workload limits to initial defaults")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
            .padding(18)
            .vantageGlassCard()
        }
    }
    
    // MARK: - Actions
    
    private func autoSave() {
        settings.lastModified = Date()
        try? modelContext.save()
    }
    
    private func resetSettingsToDefaults(settings: ApplicationSettings) {
        settings.appearanceTheme = "Dark"
        settings.accentColorHex = "#0A84FF"
        settings.enableGlassmorphicGlow = true
        settings.enableSpatialSoundFeedback = true
        settings.contentDensity = "Comfortable"
        settings.firstDayOfWeek = 1
        settings.defaultEventDurationMinutes = 60
        settings.dayStartHour = 8
        settings.dayEndHour = 18
        settings.showCompletedTasksInCalendar = false
        settings.defaultCalendarView = "Week"
        settings.maxDailyAcademicHours = 6.0
        settings.maxDailyWorkHours = 8.0
        settings.maxConcurrentActiveTasks = 5
        settings.overdueWarningThresholdHours = 24
        settings.enableBurnoutAlerts = true
        settings.lastModified = Date()
        
        try? modelContext.save()
        
        withAnimation {
            statusToastMessage = "Settings restored to factory defaults."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                statusToastMessage = nil
            }
        }
    }
    
    private func purgeCompletedTasks() {
        let completed = allTasks.filter { $0.status == .completed }
        for task in completed {
            modelContext.delete(task)
        }
        try? modelContext.save()
        
        withAnimation {
            statusToastMessage = "Purged \(completed.count) completed tasks."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                statusToastMessage = nil
            }
        }
    }
}
