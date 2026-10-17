//
//  CategoryBadge.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI

/// Distinct spatial pill badge for Academic (#7779C9) and Work (#2A9D98) categories
public struct CategoryBadge: View {
    public let category: PlannerCategory
    public var isCompact: Bool = false
    
    public init(category: PlannerCategory, isCompact: Bool = false) {
        self.category = category
        self.isCompact = isCompact
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.iconName)
                .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
            
            if !isCompact {
                Text(category.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .padding(.horizontal, isCompact ? 6 : 9)
        .padding(.vertical, isCompact ? 3 : 5)
        .foregroundStyle(category.accentColor)
        .background(
            Capsule()
                .fill(category.accentColor.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(category.accentColor.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

/// Badge showing task priority with visual color and SF Symbol
public struct PriorityBadge: View {
    public let priority: Priority
    
    public init(priority: Priority) {
        self.priority = priority
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: priority.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(priority.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .foregroundStyle(priority.color)
        .background(
            Capsule()
                .fill(priority.color.opacity(0.15))
        )
    }
}
