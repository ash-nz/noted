import SwiftUI

/// Owns the 10 notes, the current selection, and all persistence.
///
/// Note text is stored as plain `.txt` files in Application Support so the data
/// stays human-readable and easy to back up. Per-tab presentation mode and the
/// selected tab live in `UserDefaults` since they're lightweight app state.
@MainActor
final class NoteStore: ObservableObject {
    static let tabCount = 10

    @Published var notes: [Note]
    @Published var selectedIndex: Int {
        didSet { UserDefaults.standard.set(selectedIndex, forKey: Keys.selectedIndex) }
    }

    private let directory: URL
    private var pendingSaves: [Int: DispatchWorkItem] = [:]
    private let saveDelay: TimeInterval = 0.4

    private enum Keys {
        static let selectedIndex = "noted.selectedIndex"
        static let didSeedWelcome = "noted.didSeedWelcome"
        static func mode(_ index: Int) -> String { "noted.mode.\(index)" }
    }

    var selectedNote: Note { notes[selectedIndex] }

    // MARK: - Lifecycle

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Noted", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.directory = dir

        let defaults = UserDefaults.standard
        self.selectedIndex = min(max(defaults.integer(forKey: Keys.selectedIndex), 0),
                                 Self.tabCount - 1)

        var loaded: [Note] = []
        loaded.reserveCapacity(Self.tabCount)
        for index in 0..<Self.tabCount {
            let url = dir.appendingPathComponent("note-\(index).txt")
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let mode = EditorMode(rawValue: defaults.string(forKey: Keys.mode(index)) ?? "")
                ?? .text
            loaded.append(Note(id: index, text: text, mode: mode))
        }
        self.notes = loaded

        seedWelcomeNoteIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    // MARK: - Mutations

    func updateText(_ text: String) {
        notes[selectedIndex].text = text
        scheduleSave(index: selectedIndex)
    }

    func setMode(_ mode: EditorMode, for index: Int) {
        notes[index].mode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Keys.mode(index))
    }

    func toggleMode() {
        let next: EditorMode = selectedNote.mode == .text ? .markdown : .text
        setMode(next, for: selectedIndex)
    }

    // MARK: - Persistence

    private func fileURL(_ index: Int) -> URL {
        directory.appendingPathComponent("note-\(index).txt")
    }

    private func scheduleSave(index: Int) {
        pendingSaves[index]?.cancel()
        let url = fileURL(index)
        let text = notes[index].text
        let work = DispatchWorkItem {
            try? Data(text.utf8).write(to: url, options: .atomic)
        }
        pendingSaves[index] = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + saveDelay,
                                                       execute: work)
    }

    /// Flushes any pending writes immediately (e.g. on quit).
    func flush() {
        for (index, work) in pendingSaves {
            work.cancel()
            let url = fileURL(index)
            try? Data(notes[index].text.utf8).write(to: url, options: .atomic)
        }
        pendingSaves.removeAll()
    }

    @objc private func handleAppWillTerminate() {
        flush()
    }

    private func seedWelcomeNoteIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Keys.didSeedWelcome) else { return }
        defaults.set(true, forKey: Keys.didSeedWelcome)

        guard notes.allSatisfy({ $0.text.isEmpty }) else { return }
        notes[0].text = Self.welcomeText
        setMode(.markdown, for: 0)
        scheduleSave(index: 0)
    }

    private static let welcomeText = """
    # Welcome to Noted

    A tiny menu bar scratchpad with **10 color tabs**.

    - Click a dot or press **⌘1–⌘0** to switch tabs
    - Toggle **Text ⇄ Markdown** at the bottom right
    - Everything autosaves to plain `.txt` files

    Try some Markdown:

    ## Lists
    1. First
    2. Second

    > Quotes look like this.

    `inline code` and [links](https://example.com) work too.
    """
}
