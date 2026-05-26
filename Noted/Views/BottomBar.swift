import SwiftUI

struct BottomBar: View {
    @EnvironmentObject private var store: NoteStore

    private var stats: String {
        let text = store.selectedNote.text
        let words = text.split { $0.isWhitespace || $0.isNewline }.count
        let chars = text.count
        return "\(words) word\(words == 1 ? "" : "s") · \(chars) char\(chars == 1 ? "" : "s")"
    }

    private var modeBinding: Binding<EditorMode> {
        Binding(
            get: { store.selectedNote.mode },
            set: { store.setMode($0, for: store.selectedIndex) }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(stats)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Mode", selection: modeBinding) {
                ForEach(EditorMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
            .keyboardShortcut("/", modifiers: .command)

            menu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var menu: some View {
        Menu {
            Button("Copy All") {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(store.selectedNote.text, forType: .string)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])

            Divider()

            Button("Quit Noted") {
                store.flush()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 13))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
