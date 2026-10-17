//
//  TaskCardRow.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Interactive glass card representing a Task in lists and boards.
/// Provides direct actions to open the reusable Task Editor sheet or the dedicated visionOS utility window.
public struct TaskCardRow: View {
    @Bindable public var task: Task
    public var onEdit: (() -> Void)? = nil
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    public init(task: Task, onEdit: (() -> Void)? = nil) {
        self.task = task
        self.onEdit = onEdit
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Status Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if task.status == .completed {
                        task.status = .toDo
                        task.completedAt = nil
                    } else {
                        task.status = .completed
                        task.completedAt = Date()
                    }
                    try? modelContext.save()
                }
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(task.status == .completed ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.status == .completed)
                        .foregroundStyle(task.status == .completed ? .secondary : .primary)
                    
                    Spacer()
                    
                    CategoryBadge(category: task.category)
                    PriorityBadge(priority: task.priority)
                }
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    // Associated Course / Project
                    if let project = task.courseProject {
                        HStack(spacing: 4) {
                            Image(systemName: project.iconName)
                                .font(.caption2)
                            Text("\(project.identifier) • \(project.name)")
                                .font(.caption)
                        }
                        .foregroundStyle(task.category.accentColor.opacity(0.85))
                    }
                    
                    // Due Date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDueDate(dueDate, hasSpecificTime: task.hasSpecificTime))
                                .font(.caption)
                        }
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(task.formattedDuration)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let onEdit {
                    onEdit()
                } else {
                    openWindow(id: VantageWindowID.taskDetail, value: task.id)
                }
            }
            
            // Actions: Edit Sheet & Detach Window
            HStack(spacing: 6) {
                if let onEdit {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(8)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Edit in Modal Sheet")
                }
                
                Button {
                    openWindow(id: VantageWindowID.taskDetail, value: task.id)
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(8)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Open in Task Details Window")
            }
        }
        .padding(14)
        .vantageGlassCard()
        .contextMenu {
            Button {
                if let onEdit {
                    onEdit()
                } else {
                    openWindow(id: VantageWindowID.taskDetail, value: task.id)
                }
            } label: {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button {
                withAnimation {
                    if task.status == .completed {
                        task.status = .toDo
                        task.completedAt = nil
                    } else {
                        task.status = .completed
                        task.completedAt = Date()
                    }
                    try? modelContext.save()
                }
            } label: {
                Label(task.status == .completed ? "Mark as Incomplete" : "Mark as Completed", systemImage: task.status == .completed ? "circle" : "checkmark.circle.fill")
            }
            
            Button {
                openWindow(id: VantageWindowID.taskDetail, value: task.id)
            } label: {
                Label("Open in Auxiliary Window", systemImage: "arrow.up.forward.app")
            }
            
            Divider()
            
            Button(role: .destructive) {
                modelContext.delete(task)
                try? modelContext.save()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
    
    private func formatDueDate(_ date: Date, hasSpecificTime: Bool) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            if hasSpecificTime {
                formatter.dateFormat = "'Today at' h:mm a"
                return formatter.string(from: date)
            }
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            if hasSpecificTime {
                formatter.dateFormat = "'Tomorrow at' h:mm a"
                return formatter.string(from: date)
            }
            return "Tomorrow"
        } else {
            formatter.dateFormat = hasSpecificTime ? "MMM d, h:mm a" : "MMM d"
            return formatter.string(from: date)
        }
    }
}
