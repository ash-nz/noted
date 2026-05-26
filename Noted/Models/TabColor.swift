import SwiftUI

/// The fixed palette for the 10 tabs. Index maps 1:1 to the tab index (0–9).
enum TabColor {
    static let all: [Color] = [
        Color(red: 0.55, green: 0.59, blue: 0.66), // 1 · Graphite
        Color(red: 0.91, green: 0.31, blue: 0.36), // 2 · Red
        Color(red: 0.95, green: 0.55, blue: 0.20), // 3 · Orange
        Color(red: 0.92, green: 0.77, blue: 0.21), // 4 · Amber
        Color(red: 0.30, green: 0.72, blue: 0.45), // 5 · Green
        Color(red: 0.18, green: 0.72, blue: 0.66), // 6 · Teal
        Color(red: 0.23, green: 0.51, blue: 0.96), // 7 · Blue
        Color(red: 0.39, green: 0.40, blue: 0.95), // 8 · Indigo
        Color(red: 0.66, green: 0.33, blue: 0.97), // 9 · Purple
        Color(red: 0.93, green: 0.28, blue: 0.60), // 10 · Pink
    ]

    static func color(at index: Int) -> Color {
        all[min(max(index, 0), all.count - 1)]
    }
}
