//
//  ScheduleEventEditorSheet.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// Modal sheet form to Create, Read, Update, and Delete Schedule Events.
public struct ScheduleEventEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    public let eventToEdit: ScheduleEvent?
    public let initialDate: Date
    public let initialCategory: PlannerCategory
    
    @Query(sort: \CourseProject.name) private var allProjects: [CourseProject]
    @Query private var settingsList: [ApplicationSettings]
    
    // Form State
    @State private var title: String
    @State private var category: PlannerCategory
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isAllDay: Bool
    @State private var location: String
    @State private var notes: String
    @State private var selectedProject: CourseProject?
    @State private var showDeleteConfirmation: Bool = false
    
    public init(
        eventToEdit: ScheduleEvent? = nil,
        initialDate: Date = Date(),
        initialCategory: PlannerCategory = .academic
    ) {
        self.eventToEdit = eventToEdit
        self.initialDate = initialDate
        self.initialCategory = initialCategory
        
        if let event = eventToEdit {
            _title = State(initialValue: event.title)
            _category = State(initialValue: event.category)
            _date = State(initialValue: event.date)
            _startTime = State(initialValue: event.startTime)
            _endTime = State(initialValue: event.endTime)
            _isAllDay = State(initialValue: event.isAllDay)
            _location = State(initialValue: event.location ?? "")
            _notes = State(initialValue: event.notes)
            _selectedProject = State(initialValue: event.courseProject)
        } else {
            _title = State(initialValue: "")
            _category = State(initialValue: initialCategory)
            _date = State(initialValue: initialDate)
            
            let defaultDuration = 60 // fallback minutes
            let start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: initialDate) ?? initialDate
            let end = start.addingTimeInterval(TimeInterval(defaultDuration * 60))
            
            _startTime = State(initialValue: start)
            _endTime = State(initialValue: end)
            _isAllDay = State(initialValue: false)
            _location = State(initialValue: "")
            _notes = State(initialValue: "")
            _selectedProject = State(initialValue: nil)
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
                // Section 1: General Info
                Section {
                    TextField("Event Title (e.g. CS 450 Lecture, Sprint Standup)", text: $title)
                        .font(.headline)
                    
                    Picker("Domain Category", selection: $category) {
                        ForEach(PlannerCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.iconName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(activeAccent)
                    .onChange(of: category) { _, newCat in
                        if let current = selectedProject, current.category != newCat {
                            selectedProject = nil
                        }
                    }
                    
                    Picker(category == .academic ? "Course" : "Project", selection: $selectedProject) {
                        Text("None").tag(nil as CourseProject?)
                        ForEach(relevantProjects) { proj in
                            Text("\(proj.identifier) - \(proj.name)").tag(proj as CourseProject?)
                        }
                    }
                } header: {
                    Text("General")
                }
                
                // Section 2: Timing
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    
                    Toggle("All-Day Event", isOn: $isAllDay)
                    
                    if !isAllDay {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                        
                        if endTime <= startTime {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(Color.conflictWarning)
                                Text("End time must be after start time")
                                    .font(.caption)
                                    .foregroundStyle(Color.conflictWarning)
                            }
                        }
                    }
                } header: {
                    Text("Date & Time")
                }
                
                // Section 3: Location & Details
                Section {
                    TextField("Location / Video Meeting Link", text: $location)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Location & Notes")
                }
                
                // Section 4: Deletion (If Editing)
                if eventToEdit != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Event", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(eventToEdit == nil ? "New Schedule Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(eventToEdit == nil ? "Add" : "Save") {
                        saveEvent()
                        dismiss()
                    }
                    .disabled(!isFormValid || (!isAllDay && endTime <= startTime))
                    .fontWeight(.bold)
                    .tint(activeAccent)
                }
            }
            .confirmationDialog("Delete Event?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let existing = eventToEdit {
                        modelContext.delete(existing)
                        try? modelContext.save()
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
        .frame(minWidth: 500, idealWidth: 560, minHeight: 520, idealHeight: 600)
        .preferredColorScheme(settingsList.first?.appearanceTheme == "Light" ? .light : (settingsList.first?.appearanceTheme == "System" ? nil : .dark))
        .onAppear {
            if eventToEdit == nil {
                let durationMinutes = settingsList.first?.defaultEventDurationMinutes ?? 60
                endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
            }
        }
    }
    
    private func saveEvent() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location
        
        if let existing = eventToEdit {
            existing.title = cleanTitle
            existing.category = category
            existing.date = date
            existing.startTime = isAllDay ? Calendar.current.startOfDay(for: date) : startTime
            existing.endTime = isAllDay ? Calendar.current.startOfDay(for: date).addingTimeInterval(86400) : endTime
            existing.isAllDay = isAllDay
            existing.location = cleanLocation
            existing.notes = notes
            existing.courseProject = selectedProject
        } else {
            let newEvent = ScheduleEvent(
                title: cleanTitle,
                category: category,
                date: date,
                startTime: isAllDay ? Calendar.current.startOfDay(for: date) : startTime,
                endTime: isAllDay ? Calendar.current.startOfDay(for: date).addingTimeInterval(86400) : endTime,
                courseProject: selectedProject,
                location: cleanLocation,
                notes: notes,
                isAllDay: isAllDay
            )
            modelContext.insert(newEvent)
        }
        try? modelContext.save()
    }
}
