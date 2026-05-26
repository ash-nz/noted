import SwiftUI

struct EditorView: View {
    @Binding var text: String

    /// macOS `NSTextView` lays the first glyph one `lineFragmentPadding` (~5pt)
    /// in from the text container's leading edge. The placeholder shares the
    /// editor's container (same `ZStack`, same outer padding), so it only needs
    /// to absorb that one inset to sit exactly on the insertion point.
    private let lineFragmentPadding: CGFloat = 5

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Start writing…")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, lineFragmentPadding)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.system(size: 14))
                .lineSpacing(2)
                .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
