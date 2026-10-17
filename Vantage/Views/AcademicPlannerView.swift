//
//  AcademicPlannerView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Academic Planner View themed with Indigo (#7779C9).
/// Features course summary cards at the top showing open and completed task counts,
/// and a task list filterable by selected course and completion status.
public struct AcademicPlannerView: View {
    @Query(sort: \Task.dueDate) private var allTasks: [Task]
    @Query(sort: \CourseProject.name) private var allProjects: [CourseProject]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    // Filtering State
    @State private var selectedCourseID: UUID? = nil // nil means "All Courses"
    @State private var completionFilter: AcademicCompletionFilter = .all
    
    // Sheet State
    @State private var showCreateTaskSheet: Bool = false
    @State private var showCreateCourseSheet: Bool = false
    @State private var taskToEdit: Task? = nil
    @State private var courseToEdit: CourseProject? = nil
    
    public init() {}
    
    private var academicCourses: [CourseProject] {
        allProjects.filter { $0.category == .academic }
    }
    
    private var allAcademicTasks: [Task] {
        allTasks.filter { $0.category == .academic }
    }
    
    /// Filtered tasks based on selected course and completion status
    private var filteredTasks: [Task] {
        allAcademicTasks.filter { task in
            // Filter by Course
            if let selectedCourseID {
                guard task.courseProject?.id == selectedCourseID else { return false }
            }
            
            // Filter by Completion Status
            switch completionFilter {
            case .all:
                return true
            case .open:
                return task.status != .completed
            case .completed:
                return task.status == .completed
            }
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Banner
                headerSection
                
                // 1. Course Summary Cards (Showing Open & Completed Counts)
                courseSummaryCardsSection
                
                // 2. Filter Bar & Task List
                taskListHeaderAndFilters
                
                // Tasks List
                if filteredTasks.isEmpty {
                    emptyTasksView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskCardRow(task: task) {
                                taskToEdit = task
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .navigationTitle("Academic")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateTaskSheet = true
                } label: {
                    Label("New Assignment", systemImage: "plus")
                }
                .tint(Color.academicAccent)
            }
        }
        // Task Creation Sheet with Academic Preselected
        .sheet(isPresented: $showCreateTaskSheet) {
            TaskEditorSheet(taskToEdit: nil, initialCategory: .academic)
        }
        // Task Editing Sheet
        .sheet(item: $taskToEdit) { task in
            TaskEditorSheet(taskToEdit: task, initialCategory: .academic)
        }
        // Course Creation Sheet
        .sheet(isPresented: $showCreateCourseSheet) {
            ProjectEditorSheet(initialCategory: .academic)
        }
        // Course Editing Sheet
        .sheet(item: $courseToEdit) { course in
            ProjectEditorSheet(projectToEdit: course, initialCategory: .academic)
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(Color.academicAccent)
                    Text("Academic Studies")
                        .font(.system(.title, design: .rounded, weight: .bold))
                }
                Text("Coursework assignments, exam schedules, and research milestones.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            Button {
                showCreateTaskSheet = true
            } label: {
                Label("Add Assignment", systemImage: "plus.circle.fill")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.academicAccent)
        }
    }
    
    // MARK: - Course Summary Cards
    private var courseSummaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Course Summaries")
                    .font(.title3.weight(.bold))
                Spacer()
                
                Button {
                    showCreateCourseSheet = true
                } label: {
                    Label("Add Course", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Color.academicAccent)
                
                if selectedCourseID != nil {
                    Button("Show All") {
                        withAnimation { selectedCourseID = nil }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.academicAccent)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // "All Courses" Aggregate Card
                    allCoursesSummaryCard
                    
                    // Individual Course Cards
                    ForEach(academicCourses) { course in
                        individualCourseCard(course: course)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private var allCoursesSummaryCard: some View {
        let isSelected = selectedCourseID == nil
        let openCount = allAcademicTasks.filter { $0.status != .completed }.count
        let completedCount = allAcademicTasks.filter { $0.status == .completed }.count
        
        return Button {
            withAnimation { selectedCourseID = nil }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ALL")
                        .font(.caption.weight(.black))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.academicAccent.opacity(isSelected ? 0.35 : 0.2))
                        .foregroundStyle(Color.academicAccent)
                        .cornerRadius(6)
                    Spacer()
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.caption)
                        .foregroundStyle(Color.academicAccent)
                }
                
                Text("All Courses")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Open & Completed Task Counts
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(openCount)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.academicAccent)
                        Text("Open")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider().frame(height: 24).overlay(.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(completedCount)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Completed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 190)
            .padding(14)
            .vantageGlassCard(borderColor: isSelected ? Color.academicAccent : Color.white.opacity(0.12))
        }
        .buttonStyle(.plain)
    }
    
    private func individualCourseCard(course: CourseProject) -> some View {
        let isSelected = selectedCourseID == course.id
        let courseTasks = allAcademicTasks.filter { $0.courseProject?.id == course.id }
        let openCount = courseTasks.filter { $0.status != .completed }.count
        let completedCount = courseTasks.filter { $0.status == .completed }.count
        
        return Button {
            withAnimation {
                if selectedCourseID == course.id {
                    selectedCourseID = nil // Toggle off if already selected
                } else {
                    selectedCourseID = course.id
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(course.identifier)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.academicAccent.opacity(isSelected ? 0.35 : 0.2))
                        .foregroundStyle(Color.academicAccent)
                        .cornerRadius(6)
                    Spacer()
                    Image(systemName: course.iconName)
                        .font(.caption)
                        .foregroundStyle(Color.academicAccent)
                }
                
                Text(course.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Open & Completed Task Counts
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(openCount)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.academicAccent)
                        Text("Open")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider().frame(height: 24).overlay(.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(completedCount)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Completed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 210)
            .padding(14)
            .vantageGlassCard(borderColor: isSelected ? Color.academicAccent : Color.academicAccent.opacity(0.25))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                courseToEdit = course
            } label: {
                Label("Edit Course", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                if selectedCourseID == course.id {
                    selectedCourseID = nil
                }
                modelContext.delete(course)
                try? modelContext.save()
            } label: {
                Label("Delete Course", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Task List Header & Filters
    private var taskListHeaderAndFilters: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Assignments & Coursework")
                    .font(.title2.weight(.bold))
                if let selectedCourseID, let course = academicCourses.first(where: { $0.id == selectedCourseID }) {
                    Text("Filtered by: \(course.identifier) - \(course.name)")
                        .font(.caption)
                        .foregroundStyle(Color.academicAccent)
                }
            }
            
            Spacer()
            
            // Completion Status Filter
            Picker("Completion Status", selection: $completionFilter) {
                ForEach(AcademicCompletionFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
        }
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 44))
                .foregroundStyle(Color.academicAccent.opacity(0.6))
            Text("No Assignments Found")
                .font(.headline)
            Text(selectedCourseID != nil ? "No tasks matching this course and status filter." : "Create an assignment to get started.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Add Assignment") {
                showCreateTaskSheet = true
            }
            .buttonStyle(.bordered)
            .tint(Color.academicAccent)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .vantageGlassCard()
    }
}

public enum AcademicCompletionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case completed = "Completed"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}
