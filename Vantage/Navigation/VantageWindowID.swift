//
//  VantageWindowID.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import Foundation

/// Centralized identifiers for visionOS multi-window management
public enum VantageWindowID {
    /// Primary window presenting the NavigationSplitView sidebar and destination content
    public static let main = "vantage.main"
    
    /// Dedicated standalone calendar window (spatial schedule without navigation sidebar)
    public static let standaloneCalendar = "vantage.calendar.standalone"
    
    /// Utility inspector window for inspecting and editing an individual task by UUID
    public static let taskDetail = "vantage.task.detail"
}
