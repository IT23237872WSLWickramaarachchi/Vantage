//
//  VantageDataContainer.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import Foundation
import SwiftData

/// Centralized SwiftData container configuration and preview seed generator for Vantage.
public final class VantageDataContainer {
    
    /// The core schema containing all registered SwiftData models
    public static let schema = Schema([
        Task.self,
        CourseProject.self,
        ScheduleEvent.self,
        ApplicationSettings.self
    ])
    
    /// Creates a production or testing ModelContainer with appropriate configuration
    public static func create(isStoredInMemoryOnly: Bool = false) -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer for Vantage: \(error.localizedDescription)")
        }
    }
    
    /// Dedicated in-memory container pre-seeded with sample data for visionOS SwiftUI previews
    @MainActor
    public static var previewContainer: ModelContainer = {
        let container = create(isStoredInMemoryOnly: true)
        let context = container.mainContext
        
        // Seed Default Settings
        _ = ApplicationSettings.fetchOrCreate(in: context)
        
        // Seed Academic Course
        let csCourse = CourseProject(
            name: "Distributed Systems & Cloud Computing",
            category: .academic,
            identifier: "CS-450",
            colorHex: "#AF52DE",
            iconName: "network"
        )
        context.insert(csCourse)
        
        // Seed Work Project
        let visionProject = CourseProject(
            name: "Vantage visionOS Spatial UI",
            category: .work,
            identifier: "PRJ-VAN-01",
            colorHex: "#0A84FF",
            iconName: "visionpro"
        )
        context.insert(visionProject)
        
        // Seed Sample Academic Tasks
        let task1 = Task(
            title: "Implement Raft Consensus Algorithm",
            description: "Complete leader election and log replication test suites for Milestone 2.",
            category: .academic,
            courseProject: csCourse,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            hasSpecificTime: true,
            priority: .high,
            estimatedCompletionTime: 7200, // 2 hours
            status: .inProgress
        )
        
        let task2 = Task(
            title: "Review Paper: DynamoDB Architecture",
            description: "Read Amazon Dynamo paper and summarize key partition strategies.",
            category: .academic,
            courseProject: csCourse,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            hasSpecificTime: false,
            priority: .medium,
            estimatedCompletionTime: 3600, // 1 hour
            status: .toDo
        )
        
        // Seed Sample Work Tasks
        let task3 = Task(
            title: "Refactor Spatial Ornament Toolbars",
            description: "Align glassmorphic ornament layout with visionOS human interface guidelines.",
            category: .work,
            courseProject: visionProject,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            hasSpecificTime: true,
            priority: .high,
            estimatedCompletionTime: 5400, // 1.5 hours
            status: .toDo
        )
        
        let task4 = Task(
            title: "Set up SwiftData ModelContainer",
            description: "Implement unified Task, CourseProject, ScheduleEvent, and ApplicationSettings.",
            category: .work,
            courseProject: visionProject,
            dueDate: Date(),
            hasSpecificTime: true,
            priority: .high,
            estimatedCompletionTime: 2700,
            status: .completed,
            completedAt: Date()
        )
        
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        context.insert(task4)
        
        // Seed Schedule Events
        let lectureEvent = ScheduleEvent(
            title: "CS-450 Advanced Lecture",
            category: .academic,
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date()) ?? Date(),
            courseProject: csCourse,
            location: "Hall 4B / Spatial Stream",
            notes: "Discussion on vector clocks and eventual consistency."
        )
        
        let standupEvent = ScheduleEvent(
            title: "Vantage Sprint Sync",
            category: .work,
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 14, minute: 45, second: 0, of: Date()) ?? Date(),
            courseProject: visionProject,
            location: "FaceTime Spatial Persona",
            notes: "Review progress on visionOS planner window groups."
        )
        
        context.insert(lectureEvent)
        context.insert(standupEvent)
        
        try? context.save()
        return container
    }()
}
