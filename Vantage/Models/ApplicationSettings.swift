//
//  ApplicationSettings.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import Foundation
import SwiftData

/// Stores user configurations for appearance, calendar layout, and workload thresholds.
/// Persisted as a SwiftData `@Model` to allow synchronization across visionOS, iOS, and macOS.
@Model
public final class ApplicationSettings {
    /// Unique identifier for the settings record (singleton pattern)
    @Attribute(.unique)
    public var id: UUID = UUID()
    
    // MARK: - Appearance Preferences
    /// Theme preference: "System", "Glass Minimal", "Spatial Vibrant", "Dark"
    public var appearanceTheme: String = "System"
    
    /// User's chosen accent color hex code (default Vantage cyan/blue)
    public var accentColorHex: String = "#0A84FF"
    
    /// visionOS specific: Enables ambient spatial glow on cards and windows
    public var enableGlassmorphicGlow: Bool = true
    
    /// visionOS specific: Enables spatial sound feedback on task completion and timer events
    public var enableSpatialSoundFeedback: Bool = true
    
    /// Density preference for visionOS windows: "Comfortable" vs "Compact"
    public var contentDensity: String = "Comfortable"
    
    // MARK: - Calendar Preferences
    /// First day of the week: 1 for Sunday, 2 for Monday (matches Calendar.current component)
    public var firstDayOfWeek: Int = 1
    
    /// Default duration for newly created events in minutes
    public var defaultEventDurationMinutes: Int = 60
    
    /// Typical start of day hour (0 - 23), default 8:00 AM
    public var dayStartHour: Int = 8
    
    /// Typical end of day hour (0 - 23), default 18:00 (6:00 PM)
    public var dayEndHour: Int = 18
    
    /// Whether completed tasks should be rendered alongside calendar events
    public var showCompletedTasksInCalendar: Bool = false
    
    /// Default calendar presentation: "Day", "Week", "Timeline"
    public var defaultCalendarView: String = "Week"
    
    // MARK: - Workload Thresholds
    /// Maximum recommended daily academic study hours before warning
    public var maxDailyAcademicHours: Double = 6.0
    
    /// Maximum recommended daily employment/work hours before warning
    public var maxDailyWorkHours: Double = 8.0
    
    /// Maximum number of active ("In Progress") tasks before triggering cognitive load alert
    public var maxConcurrentActiveTasks: Int = 5
    
    /// Number of hours prior to deadline when an urgent alert is triggered
    public var overdueWarningThresholdHours: Int = 24
    
    /// Enables AI/heuristic notifications when combined study + work time exceeds threshold
    public var enableBurnoutAlerts: Bool = true
    
    /// Timestamp when settings were last modified
    public var lastModified: Date = Date()
    
    // MARK: - Initializer
    public init(
        id: UUID = UUID(),
        appearanceTheme: String = "System",
        accentColorHex: String = "#0A84FF",
        enableGlassmorphicGlow: Bool = true,
        enableSpatialSoundFeedback: Bool = true,
        contentDensity: String = "Comfortable",
        firstDayOfWeek: Int = 1,
        defaultEventDurationMinutes: Int = 60,
        dayStartHour: Int = 8,
        dayEndHour: Int = 18,
        showCompletedTasksInCalendar: Bool = false,
        defaultCalendarView: String = "Week",
        maxDailyAcademicHours: Double = 6.0,
        maxDailyWorkHours: Double = 8.0,
        maxConcurrentActiveTasks: Int = 5,
        overdueWarningThresholdHours: Int = 24,
        enableBurnoutAlerts: Bool = true,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.appearanceTheme = appearanceTheme
        self.accentColorHex = accentColorHex
        self.enableGlassmorphicGlow = enableGlassmorphicGlow
        self.enableSpatialSoundFeedback = enableSpatialSoundFeedback
        self.contentDensity = contentDensity
        self.firstDayOfWeek = firstDayOfWeek
        self.defaultEventDurationMinutes = defaultEventDurationMinutes
        self.dayStartHour = dayStartHour
        self.dayEndHour = dayEndHour
        self.showCompletedTasksInCalendar = showCompletedTasksInCalendar
        self.defaultCalendarView = defaultCalendarView
        self.maxDailyAcademicHours = maxDailyAcademicHours
        self.maxDailyWorkHours = maxDailyWorkHours
        self.maxConcurrentActiveTasks = maxConcurrentActiveTasks
        self.overdueWarningThresholdHours = overdueWarningThresholdHours
        self.enableBurnoutAlerts = enableBurnoutAlerts
        self.lastModified = lastModified
    }
    
    // MARK: - Singleton Helper
    /// Fetches the existing settings entity, or creates and inserts a default one if none exists.
    @MainActor
    public static func fetchOrCreate(in context: ModelContext) -> ApplicationSettings {
        let descriptor = FetchDescriptor<ApplicationSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let fresh = ApplicationSettings()
        context.insert(fresh)
        try? context.save()
        return fresh
    }
}
