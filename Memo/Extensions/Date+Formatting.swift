//
//  Date+Formatting.swift
//  Memo
//
//  Relative and absolute date formatting helpers used throughout the UI.
//  All formatters are created once and reused — date formatters are
//  expensive to initialise.
//

import Foundation

extension Date {

    // MARK: - Relative Labels

    /// "Today", "Yesterday", "Monday", or "Jun 27"
    var memoRelativeLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self)     { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }

        // Within the last 7 days → show day name
        let daysAgo = calendar.dateComponents([.day], from: self, to: Date()).day ?? 999
        if daysAgo < 7 { return self.formatted(.dateTime.weekday(.wide)) }

        // Within the same year → "Jun 27"
        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            return self.formatted(.dateTime.month(.abbreviated).day())
        }

        // Older → "Jun 27, 2024"
        return self.formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// "2:30 PM"
    var memoTimeLabel: String {
        self.formatted(.dateTime.hour().minute())
    }

    /// "Jun 27, 2026 · 2:30 PM"
    var memoFullLabel: String {
        self.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }

    /// "June 2026" — used for budget/month headers
    var memoMonthYearLabel: String {
        self.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Comparison Helpers

    /// True if this date is within the current calendar day.
    var isToday: Bool { Calendar.current.isDateInToday(self) }

    /// True if this date is within the current calendar week.
    var isThisWeek: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) }

    /// True if this date is within the current calendar month.
    var isThisMonth: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month) }

    // MARK: - Start of Period

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }
}
