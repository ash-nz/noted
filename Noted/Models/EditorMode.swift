import Foundation

/// How a tab's content is presented. The underlying text is always the same
/// plain-text file on disk; only the rendering differs.
enum EditorMode: String, Codable, CaseIterable, Identifiable {
    /// Editable plain-text editor.
    case text
    /// Read-only rendered Markdown preview.
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text"
        case .markdown: return "Markdown"
        }
    }
}
