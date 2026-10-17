//
//  PlannerEnums.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI

// MARK: - Planner Category (Unified Academic & Work)
/// Represents the primary classification for tasks, projects, and schedule events.
/// Vantage unifies Academic and Work domains into a single cohesive data pipeline.
public enum PlannerCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case academic = "Academic"
    case work = "Work"
    
    public var id: String { rawValue }
    
    /// Display title for UI presentation
    public var title: String { rawValue }
    
    /// SF Symbol icon suitable for visionOS ornaments and spatial labels
    public var iconName: String {
        switch self {
        case .academic:
            return "graduationcap.fill"
        case .work:
            return "briefcase.fill"
        }
    }
    
    /// Default theme color for badges and progress gauges in visionOS
    public var accentColor: Color {
        switch self {
        case .academic:
            return Color.academicAccent
        case .work:
            return Color.workAccent
        }
    }
}

// MARK: - Priority
/// Task priority levels used for workload calculations, sorting, and alert indicators.
public enum Priority: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    public var id: String { rawValue }
    
    public var title: String { rawValue }
    
    /// Order value for Comparable conformance (Low < Medium < High)
    public var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
    
    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
    
    public var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .low: return .secondary
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Task Status
/// Current progression state of a task.
public enum TaskStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case toDo = "To Do"
    case inProgress = "In Progress"
    case completed = "Completed"
    
    public var id: String { rawValue }
    
    public var title: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .toDo: return "circle"
        case .inProgress: return "hourglass"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    public var isCompleted: Bool {
        self == .completed
    }
}

// MARK: - Calendar Category Filter
public enum CalendarCategoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All Events"
    case academic = "Academic Only"
    case work = "Work Only"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
    
    public var color: Color {
        switch self {
        case .all: return .white
        case .academic: return Color.academicAccent
        case .work: return Color.workAccent
        }
    }
}
