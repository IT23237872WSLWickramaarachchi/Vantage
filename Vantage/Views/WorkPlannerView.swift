//
//  WorkPlannerView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Work & Professional Planner View themed with Teal (#2A9D98).
/// Features project summary cards at the top showing open and completed task counts,
/// and a task list filterable by selected project and completion status.
public struct WorkPlannerView: View {
    @Query(sort: \Task.dueDate) private var allTasks: [Task]
    @Query(sort: \CourseProject.name) private var allProjects: [CourseProject]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    // Filtering State
    @State private var selectedProjectID: UUID? = nil // nil means "All Projects"
    @State private var completionFilter: WorkCompletionFilter = .all
    
    // Sheet State
    @State private var showCreateTaskSheet: Bool = false
    @State private var showCreateProjectSheet: Bool = false
    @State private var taskToEdit: Task? = nil
    @State private var projectToEdit: CourseProject? = nil
    
    public init() {}
    
    private var workProjects: [CourseProject] {
        allProjects.filter { $0.category == .work }
    }
    
    private var allWorkTasks: [Task] {
        allTasks.filter { $0.category == .work }
    }
    
    /// Filtered tasks based on selected project and completion status
    private var filteredTasks: [Task] {
        allWorkTasks.filter { task in
            // Filter by Project
            if let selectedProjectID {
                guard task.courseProject?.id == selectedProjectID else { return false }
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
                
                // 1. Project Summary Cards (Showing Open & Completed Counts)
                projectSummaryCardsSection
                
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
        .navigationTitle("Work")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateTaskSheet = true
                } label: {
                    Label("New Deliverable", systemImage: "plus")
                }
                .tint(Color.workAccent)
            }
        }
        // Task Creation Sheet with Work Preselected
        .sheet(isPresented: $showCreateTaskSheet) {
            TaskEditorSheet(taskToEdit: nil, initialCategory: .work)
        }
        // Task Editing Sheet
        .sheet(item: $taskToEdit) { task in
            TaskEditorSheet(taskToEdit: task, initialCategory: .work)
        }
        // Project Creation Sheet
        .sheet(isPresented: $showCreateProjectSheet) {
            ProjectEditorSheet(initialCategory: .work)
        }
        // Project Editing Sheet
        .sheet(item: $projectToEdit) { project in
            ProjectEditorSheet(projectToEdit: project, initialCategory: .work)
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .foregroundStyle(Color.workAccent)
                    Text("Professional Work")
                        .font(.system(.title, design: .rounded, weight: .bold))
                }
                Text("Sprint deliverables, engineering tickets, client milestones, and company initiatives.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            Button {
                showCreateTaskSheet = true
            } label: {
                Label("Add Deliverable", systemImage: "plus.circle.fill")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.workAccent)
        }
    }
    
    // MARK: - Project Summary Cards
    private var projectSummaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Project Summaries")
                    .font(.title3.weight(.bold))
                Spacer()
                
                Button {
                    showCreateProjectSheet = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Color.workAccent)
                
                if selectedProjectID != nil {
                    Button("Show All") {
                        withAnimation { selectedProjectID = nil }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.workAccent)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // "All Projects" Aggregate Card
                    allProjectsSummaryCard
                    
                    // Individual Project Cards
                    ForEach(workProjects) { project in
                        individualProjectCard(project: project)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private var allProjectsSummaryCard: some View {
        let isSelected = selectedProjectID == nil
        let openCount = allWorkTasks.filter { $0.status != .completed }.count
        let completedCount = allWorkTasks.filter { $0.status == .completed }.count
        
        return Button {
            withAnimation { selectedProjectID = nil }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ALL")
                        .font(.caption.weight(.black))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.workAccent.opacity(isSelected ? 0.35 : 0.2))
                        .foregroundStyle(Color.workAccent)
                        .cornerRadius(6)
                    Spacer()
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.caption)
                        .foregroundStyle(Color.workAccent)
                }
                
                Text("All Projects")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Open & Completed Task Counts
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(openCount)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.workAccent)
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
            .vantageGlassCard(borderColor: isSelected ? Color.workAccent : Color.white.opacity(0.12))
        }
        .buttonStyle(.plain)
    }
    
    private func individualProjectCard(project: CourseProject) -> some View {
        let isSelected = selectedProjectID == project.id
        let projectTasks = allWorkTasks.filter { $0.courseProject?.id == project.id }
        let openCount = projectTasks.filter { $0.status != .completed }.count
        let completedCount = projectTasks.filter { $0.status == .completed }.count
        
        return Button {
            withAnimation {
                if selectedProjectID == project.id {
                    selectedProjectID = nil // Toggle off if already selected
                } else {
                    selectedProjectID = project.id
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(project.identifier)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.workAccent.opacity(isSelected ? 0.35 : 0.2))
                        .foregroundStyle(Color.workAccent)
                        .cornerRadius(6)
                    Spacer()
                    Image(systemName: project.iconName)
                        .font(.caption)
                        .foregroundStyle(Color.workAccent)
                }
                
                Text(project.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Open & Completed Task Counts
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(openCount)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.workAccent)
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
            .vantageGlassCard(borderColor: isSelected ? Color.workAccent : Color.workAccent.opacity(0.25))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                projectToEdit = project
            } label: {
                Label("Edit Project", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                if selectedProjectID == project.id {
                    selectedProjectID = nil
                }
                modelContext.delete(project)
                try? modelContext.save()
            } label: {
                Label("Delete Project", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Task List Header & Filters
    private var taskListHeaderAndFilters: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Deliverables & Action Items")
                    .font(.title2.weight(.bold))
                if let selectedProjectID, let project = workProjects.first(where: { $0.id == selectedProjectID }) {
                    Text("Filtered by: \(project.identifier) - \(project.name)")
                        .font(.caption)
                        .foregroundStyle(Color.workAccent)
                }
            }
            
            Spacer()
            
            // Completion Status Filter
            Picker("Completion Status", selection: $completionFilter) {
                ForEach(WorkCompletionFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
        }
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase")
                .font(.system(size: 44))
                .foregroundStyle(Color.workAccent.opacity(0.6))
            Text("No Deliverables Found")
                .font(.headline)
            Text(selectedProjectID != nil ? "No work items matching this project and status filter." : "Create a deliverable to get started.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Add Deliverable") {
                showCreateTaskSheet = true
            }
            .buttonStyle(.bordered)
            .tint(Color.workAccent)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .vantageGlassCard()
    }
}

public enum WorkCompletionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case completed = "Completed"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}
