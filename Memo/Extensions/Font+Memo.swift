//
//  Font+Memo.swift
//  Memo
//
//  Typography aliases over the SF Pro system font.
//  Using Dynamic Type ensures the app respects user accessibility settings.
//

import SwiftUI

extension Font {

    // MARK: - Display

    /// 34pt Large Title — greeting, onboarding headings.
    static let memoLargeTitle = Font.largeTitle.weight(.bold)

    /// 28pt Title — section headings, total amounts.
    static let memoTitle = Font.title.weight(.semibold)

    /// 22pt Title 2 — card headings.
    static let memoTitle2 = Font.title2.weight(.semibold)

    /// 17pt Headline — transaction names, action labels.
    static let memoHeadline = Font.headline

    // MARK: - Body

    /// 17pt Body — default body text.
    static let memoBody = Font.body

    /// 15pt Subheadline — secondary labels, dates.
    static let memoSubheadline = Font.subheadline

    /// 13pt Caption — category badges, metadata.
    static let memoCaption = Font.caption

    // MARK: - Numeric (Monospaced)

    /// Monospaced number display for amounts — prevents layout shift.
    static let memoAmount = Font.system(
        .title2,
        design: .rounded,
        weight: .bold
    ).monospacedDigit()

    /// Large monospaced amount — preview sheets.
    static let memoAmountLarge = Font.system(
        .largeTitle,
        design: .rounded,
        weight: .heavy
    ).monospacedDigit()

    /// Small inline amount — list rows.
    static let memoAmountSmall = Font.system(
        .subheadline,
        design: .rounded,
        weight: .semibold
    ).monospacedDigit()
}
