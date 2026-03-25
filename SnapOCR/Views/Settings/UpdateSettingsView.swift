//
//  UpdateSettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct UpdateSettingsView: View {
    var body: some View {
        PlaceholderSettingsView(
            systemImage: "arrow.triangle.2.circlepath",
            message: String(localized: "Update settings will be available in Phase 5.", comment: "Placeholder message for update settings not yet implemented")
        )
    }
}
