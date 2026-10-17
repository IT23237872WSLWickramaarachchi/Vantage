//
//  CourseProject.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import Foundation
import SwiftData

/// Represents an Academic Course (e.g., "Distributed Systems") or a Work Project (e.g., "VisionOS Launch").
/// Both share this unified structure, categorized by `PlannerCategory`.
@Model
public final class CourseProject {
    /// Unique identifier for SwiftData persistence
    @Attribute(.unique)
    public var id: UUID = UUID()
    
    /// Display name of the course or project
    public var name: String = ""
    
    /// Domain category: Academic or Work
    public var category: PlannerCategory = PlannerCategory.academic
    
    /// External or institutional identifier (e.g. course code "CS 450", client code, or project slug "PRJ-901")
    public var identifier: String = ""
    
    /// Color hex string for custom spatial tag/ornament styling (e.g. "#5856D6")
    public var colorHex: String = "#0A84FF"
    
    /// SF Symbol icon name for visual representation in visionOS lists and cards
    public var iconName: String = "folder.fill"
    
    /// Timestamp when this course or project was registered
    public var createdAt: Date = Date()
    
    // MARK: - Relationships
    /// All tasks belonging to this course or project. Nullified if this course/project is deleted.
    @Relationship(deleteRule: .nullify, inverse: \Task.courseProject)
    public var tasks: [Task]? = []
    
    /// All calendar/schedule events associated with this course or project.
    @Relationship(deleteRule: .nullify, inverse: \ScheduleEvent.courseProject)
    public var scheduleEvents: [ScheduleEvent]? = []
    
    // MARK: - Initializer
    public init(
        id: UUID = UUID(),
        name: String,
        category: PlannerCategory,
        identifier: String,
        colorHex: String = "#0A84FF",
        iconName: String = "folder.fill",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.identifier = identifier
        self.colorHex = colorHex
        self.iconName = iconName
        self.createdAt = createdAt
        self.tasks = []
        self.scheduleEvents = []
    }
}

// Convenience alias to match requirement naming
public typealias CourseOrProject = CourseProject
