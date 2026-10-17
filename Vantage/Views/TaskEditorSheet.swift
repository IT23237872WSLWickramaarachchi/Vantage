//
//  TaskEditorSheet.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Modal sheet form to create and edit tasks.
/// Automatically preselects the domain category (Academic or Work) when opened from contextual views.
public struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    /// Optional existing task to edit. If nil, the sheet operates in Create mode.
    public let taskToEdit: Task?
    
    /// Fallback initial category for new tasks.
    public let initialCategory: PlannerCategory
    
    @Query(sort: \CourseProject.name) private var allProjects: [CourseProject]
    
    // MARK: - Form State
    @State private var title: String
    @State private var taskDescription: String
    @State private var category: PlannerCategory
    @State private var selectedProject: CourseProject?
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasSpecificTime: Bool
    @State private var priority: Priority
    @State private var estimatedMinutes: Int
    @State private var status: TaskStatus
    @State private var showCreateProjectSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    // Effort presets in minutes
    private let effortPresets: [Int] = [15, 30, 45, 60, 90, 120, 180]
    
    public init(taskToEdit: Task? = nil, initialCategory: PlannerCategory = .academic) {
        self.taskToEdit = taskToEdit
        self.initialCategory = initialCategory
        
        if let task = taskToEdit {
            _title = State(initialValue: task.title)
            _taskDescription = State(initialValue: task.taskDescription)
            _category = State(initialValue: task.category)
            _selectedProject = State(initialValue: task.courseProject)
            _hasDueDate = State(initialValue: task.dueDate != nil)
            _dueDate = State(initialValue: task.dueDate ?? Date())
            _hasSpecificTime = State(initialValue: task.hasSpecificTime)
            _priority = State(initialValue: task.priority)
            _estimatedMinutes = State(initialValue: task.estimatedCompletionMinutes)
            _status = State(initialValue: task.status)
        } else {
            _title = State(initialValue: "")
            _taskDescription = State(initialValue: "")
            _category = State(initialValue: initialCategory)
            _selectedProject = State(initialValue: nil)
            _hasDueDate = State(initialValue: true)
            _dueDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
            _hasSpecificTime = State(initialValue: false)
            _priority = State(initialValue: .medium)
            _estimatedMinutes = State(initialValue: 30)
            _status = State(initialValue: .toDo)
        }
    }
    
    private var relevantProjects: [CourseProject] {
        allProjects.filter { $0.category == category }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var activeAccent: Color {
        category == .academic ? Color.academicAccent : Color.workAccent
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Title & Domain Category
                Section {
                    TextField("Task Title (e.g., Problem Set 4, API Migration)", text: $title)
                        .font(.headline)
                    
                    Picker("Domain Category", selection: $category) {
                        ForEach(PlannerCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(activeAccent)
                    .onChange(of: category) { _, newCat in
                        // Reset course/project if it doesn't match the new category
                        if let currentProj = selectedProject, currentProj.category != newCat {
                            selectedProject = nil
                        }
                    }
                } header: {
                    Text("General")
                }
                
                // Section 2: Course / Project Selector
                Section {
                    Picker(category == .academic ? "Associated Course" : "Associated Project", selection: $selectedProject) {
                        Text("None").tag(nil as CourseProject?)
                        ForEach(relevantProjects) { project in
                            HStack {
                                Text(project.identifier)
                                    .fontWeight(.bold)
                                Text("•")
                                Text(project.name)
                            }
                            .tag(project as CourseProject?)
                        }
                    }
                } header: {
                    HStack {
                        Text(category == .academic ? "Academic Affiliation" : "Project Association")
                        Spacer()
                        Button {
                            showCreateProjectSheet = true
                        } label: {
                            Text(category == .academic ? "+ New Course" : "+ New Project")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(activeAccent)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    if relevantProjects.isEmpty {
                        Text("No \(category.title.lowercased()) courses/projects found. You can associate tasks without one or create one above.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Section 3: Status & Priority
                Section {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases) { item in
                            Label(item.title, systemImage: item.iconName)
                                .tag(item)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { item in
                            HStack {
                                Image(systemName: item.iconName)
                                Text(item.title)
                            }
                            .tag(item)
                        }
                    }
                } header: {
                    Text("Progression & Urgency")
                }
                
                // Section 4: Due Date (with optional time toggle)
                Section {
                    Toggle("Enable Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        Toggle("Include Specific Time", isOn: $hasSpecificTime)
                        
                        DatePicker(
                            "Deadline",
                            selection: $dueDate,
                            displayedComponents: hasSpecificTime ? [.date, .hourAndMinute] : [.date]
                        )
                        .tint(activeAccent)
                    }
                } header: {
                    Text("Deadline & Timing")
                }
                
                // Section 5: Estimated Effort
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Estimated Duration")
                            Spacer()
                            Text(formatDuration(minutes: estimatedMinutes))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(activeAccent)
                        }
                        
                        // Preset duration chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(effortPresets, id: \.self) { mins in
                                    Button {
                                        estimatedMinutes = mins
                                    } label: {
                                        Text(formatDuration(minutes: mins))
                                            .font(.caption.weight(estimatedMinutes == mins ? .bold : .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(estimatedMinutes == mins ? activeAccent.opacity(0.25) : Color.white.opacity(0.06))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(estimatedMinutes == mins ? activeAccent : Color.white.opacity(0.12), lineWidth: 1)
                                                    )
                                            )
                                            .foregroundStyle(estimatedMinutes == mins ? activeAccent : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Stepper("Custom Stepper (±15 min)", value: $estimatedMinutes, in: 5...720, step: 15)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Workload Estimation")
                }
                
                // Section 6: In-Depth Description
                Section {
                    TextEditor(text: $taskDescription)
                        .frame(minHeight: 90)
                } header: {
                    Text("Description & Notes")
                }
                
                // Section 7: Destructive Action (If Editing)
                if taskToEdit != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Task", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .confirmationDialog("Delete Task?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let existing = taskToEdit {
                        modelContext.delete(existing)
                        try? modelContext.save()
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
            .navigationTitle(taskToEdit == nil ? (category == .academic ? "New Assignment" : "New Work Task") : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(taskToEdit == nil ? "Create" : "Save") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.bold)
                    .tint(activeAccent)
                }
            }
        }
        .frame(minWidth: 540, idealWidth: 600, minHeight: 640, idealHeight: 720)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCreateProjectSheet) {
            ProjectEditorSheet(initialCategory: category) { newProject in
                selectedProject = newProject
            }
        }
    }
    
    // MARK: - Save Logic
    private func saveTask() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedDueDate: Date? = hasDueDate ? dueDate : nil
        let durationSeconds = TimeInterval(estimatedMinutes * 60)
        
        if let existing = taskToEdit {
            existing.title = cleanTitle
            existing.taskDescription = taskDescription
            existing.category = category
            existing.courseProject = selectedProject
            existing.dueDate = resolvedDueDate
            existing.hasSpecificTime = hasSpecificTime
            existing.priority = priority
            existing.estimatedCompletionTime = durationSeconds
            existing.status = status
            if status == .completed && existing.completedAt == nil {
                existing.completedAt = Date()
            } else if status != .completed {
                existing.completedAt = nil
            }
        } else {
            let newTask = Task(
                title: cleanTitle,
                description: taskDescription,
                category: category,
                courseProject: selectedProject,
                dueDate: resolvedDueDate,
                hasSpecificTime: hasSpecificTime,
                priority: priority,
                estimatedCompletionTime: durationSeconds,
                status: status,
                completedAt: status == .completed ? Date() : nil
            )
            modelContext.insert(newTask)
        }
        
        try? modelContext.save()
    }
    
    private func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 {
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
