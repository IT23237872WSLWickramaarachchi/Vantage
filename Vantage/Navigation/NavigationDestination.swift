//
//  NavigationDestination.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI

/// Exactly six sidebar destinations for the Vantage unified study and work planner
public enum NavigationDestination: String, CaseIterable, Identifiable, Hashable, Sendable {
    case overview = "Overview"
    case academic = "Academic"
    case work = "Work"
    case calendar = "Calendar"
    case insights = "Insights"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    /// Display title for sidebar item
    public var title: String { rawValue }
    
    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .overview:
            return "square.grid.2x2.fill"
        case .academic:
            return "graduationcap.fill"
        case .work:
            return "briefcase.fill"
        case .calendar:
            return "calendar"
        case .insights:
            return "chart.xyaxis.line"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    /// Subtitle description of the destination
    public var subtitle: String {
        switch self {
        case .overview:
            return "Daily summary & active priorities"
        case .academic:
            return "Courses, assignments & study log"
        case .work:
            return "Projects, deliverables & sprint items"
        case .calendar:
            return "Unified schedule & timetable"
        case .insights:
            return "Workload balance & burnout analytics"
        case .settings:
            return "Preferences & threshold controls"
        }
    }
    
    /// Associated accent color (academic gets #7779C9, work gets #2A9D98, others get neutral/visionOS glass accents)
    public var accentColor: Color {
        switch self {
        case .academic:
            return Color.academicAccent
        case .work:
            return Color.workAccent
        case .overview:
            return Color(hex: "#5E5CE6")
        case .calendar:
            return Color(hex: "#30B0C7")
        case .insights:
            return Color(hex: "#FF9F0A")
        case .settings:
            return Color.secondary
        }
    }
}
