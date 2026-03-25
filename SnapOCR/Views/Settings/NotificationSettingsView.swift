//
//  NotificationSettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct NotificationSettingsView: View {
    var body: some View {
        PlaceholderSettingsView(
            systemImage: "bell.badge",
            message: String(localized: "Notification settings will be available in Phase 3.", comment: "Placeholder message for notification settings not yet implemented")
        )
    }
}
