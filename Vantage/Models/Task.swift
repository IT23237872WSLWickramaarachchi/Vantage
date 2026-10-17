//
//  Task.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import Foundation
import SwiftData

/// Unified Task model for both Academic and Work items.
/// Shared across both domains without subclassing or separate entities, as unified by `category`.
@Model
public final class Task {
    /// Unique identifier for the task
    @Attribute(.unique)
    public var id: UUID = UUID()
    
    /// Short summary / title of the task
    public var title: String = ""
    
    /// In-depth notes or instructions.
    /// Note: Named `taskDescription` because SwiftData's `@Model` macro reserves the identifier `description`.
    public var taskDescription: String = ""
    
    /// Unified domain category: Academic or Work
    public var category: PlannerCategory = PlannerCategory.academic
    
    /// Optional association with a course or project
    public var courseProject: CourseProject?
    
    /// Due date for completion
    public var dueDate: Date?
    
    /// Indicates whether `dueDate` contains an explicit hour/minute deadline or is date-only (all-day).
    public var hasSpecificTime: Bool = false
    
    /// Priority level: Low, Medium, or High
    public var priority: Priority = Priority.medium
    
    /// Estimated time to complete the task, stored in seconds (TimeInterval).
    public var estimatedCompletionTime: TimeInterval = 1800 // Default 30 minutes
    
    /// Current lifecycle status: To Do, In Progress, or Completed
    public var status: TaskStatus = TaskStatus.toDo
    
    /// Creation timestamp
    public var createdAt: Date = Date()
    
    /// Optional timestamp recorded when task is marked completed
    public var completedAt: Date?
    
    // MARK: - Initializer
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        category: PlannerCategory,
        courseProject: CourseProject? = nil,
        dueDate: Date? = nil,
        hasSpecificTime: Bool = false,
        priority: Priority = .medium,
        estimatedCompletionTime: TimeInterval = 1800,
        status: TaskStatus = .toDo,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = description
        self.category = category
        self.courseProject = courseProject
        self.dueDate = dueDate
        self.hasSpecificTime = hasSpecificTime
        self.priority = priority
        self.estimatedCompletionTime = estimatedCompletionTime
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
    
    // MARK: - Computed Helpers for visionOS UI
    
    /// Helper to access estimated completion time in whole minutes
    public var estimatedCompletionMinutes: Int {
        get { Int(estimatedCompletionTime / 60) }
        set { estimatedCompletionTime = TimeInterval(newValue * 60) }
    }
    
    /// Formatted duration string for spatial UI chips (e.g., "1h 30m" or "45m")
    public var formattedDuration: String {
        let minutes = estimatedCompletionMinutes
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    /// Indicates if this task is past its due date and not completed
    public var isOverdue: Bool {
        guard let dueDate, status != .completed else { return false }
        return dueDate < Date()
    }
}

// Convenience alias to avoid confusion with Swift's built-in asynchronous `Task` struct
public typealias VantageTask = Task
public typealias TaskItem = Task
