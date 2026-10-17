//
//  VantageApp.swift
//  Vantage
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI
import SwiftData

@main
struct VantageApp: App {

    @State private var appModel = AppModel()

    // MARK: - SwiftData Model Container Initialization
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
            CourseProject.self,
            ScheduleEvent.self,
            ApplicationSettings.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer for Vantage: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        // MARK: - Window Presentation 1: Main Window (Features NavigationSplitView Sidebar)
        WindowGroup(id: VantageWindowID.main) {
            MainNavigationView()
                .environment(appModel)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1200, height: 800)

        // MARK: - Window Presentation 2: Standalone Calendar Window (Without Sidebar)
        WindowGroup(id: VantageWindowID.standaloneCalendar) {
            StandaloneCalendarView()
                .environment(appModel)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 980, height: 720)

        // MARK: - Window Presentation 3: Task Details Utility Window
        WindowGroup(id: VantageWindowID.taskDetail, for: UUID.self) { $taskId in
            TaskDetailUtilityView(taskId: taskId)
                .environment(appModel)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 560, height: 680)
        .windowResizability(.contentSize)

        // MARK: - visionOS Immersive Space (Focus Mode)
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
