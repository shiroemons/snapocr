//
//  RecentCapturesView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

/// Phase 4 までのプレースホルダー実装。
/// 最近のキャプチャ履歴セクションを表示する。
@MainActor
struct RecentCapturesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Recent Captures", comment: "Section header for recent captures"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            HStack {
                Spacer()
                Text(String(localized: "No captures yet", comment: "Placeholder text when no capture history exists"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    RecentCapturesView()
        .frame(width: 320)
        .padding()
}
#endif
