//
//  Date+Extension.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 08/04/25.
//

import Foundation

extension Date {
    
    func TimeAgoSinceNow() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents(
            [.second, .minute, .hour, .day, .weekOfYear, .month, .year],
            from: self,
            to: now
        )

        if let year = components.year, year >= 1 {
            return year == 1 ? "1y ago" : "\(year)y ago"
        }
        if let month = components.month, month >= 1 {
            return month == 1 ? "1mo ago" : "\(month)mo ago"
        }
        if let week = components.weekOfYear, week >= 1 {
            return week == 1 ? "1w ago" : "\(week)w ago"
        }
        if let day = components.day, day >= 1 {
            return day == 1 ? "1d ago" : "\(day)d ago"
        }
        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? "1h ago" : "\(hour)h ago"
        }
        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? "1m ago" : "\(minute)m ago"
        }
        if let second = components.second, second >= 3 {
            return "\(second)s ago"
        }
        return "just now"
    }
    
    var sectionHeader: String {
         let calendar = Calendar.current
         if calendar.isDateInToday(self) {
             return "Today"
         } else if calendar.isDateInYesterday(self) {
             return "Yesterday"
         } else {
             let formatter = DateFormatter()
             formatter.dateStyle = .medium
             return formatter.string(from: self)
         }
     }
 }
