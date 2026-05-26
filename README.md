# Noted

A tiny, elegant menu bar scratchpad for macOS — **10 color tabs**, plain text and Markdown, nothing else in the way. Inspired by [Tot](https://tot.rocks).

> Open source (MIT). A separate, cross-platform **noted-pro** app with extra features lives in its own repo and is developed independently.

## Features

- **10 color tabs** — switch with a click or `⌘1`–`⌘0`
- **Text ⇄ Markdown** per tab — edit as plain text, toggle to a rendered preview (`⌘/`)
- **Autosaves** continuously to human-readable `.txt` files
- **Menu bar only** — no Dock icon, no clutter (`LSUIElement`)
- Built entirely in **SwiftUI**, no third-party dependencies

## Requirements

- macOS 15 (Sequoia) or later, Apple silicon
- Xcode 26+

## Build & run

```sh
open Noted.xcodeproj      # then press ⌘R in Xcode
```

Or from the command line:

```sh
xcodebuild -project Noted.xcodeproj -scheme Noted -configuration Debug build
```

## Where notes are stored

Plain text, one file per tab, inside the app's sandbox container:

```
~/Library/Containers/com.noted.Noted/Data/Library/Application Support/Noted/note-0.txt … note-9.txt
```

Per-tab mode and the selected tab are kept in `UserDefaults`.

## Project layout

```
Noted/
  NotedApp.swift          # @main, MenuBarExtra scene
  Models/
    Note.swift            # one tab's content
    NoteStore.swift       # state + plain-text persistence (debounced autosave)
    EditorMode.swift      # .text / .markdown
    TabColor.swift        # the 10-color palette
  Views/
    ContentView.swift     # layout + ⌘1–⌘0 shortcuts
    TabBarView.swift       # the row of color dots
    EditorView.swift       # plain-text editor
    MarkdownView.swift     # dependency-free Markdown preview + parser
    BottomBar.swift        # word/char count, mode toggle, menu
```

## License

MIT — see [LICENSE](LICENSE).
