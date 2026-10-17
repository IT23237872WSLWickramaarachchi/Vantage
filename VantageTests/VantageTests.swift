//
//  VantageTests.swift
//  VantageTests
//
//  Created by IM Student on 2026-10-17.
//

import XCTest
import SwiftUI
import SwiftData
@testable import Vantage

final class VantageTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    @MainActor
    override func setUpWithError() throws {
        let schema = Schema([
            Task.self,
            CourseProject.self,
            ScheduleEvent.self,
            ApplicationSettings.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Task Model & Unified Architecture Tests
    @MainActor
    func testUnifiedTaskModelForAcademicAndWork() throws {
        // Academic Course & Task
        let academicCourse = CourseProject(
            name: "Algorithms",
            category: .academic,
            identifier: "CS-301"
        )
        modelContext.insert(academicCourse)

        let academicTask = Task(
            title: "Problem Set 4",
            description: "Dynamic programming and greedy algorithms.",
            category: .academic,
            courseProject: academicCourse,
            dueDate: Date().addingTimeInterval(86400),
            hasSpecificTime: true,
            priority: .high,
            estimatedCompletionTime: 7200,
            status: .inProgress
        )
        modelContext.insert(academicTask)

        // Work Project & Task
        let workProject = CourseProject(
            name: "Spatial Architecture",
            category: .work,
            identifier: "PRJ-VAN-01"
        )
        modelContext.insert(workProject)

        let workTask = Task(
            title: "ModelContainer Review",
            description: "Validate schema relationships and configuration.",
            category: .work,
            courseProject: workProject,
            dueDate: Date().addingTimeInterval(172800),
            hasSpecificTime: false,
            priority: .medium,
            estimatedCompletionTime: 3600,
            status: .toDo
        )
        modelContext.insert(workTask)

        try modelContext.save()

        // Fetch all tasks using unified Task model
        let descriptor = FetchDescriptor<Task>()
        let fetchedTasks = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedTasks.count, 2)
        XCTAssertTrue(fetchedTasks.contains(where: { $0.category == .academic && $0.title == "Problem Set 4" }))
        XCTAssertTrue(fetchedTasks.contains(where: { $0.category == .work && $0.title == "ModelContainer Review" }))
        
        // Validate attributes
        XCTAssertEqual(academicTask.priority, .high)
        XCTAssertEqual(academicTask.estimatedCompletionMinutes, 120)
        XCTAssertEqual(academicTask.courseProject?.identifier, "CS-301")
        XCTAssertTrue(academicTask.hasSpecificTime)
        
        XCTAssertEqual(workTask.priority, .medium)
        XCTAssertEqual(workTask.estimatedCompletionMinutes, 60)
        XCTAssertEqual(workTask.courseProject?.identifier, "PRJ-VAN-01")
        XCTAssertFalse(workTask.hasSpecificTime)
    }

    // MARK: - CourseProject & Relationships Test
    @MainActor
    func testCourseProjectRelationships() throws {
        let course = CourseProject(
            name: "Neural Networks",
            category: .academic,
            identifier: "AI-502"
        )
        modelContext.insert(course)

        let task = Task(
            title: "Backpropagation Lab",
            description: "Implement autograd from scratch.",
            category: .academic,
            courseProject: course
        )
        modelContext.insert(task)

        let event = ScheduleEvent(
            title: "AI-502 Lab Session",
            category: .academic,
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(5400),
            courseProject: course
        )
        modelContext.insert(event)

        try modelContext.save()

        XCTAssertEqual(course.tasks?.count, 1)
        XCTAssertEqual(course.scheduleEvents?.count, 1)
        XCTAssertEqual(course.tasks?.first?.title, "Backpropagation Lab")
        XCTAssertEqual(course.scheduleEvents?.first?.title, "AI-502 Lab Session")
    }

    // MARK: - Schedule Event Test
    @MainActor
    func testScheduleEventCreation() throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hr

        let event = ScheduleEvent(
            title: "Product Standup",
            category: .work,
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            location: "Spatial Window 2"
        )
        modelContext.insert(event)
        try modelContext.save()

        let fetched = try modelContext.fetch(FetchDescriptor<ScheduleEvent>()).first
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Product Standup")
        XCTAssertEqual(fetched?.category, .work)
        XCTAssertEqual(fetched?.duration, 3600)
        XCTAssertNil(fetched?.courseProject) // Optional association
    }

    // MARK: - Application Settings Test
    @MainActor
    func testApplicationSettingsPreferencesAndThresholds() throws {
        let settings = ApplicationSettings.fetchOrCreate(in: modelContext)
        
        // Check Appearance Preferences
        XCTAssertEqual(settings.appearanceTheme, "System")
        XCTAssertTrue(settings.enableGlassmorphicGlow)
        
        // Check Calendar Preferences
        XCTAssertEqual(settings.firstDayOfWeek, 1)
        XCTAssertEqual(settings.defaultEventDurationMinutes, 60)
        
        // Check Workload Thresholds
        XCTAssertEqual(settings.maxDailyAcademicHours, 6.0)
        XCTAssertEqual(settings.maxDailyWorkHours, 8.0)
        XCTAssertEqual(settings.maxConcurrentActiveTasks, 5)
        XCTAssertTrue(settings.enableBurnoutAlerts)

        // Modify settings and ensure singleton fetch maintains changes
        settings.maxDailyStudyHoursOrAcademic = 7.5
        try modelContext.save()

        let fetchedAgain = ApplicationSettings.fetchOrCreate(in: modelContext)
        XCTAssertEqual(fetchedAgain.maxDailyAcademicHours, 7.5)
    }

    // MARK: - Navigation & Multi-Window Architecture Tests
    func testSixSidebarDestinations() {
        let destinations = NavigationDestination.allCases
        XCTAssertEqual(destinations.count, 6, "Sidebar must feature exactly six destinations")
        
        let expectedTitles = ["Overview", "Academic", "Work", "Calendar", "Insights", "Settings"]
        XCTAssertEqual(destinations.map(\.rawValue), expectedTitles)
    }

    func testWindowIdentifiers() {
        XCTAssertEqual(VantageWindowID.main, "vantage.main")
        XCTAssertEqual(VantageWindowID.standaloneCalendar, "vantage.calendar.standalone")
        XCTAssertEqual(VantageWindowID.taskDetail, "vantage.task.detail")
    }

    func testThemeHexColorTokens() {
        let academicHex = Color(hex: "#7779C9")
        let workHex = Color(hex: "#2A9D98")
        let coralConflictHex = Color(hex: "#E46B72")
        
        XCTAssertNotNil(academicHex)
        XCTAssertNotNil(workHex)
        XCTAssertNotNil(coralConflictHex)
        XCTAssertEqual(VantageTheme.conflictWarning, Color.conflictWarning)
    }

    // MARK: - Calendar Conflict Detection Tests
    @MainActor
    func testScheduleEventConflictDetection() throws {
        let baseDate = Calendar.current.startOfDay(for: Date())
        
        // Event 1: 10:00 AM - 11:30 AM
        let event1 = ScheduleEvent(
            title: "Lecture 1",
            category: .academic,
            date: baseDate,
            startTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: baseDate)!,
            endTime: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: baseDate)!
        )
        
        // Event 2 (Overlapping): 11:00 AM - 12:00 PM
        let event2 = ScheduleEvent(
            title: "Sprint Sync",
            category: .work,
            date: baseDate,
            startTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: baseDate)!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!
        )
        
        // Event 3 (Non-overlapping): 2:00 PM - 3:00 PM
        let event3 = ScheduleEvent(
            title: "Office Hours",
            category: .academic,
            date: baseDate,
            startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: baseDate)!,
            endTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: baseDate)!
        )
        
        // Event 4 (All-Day, should not conflict):
        let event4 = ScheduleEvent(
            title: "Conference Day",
            category: .work,
            date: baseDate,
            startTime: baseDate,
            endTime: baseDate.addingTimeInterval(86400),
            isAllDay: true
        )
        
        // Helper conflict detector
        func detectConflicts(among events: [ScheduleEvent]) -> [(ScheduleEvent, ScheduleEvent)] {
            let fixed = events.filter { !$0.isAllDay }
            guard fixed.count > 1 else { return [] }
            var conflicts: [(ScheduleEvent, ScheduleEvent)] = []
            for i in 0..<fixed.count {
                for j in (i + 1)..<fixed.count {
                    if fixed[i].startTime < fixed[j].endTime && fixed[j].startTime < fixed[i].endTime {
                        conflicts.append((fixed[i], fixed[j]))
                    }
                }
            }
            return conflicts
        }
        
        let conflicts = detectConflicts(among: [event1, event2, event3, event4])
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.0.title, "Lecture 1")
        XCTAssertEqual(conflicts.first?.1.title, "Sprint Sync")
    }

    // MARK: - Insights Workload Calculation Tests
    @MainActor
    func testRemainingWorkloadCalculationExcludesCompletedTasks() throws {
        // Active Academic Task (2 hours)
        let academicActive = Task(
            title: "Active Academic",
            category: .academic,
            estimatedCompletionTime: 7200,
            status: .inProgress
        )
        // Completed Academic Task (3 hours, MUST NOT be in remaining workload)
        let academicCompleted = Task(
            title: "Completed Academic",
            category: .academic,
            estimatedCompletionTime: 10800,
            status: .completed
        )
        // Active Work Task (1 hour)
        let workActive = Task(
            title: "Active Work",
            category: .work,
            estimatedCompletionTime: 3600,
            status: .toDo
        )
        // Completed Work Task (4 hours, MUST NOT be in remaining workload)
        let workCompleted = Task(
            title: "Completed Work",
            category: .work,
            estimatedCompletionTime: 14400,
            status: .completed
        )
        
        modelContext.insert(academicActive)
        modelContext.insert(academicCompleted)
        modelContext.insert(workActive)
        modelContext.insert(workCompleted)
        try modelContext.save()
        
        let allTasks = try modelContext.fetch(FetchDescriptor<Task>())
        
        // Remaining effort calculation excludes completed tasks
        let openTasks = allTasks.filter { $0.status != .completed }
        let remainingAcademicHours = openTasks
            .filter { $0.category == .academic }
            .reduce(0.0) { $0 + $1.estimatedCompletionTime } / 3600.0
            
        let remainingWorkHours = openTasks
            .filter { $0.category == .work }
            .reduce(0.0) { $0 + $1.estimatedCompletionTime } / 3600.0
            
        XCTAssertEqual(remainingAcademicHours, 2.0, "Remaining academic workload must be 2.0h, excluding completed tasks")
        XCTAssertEqual(remainingWorkHours, 1.0, "Remaining work workload must be 1.0h, excluding completed tasks")
    }

    // MARK: - Comprehensive CRUD Operations Tests

    @MainActor
    func testCourseProjectCRUD() throws {
        // 1. CREATE
        let course = CourseProject(name: "Data Structures", category: .academic, identifier: "CS-201")
        modelContext.insert(course)
        try modelContext.save()

        // 2. READ
        var fetchedCourses = try modelContext.fetch(FetchDescriptor<CourseProject>())
        XCTAssertEqual(fetchedCourses.count, 1)
        XCTAssertEqual(fetchedCourses.first?.name, "Data Structures")
        XCTAssertEqual(fetchedCourses.first?.identifier, "CS-201")

        // 3. UPDATE
        course.name = "Advanced Data Structures & Algorithms"
        course.identifier = "CS-201-ADV"
        try modelContext.save()

        fetchedCourses = try modelContext.fetch(FetchDescriptor<CourseProject>())
        XCTAssertEqual(fetchedCourses.first?.name, "Advanced Data Structures & Algorithms")
        XCTAssertEqual(fetchedCourses.first?.identifier, "CS-201-ADV")

        // 4. DELETE
        modelContext.delete(course)
        try modelContext.save()

        fetchedCourses = try modelContext.fetch(FetchDescriptor<CourseProject>())
        XCTAssertTrue(fetchedCourses.isEmpty)
    }

    @MainActor
    func testScheduleEventCRUD() throws {
        let testDate = Date()
        let startTime = testDate
        let endTime = testDate.addingTimeInterval(3600)

        // 1. CREATE
        let event = ScheduleEvent(
            title: "Operating Systems Lecture",
            category: .academic,
            date: testDate,
            startTime: startTime,
            endTime: endTime,
            location: "Hall B"
        )
        modelContext.insert(event)
        try modelContext.save()

        // 2. READ
        var fetchedEvents = try modelContext.fetch(FetchDescriptor<ScheduleEvent>())
        XCTAssertEqual(fetchedEvents.count, 1)
        XCTAssertEqual(fetchedEvents.first?.title, "Operating Systems Lecture")
        XCTAssertEqual(fetchedEvents.first?.location, "Hall B")

        // 3. UPDATE
        event.title = "Operating Systems Lab"
        event.location = "Computer Lab 4"
        event.endTime = testDate.addingTimeInterval(7200)
        try modelContext.save()

        fetchedEvents = try modelContext.fetch(FetchDescriptor<ScheduleEvent>())
        XCTAssertEqual(fetchedEvents.first?.title, "Operating Systems Lab")
        XCTAssertEqual(fetchedEvents.first?.location, "Computer Lab 4")

        // 4. DELETE
        modelContext.delete(event)
        try modelContext.save()

        fetchedEvents = try modelContext.fetch(FetchDescriptor<ScheduleEvent>())
        XCTAssertTrue(fetchedEvents.isEmpty)
    }

    @MainActor
    func testTaskCRUD() throws {
        // 1. CREATE
        let task = Task(
            title: "Implement Auth Flow",
            description: "Setup OAuth and PKCE",
            category: .work,
            priority: .medium,
            estimatedCompletionTime: 3600,
            status: .toDo
        )
        modelContext.insert(task)
        try modelContext.save()

        // 2. READ
        var fetchedTasks = try modelContext.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(fetchedTasks.count, 1)
        XCTAssertEqual(fetchedTasks.first?.title, "Implement Auth Flow")
        XCTAssertEqual(fetchedTasks.first?.status, .toDo)

        // 3. UPDATE
        task.title = "Implement Auth Flow & MFA"
        task.status = .inProgress
        task.priority = .high
        task.estimatedCompletionTime = 5400
        try modelContext.save()

        fetchedTasks = try modelContext.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(fetchedTasks.first?.title, "Implement Auth Flow & MFA")
        XCTAssertEqual(fetchedTasks.first?.status, .inProgress)
        XCTAssertEqual(fetchedTasks.first?.priority, .high)
        XCTAssertEqual(fetchedTasks.first?.estimatedCompletionMinutes, 90)

        // 4. DELETE
        modelContext.delete(task)
        try modelContext.save()

        fetchedTasks = try modelContext.fetch(FetchDescriptor<Task>())
        XCTAssertTrue(fetchedTasks.isEmpty)
    }

    @MainActor
    func testApplicationSettingsCRUDAndReset() throws {
        // 1. CREATE / READ
        let settings = ApplicationSettings.fetchOrCreate(in: modelContext)
        XCTAssertNotNil(settings)

        // 2. UPDATE
        settings.appearanceTheme = "Light"
        settings.firstDayOfWeek = 2 // Monday
        settings.defaultEventDurationMinutes = 90
        settings.showCompletedTasksInCalendar = true
        settings.maxDailyAcademicHours = 7.5
        settings.maxDailyWorkHours = 9.0
        settings.enableBurnoutAlerts = false
        try modelContext.save()

        // Verify update persisted
        let fetchedSettings = try modelContext.fetch(FetchDescriptor<ApplicationSettings>()).first!
        XCTAssertEqual(fetchedSettings.appearanceTheme, "Light")
        XCTAssertEqual(fetchedSettings.firstDayOfWeek, 2)
        XCTAssertEqual(fetchedSettings.defaultEventDurationMinutes, 90)
        XCTAssertTrue(fetchedSettings.showCompletedTasksInCalendar)
        XCTAssertEqual(fetchedSettings.maxDailyAcademicHours, 7.5)
        XCTAssertEqual(fetchedSettings.maxDailyWorkHours, 9.0)
        XCTAssertFalse(fetchedSettings.enableBurnoutAlerts)

        // 3. RESET TO FACTORY DEFAULTS
        fetchedSettings.appearanceTheme = "Dark"
        fetchedSettings.firstDayOfWeek = 1
        fetchedSettings.defaultEventDurationMinutes = 60
        fetchedSettings.showCompletedTasksInCalendar = false
        fetchedSettings.maxDailyAcademicHours = 6.0
        fetchedSettings.maxDailyWorkHours = 8.0
        fetchedSettings.enableBurnoutAlerts = true
        try modelContext.save()

        let resetSettings = try modelContext.fetch(FetchDescriptor<ApplicationSettings>()).first!
        XCTAssertEqual(resetSettings.appearanceTheme, "Dark")
        XCTAssertEqual(resetSettings.firstDayOfWeek, 1)
        XCTAssertEqual(resetSettings.defaultEventDurationMinutes, 60)
        XCTAssertFalse(resetSettings.showCompletedTasksInCalendar)
        XCTAssertEqual(resetSettings.maxDailyAcademicHours, 6.0)
        XCTAssertEqual(resetSettings.maxDailyWorkHours, 8.0)
        XCTAssertTrue(resetSettings.enableBurnoutAlerts)
    }

    @MainActor
    func testShowCompletedTasksInCalendarFilter() throws {
        let calendar = Calendar.current
        let today = Date()

        let openTask = Task(title: "Open Deliverable", category: .work, dueDate: today, status: .inProgress)
        let completedTask = Task(title: "Completed Deliverable", category: .work, dueDate: today, status: .completed)

        modelContext.insert(openTask)
        modelContext.insert(completedTask)
        try modelContext.save()

        let allTasks = try modelContext.fetch(FetchDescriptor<Task>())

        // When showCompletedTasksInCalendar is false
        let filteredWhenHidden = allTasks.filter { task in
            guard let due = task.dueDate, calendar.isDate(due, inSameDayAs: today) else { return false }
            let showCompleted = false
            if !showCompleted && task.status == .completed { return false }
            return true
        }
        XCTAssertEqual(filteredWhenHidden.count, 1)
        XCTAssertEqual(filteredWhenHidden.first?.title, "Open Deliverable")

        // When showCompletedTasksInCalendar is true
        let filteredWhenShown = allTasks.filter { task in
            guard let due = task.dueDate, calendar.isDate(due, inSameDayAs: today) else { return false }
            let showCompleted = true
            if !showCompleted && task.status == .completed { return false }
            return true
        }
        XCTAssertEqual(filteredWhenShown.count, 2)
    }
}

// Convenience helper for test readability
extension ApplicationSettings {
    var maxDailyStudyHoursOrAcademic: Double {
        get { maxDailyAcademicHours }
        set { maxDailyAcademicHours = newValue }
    }
}
