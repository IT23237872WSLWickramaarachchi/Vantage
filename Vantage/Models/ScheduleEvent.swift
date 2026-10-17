//
//  ScheduleEvent.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import Foundation
import SwiftData

/// Represents a calendar or timetable event, such as a lecture, lab, sprint standup, or client meeting.
@Model
public final class ScheduleEvent {
    /// Unique identifier for the schedule event
    @Attribute(.unique)
    public var id: UUID = UUID()
    
    /// Title of the event (e.g., "CS 450 Lecture", "Design Review")
    public var title: String = ""
    
    /// Unified domain category: Academic or Work
    public var category: PlannerCategory = PlannerCategory.academic
    
    /// Calendar day of the event
    public var date: Date = Date()
    
    /// Scheduled start time
    public var startTime: Date = Date()
    
    /// Scheduled end time
    public var endTime: Date = Date()
    
    /// Optional association with an academic course or work project
    public var courseProject: CourseProject?
    
    /// Location or meeting URL (e.g., "Hall 3B", "Zoom Link", or virtual room)
    public var location: String?
    
    /// Optional supplementary notes for the event
    public var notes: String = ""
    
    /// Whether this event spans the entire day
    public var isAllDay: Bool = false
    
    /// Timestamp when this event was recorded
    public var createdAt: Date = Date()
    
    // MARK: - Initializer
    public init(
        id: UUID = UUID(),
        title: String,
        category: PlannerCategory,
        date: Date,
        startTime: Date,
        endTime: Date,
        courseProject: CourseProject? = nil,
        location: String? = nil,
        notes: String = "",
        isAllDay: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.courseProject = courseProject
        self.location = location
        self.notes = notes
        self.isAllDay = isAllDay
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    /// Total duration of the event in seconds
    public var duration: TimeInterval {
        max(0, endTime.timeIntervalSince(startTime))
    }
    
    /// Formatted time string (e.g. "10:00 AM - 11:30 AM")
    public var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}
