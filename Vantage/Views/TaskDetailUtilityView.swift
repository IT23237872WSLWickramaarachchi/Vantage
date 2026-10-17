//
//  TaskDetailUtilityView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Utility Inspector Window Presentation for inspecting and editing an individual Task.
/// Opens via `openWindow(id: VantageWindowID.taskDetail, value: task.id)`.
public struct TaskDetailUtilityView: View {
    public let taskId: UUID?
    
    @Query private var allTasks: [Task]
    @Query(sort: \CourseProject.name) private var allProjects: [CourseProject]
    @Query private var settingsList: [ApplicationSettings]
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.modelContext) private var modelContext
    
    public init(taskId: UUID?) {
        self.taskId = taskId
    }
    
    private var task: Task? {
        guard let taskId else { return nil }
        return allTasks.first(where: { $0.id == taskId })
    }
    
    public var body: some View {
        Group {
            if let task {
                TaskDetailContent(task: task, projects: allProjects)
            } else {
                emptyStateView
            }
        }
        .frame(minWidth: 460, idealWidth: 540, minHeight: 580, idealHeight: 660)
        .preferredColorScheme(settingsList.first?.appearanceTheme == "Light" ? .light : (settingsList.first?.appearanceTheme == "System" ? nil : .dark))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.folder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Task Not Found")
                .font(.title2.weight(.bold))
            Text("The requested task may have been removed or no ID was provided.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Dismiss Window") {
                dismissWindow()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(32)
    }
}

// MARK: - Task Detail Editor Content
private struct TaskDetailContent: View {
    @Bindable var task: Task
    let projects: [CourseProject]
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.modelContext) private var modelContext
    
    private var relevantProjects: [CourseProject] {
        projects.filter { $0.category == task.category }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Title and Category
                Section {
                    TextField("Task Title", text: $task.title)
                        .font(.headline)
                    
                    Picker("Domain Category", selection: $task.category) {
                        ForEach(PlannerCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.title)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(task.category.accentColor)
                } header: {
                    Text("General")
                }
                
                // Section 2: Status & Priority
                Section {
                    Picker("Status", selection: $task.status) {
                        ForEach(TaskStatus.allCases) { status in
                            Label(status.title, systemImage: status.iconName).tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: $task.priority) {
                        ForEach(Priority.allCases) { priority in
                            Label(priority.title, systemImage: priority.iconName).tag(priority)
                        }
                    }
                    
                    // Associated Course / Project
                    Picker(task.category == .academic ? "Course" : "Project", selection: $task.courseProject) {
                        Text("None").tag(nil as CourseProject?)
                        ForEach(relevantProjects) { project in
                            Text("\(project.identifier) - \(project.name)").tag(project as CourseProject?)
                        }
                    }
                } header: {
                    Text("Classification")
                }
                
                // Section 3: Scheduling & Due Date
                Section {
                    Toggle("Set Due Date", isOn: Binding(
                        get: { task.dueDate != nil },
                        set: { enabled in
                            if enabled {
                                task.dueDate = Date()
                            } else {
                                task.dueDate = nil
                                task.hasSpecificTime = false
                            }
                        }
                    ))
                    
                    if task.dueDate != nil {
                        Toggle("Include Specific Time", isOn: $task.hasSpecificTime)
                        
                        DatePicker(
                            "Deadline",
                            selection: Binding(
                                get: { task.dueDate ?? Date() },
                                set: { task.dueDate = $0 }
                            ),
                            displayedComponents: task.hasSpecificTime ? [.date, .hourAndMinute] : [.date]
                        )
                    }
                    
                    // Estimated Completion Duration
                    Stepper(value: $task.estimatedCompletionMinutes, in: 5...720, step: 15) {
                        HStack {
                            Text("Estimated Duration")
                            Spacer()
                            Text(task.formattedDuration)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Timeline & Effort")
                }
                
                // Section 4: In-depth Description
                Section {
                    TextEditor(text: $task.taskDescription)
                        .frame(minHeight: 100)
                } header: {
                    Text("Notes & Details")
                }
                
                // Section 5: Destruction
                Section {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        try? modelContext.save()
                        dismissWindow()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Task", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        try? modelContext.save()
                        dismissWindow()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        dismissWindow()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
