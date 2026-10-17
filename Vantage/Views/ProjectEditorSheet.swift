//
//  ProjectEditorSheet.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Modal sheet form to Create, Read, Update, and Delete an Academic Course or Work Project.
public struct ProjectEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    public let projectToEdit: CourseProject?
    public let initialCategory: PlannerCategory
    public var onCreated: ((CourseProject) -> Void)? = nil
    
    @State private var name: String
    @State private var identifier: String
    @State private var category: PlannerCategory
    @State private var iconName: String
    @State private var colorHex: String
    @State private var showDeleteConfirmation: Bool = false
    
    // Sample SF Symbols for selection
    private let academicIcons = ["graduationcap.fill", "books.vertical.fill", "atom", "function", "brain.head.profile", "network"]
    private let workIcons = ["briefcase.fill", "folder.fill", "hammer.fill", "macbook", "chart.line.uptrend.xyaxis", "visionpro"]
    
    public init(
        projectToEdit: CourseProject? = nil,
        initialCategory: PlannerCategory = .academic,
        onCreated: ((CourseProject) -> Void)? = nil
    ) {
        self.projectToEdit = projectToEdit
        self.initialCategory = initialCategory
        self.onCreated = onCreated
        
        if let project = projectToEdit {
            _name = State(initialValue: project.name)
            _identifier = State(initialValue: project.identifier)
            _category = State(initialValue: project.category)
            _iconName = State(initialValue: project.iconName)
            _colorHex = State(initialValue: project.colorHex)
        } else {
            _name = State(initialValue: "")
            _identifier = State(initialValue: "")
            _category = State(initialValue: initialCategory)
            _iconName = State(initialValue: initialCategory == .academic ? "graduationcap.fill" : "briefcase.fill")
            _colorHex = State(initialValue: initialCategory == .academic ? "#7779C9" : "#2A9D98")
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var activeAccent: Color {
        category == .academic ? Color.academicAccent : Color.workAccent
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Basic Details") {
                    TextField(category == .academic ? "Course Name (e.g. Distributed Systems)" : "Project Name (e.g. iOS Client Redesign)", text: $name)
                    
                    TextField(category == .academic ? "Identifier (e.g. CS-450)" : "Identifier (e.g. PRJ-VAN-01)", text: $identifier)
                    
                    Picker("Domain Category", selection: $category) {
                        ForEach(PlannerCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.iconName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(activeAccent)
                    .onChange(of: category) { _, newCat in
                        iconName = newCat == .academic ? "graduationcap.fill" : "briefcase.fill"
                        colorHex = newCat == .academic ? "#7779C9" : "#2A9D98"
                    }
                }
                
                Section("Visual Style") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            let availableIcons = category == .academic ? academicIcons : workIcons
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    iconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(iconName == icon ? activeAccent.opacity(0.3) : Color.white.opacity(0.06))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(iconName == icon ? activeAccent : Color.clear, lineWidth: 2)
                                                )
                                        )
                                        .foregroundStyle(iconName == icon ? activeAccent : .white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Destructive Section (if editing existing course/project)
                if projectToEdit != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label(category == .academic ? "Delete Course" : "Delete Project", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(projectToEdit == nil ? (category == .academic ? "New Course" : "New Project") : (category == .academic ? "Edit Course" : "Edit Project"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(projectToEdit == nil ? "Create" : "Save") {
                        saveProject()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.bold)
                    .tint(activeAccent)
                }
            }
            .confirmationDialog(category == .academic ? "Delete Course?" : "Delete Project?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let existing = projectToEdit {
                        modelContext.delete(existing)
                        try? modelContext.save()
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this \(category.title.lowercased())? Associated tasks and events will be unassigned.")
            }
        }
        .frame(minWidth: 480, idealWidth: 540, minHeight: 460, idealHeight: 520)
        .preferredColorScheme(.dark)
    }
    
    private func saveProject() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanId = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = projectToEdit {
            existing.name = cleanName
            existing.identifier = cleanId
            existing.category = category
            existing.colorHex = colorHex
            existing.iconName = iconName
            try? modelContext.save()
        } else {
            let newProject = CourseProject(
                name: cleanName,
                category: category,
                identifier: cleanId,
                colorHex: colorHex,
                iconName: iconName
            )
            modelContext.insert(newProject)
            try? modelContext.save()
            onCreated?(newProject)
        }
    }
}
