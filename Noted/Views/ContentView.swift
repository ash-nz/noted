import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: NoteStore

    private var accent: Color { TabColor.color(at: store.selectedIndex) }

    private var textBinding: Binding<String> {
        Binding(
            get: { store.notes[store.selectedIndex].text },
            set: { store.updateText($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TabBarView()
            Divider()
            editor
            Divider()
            BottomBar()
        }
        .frame(width: 380, height: 460)
        .background(accent.opacity(0.06))
        .background(.background)
        .tint(accent)
        .background(tabShortcuts)
    }

    @ViewBuilder
    private var editor: some View {
        if store.selectedNote.mode == .markdown {
            MarkdownView(text: store.selectedNote.text, accent: accent)
        } else {
            EditorView(text: textBinding)
        }
    }

    /// Invisible buttons that bind ⌘1–⌘9 and ⌘0 to tab selection.
    private var tabShortcuts: some View {
        ForEach(0..<NoteStore.tabCount, id: \.self) { index in
            Button("") { store.selectedIndex = index }
                .keyboardShortcut(KeyEquivalent(Character("\((index + 1) % 10)")),
                                  modifiers: .command)
                .opacity(0)
        }
    }
}
