//
//  HistorySettingsView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct HistorySettingsView: View {
    var body: some View {
        PlaceholderSettingsView(
            systemImage: "clock.arrow.circlepath",
            message: String(localized: "History settings will be available in Phase 4.", comment: "Placeholder message for history settings not yet implemented")
        )
    }
}
