//
//  RelativeTimeText.swift
//  SnapOCR
//

import SwiftUI

/// 現在からの相対時刻を、指定したロケールで表示する。
/// `Text(_:format:)` は再描画されるまで更新されず、常駐するメニューでは古い表示が残るため、1 分ごとに描き直す。
struct RelativeTimeText: View {
    let date: Date
    let locale: Locale

    var body: some View {
        TimelineView(.everyMinute) { _ in
            Text(date.formatted(.relative(presentation: .named).locale(locale)))
        }
    }
}
