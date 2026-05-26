import Foundation

/// A single tab's note. `id` is the stable tab index (0–9).
struct Note: Identifiable {
    let id: Int
    var text: String
    var mode: EditorMode
}
