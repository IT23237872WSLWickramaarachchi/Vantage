//
//  MainNavigationView.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

/// The primary navigation view for Vantage using visionOS `NavigationSplitView`.
/// Features exactly six destinations in the sidebar:
/// Overview, Academic, Work, Calendar, Insights, and Settings.
public struct MainNavigationView: View {
    @State private var selectedDestination: NavigationDestination? = .overview
    
    @Query private var tasks: [Task]
    @Query private var settingsList: [ApplicationSettings]
    @Environment(\.openWindow) private var openWindow
    @Environment(AppModel.self) private var appModel
    
    public init() {}
    
    private var pendingAcademicCount: Int {
        tasks.filter { $0.category == .academic && $0.status != .completed }.count
    }
    
    private var pendingWorkCount: Int {
        tasks.filter { $0.category == .work && $0.status != .completed }.count
    }
    
    public var body: some View {
        NavigationSplitView {
            // MARK: - Primary Sidebar (Exactly 6 Destinations)
            sidebarContent
                .navigationTitle("Vantage")
        } detail: {
            // MARK: - Detail Stage
            detailContent
        }
        .preferredColorScheme(settingsList.first?.appearanceTheme == "Light" ? .light : (settingsList.first?.appearanceTheme == "System" ? nil : .dark))
    }
    
    // MARK: - Sidebar Construction
    private var sidebarContent: some View {
        List(selection: $selectedDestination) {
            // Branding Header
            Section {
                brandingHeader
            }
            .listRowBackground(Color.clear)
            
            // Destinations Section (Exactly 6 items)
            Section("Workspace") {
                // 1. Overview
                destinationRow(destination: .overview)
                
                // 2. Academic (Indigo #7779C9)
                destinationRow(
                    destination: .academic,
                    badgeCount: pendingAcademicCount,
                    accentColor: Color.academicAccent
                )
                
                // 3. Work (Teal #2A9D98)
                destinationRow(
                    destination: .work,
                    badgeCount: pendingWorkCount,
                    accentColor: Color.workAccent
                )
                
                // 4. Calendar
                destinationRow(destination: .calendar)
                
                // 5. Insights
                destinationRow(destination: .insights)
                
                // 6. Settings
                destinationRow(destination: .settings)
            }
            
            // Spatial Utilities Section
            Section("Spatial Tools") {
                Button {
                    openWindow(id: VantageWindowID.standaloneCalendar)
                } label: {
                    Label("Detach Calendar Window", systemImage: "macwindow.badge.plus")
                        .font(.callout)
                }
                .foregroundStyle(Color.workAccent)
                
                ToggleImmersiveSpaceButton()
            }
        }
        .listStyle(.sidebar)
    }
    
    private var brandingHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.academicAccent, Color.workAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("VANTAGE")
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .tracking(1.5)
                Text("Study & Work Planner")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func destinationRow(
        destination: NavigationDestination,
        badgeCount: Int? = nil,
        accentColor: Color? = nil
    ) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 10) {
                Image(systemName: destination.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor ?? destination.accentColor)
                    .frame(width: 24)
                
                Text(destination.title)
                    .font(.headline.weight(.medium))
                
                Spacer()
                
                if let badgeCount, badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((accentColor ?? .secondary).opacity(0.2)))
                        .foregroundStyle(accentColor ?? .secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Detail Routing
    @ViewBuilder
    private var detailContent: some View {
        if let selectedDestination {
            switch selectedDestination {
            case .overview:
                OverviewView()
            case .academic:
                AcademicPlannerView()
            case .work:
                WorkPlannerView()
            case .calendar:
                CalendarPlannerView()
            case .insights:
                InsightsView()
            case .settings:
                SettingsView()
            }
        } else {
            ContentUnavailableView(
                "Select a Destination",
                systemImage: "sidebar.left",
                description: Text("Choose one of the 6 workspace views from the navigation sidebar.")
            )
        }
    }
}
