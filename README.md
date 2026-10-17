# Vantage

> Unified Study and Work Planner designed natively for Apple Vision Pro (`visionOS`).

Vantage bridges the gap between high-demand academic curricula and professional engineering workloads in a single spatial computing environment. Built with **SwiftUI**, **SwiftData**, **Swift Charts**, and **RealityKit Content**.

---

## Key Features

### 1. Spatial Multi-Window Architecture
- **Primary Command Center (`WindowGroup`)**: Features a native `NavigationSplitView` sidebar with six core destinations:
  - **Overview**: High-level telemetry, summary metrics (Open Tasks, Due in 7 Days, Completed Tasks), upcoming incomplete deliverables, and domain balance snapshot.
  - **Academic**: Course summaries, deliverables filtered by course and status, and Indigo accent tokens (`#7779C9`).
  - **Work**: Project sprint cards, deliverables filtered by initiative and status, and Teal accent tokens (`#2A9D98`).
  - **Calendar**: Monthly grid combining Task Deadlines and Schedule Events, with automatic fixed-time conflict detection and Coral warning alerts (`#E46B72`).
  - **Insights**: Swift Charts workload distribution, remaining effort comparison (Academic vs. Work), completion velocity donut chart, and cognitive threshold guardrails.
  - **Settings**: Live configuration for theme styles, window density, ambient glass glow, calendar starting day, default event duration, and cognitive overload limits.
- **Standalone Timetable Window**: Detachable auxiliary window designed for persistent spatial placement next to other workspaces.
- **Task Detail Utility Inspector**: Dedicated utility window for focused editing and attribute review.

### 2. Comprehensive CRUD Operations
- **Tasks**: Create, read, update, and delete unified tasks with priority, duration estimates, status tracking, and course/project linkages.
- **Courses & Projects**: Full management of courses and initiatives with task count telemetry and cascade safety.
- **Schedule Events**: Integrated schedule event editor sheet with time-picker defaults and calendar integration.
- **Application Settings**: Live auto-saving settings with factory reset and completed task purging.

### 3. Cognitive Guardrails & Workload Analytics
- Proactive burnout warnings when estimated backlog exceeds daily study or employment targets.
- Conflict detection flags overlapping commitments on the same date with visual badges and guidance.
- Dynamic theme adaptation (Dark Glass, Light Glass, System) and configurable ambient glassmorphic edge luminescence.

---

## Design System & Color Tokens

- **Academic Domain**: `#7779C9` (Indigo)
- **Work Domain**: `#2A9D98` (Teal)
- **Conflict Warning**: `#E46B72` (Coral)
- **Surfaces**: Native visionOS dark glassmorphism with subtle border strokes and continuous rounded corners.

---

## Project Structure

```
Vantage/
├── Vantage.xcodeproj/                # Xcode project file
├── Vantage/                          # Main application source
│   ├── VantageApp.swift              # App entry point & ModelContainer setup
│   ├── Navigation/                   # MainNavigationView, NavigationDestination, Window IDs
│   ├── Models/                       # SwiftData models: Task, CourseProject, ScheduleEvent, ApplicationSettings
│   ├── Views/                        # Primary destination views & editor sheets
│   │   ├── OverviewView.swift
│   │   ├── AcademicPlannerView.swift
│   │   ├── WorkPlannerView.swift
│   │   ├── CalendarPlannerView.swift
│   │   ├── StandaloneCalendarView.swift
│   │   ├── InsightsView.swift
│   │   ├── SettingsView.swift
│   │   ├── TaskDetailUtilityView.swift
│   │   ├── TaskEditorSheet.swift
│   │   ├── ProjectEditorSheet.swift
│   │   ├── ScheduleEventEditorSheet.swift
│   │   └── Components/
│   └── Theme/                        # Design tokens, colors, glassmorphic card modifiers
├── VantageTests/                     # Comprehensive XCTest suite
└── Packages/
    └── RealityKitContent/            # Reality Composer Pro assets & content bundle
```

---

## Requirements & Building

- **macOS**: Sequoia 15.0 or later
- **Xcode**: 16.0 or later
- **Target Platform**: visionOS 2.0+ (Apple Vision Pro)

### Build & Test via Command Line:
```bash
# Build scheme
xcodebuild -scheme Vantage -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Run test suite
xcodebuild test -scheme Vantage -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

---

## License

Developed for academic and professional spatial productivity.
