import SwiftUI

/// A lightweight, dependency-free Markdown preview. Handles the common blocks
/// (headings, lists, quotes, fenced code, rules, paragraphs) and delegates
/// inline styling (bold/italic/code/links) to `AttributedString`.
struct MarkdownView: View {
    let text: String
    let accent: Color

    var body: some View {
        ScrollView {
            if text.isEmpty {
                Text("Nothing to preview yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(MarkdownParser.parse(text).enumerated()), id: \.offset) { _, block in
                        view(for: block)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private func view(for block: MarkdownParser.Block) -> some View {
        switch block {
        case .heading(let level, let content):
            inline(content)
                .font(.system(size: headingSize(level), weight: .semibold))
                .padding(.top, level <= 2 ? 4 : 0)

        case .paragraph(let content):
            inline(content)
                .font(.system(size: 14))

        case .bullet(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•").foregroundStyle(accent)
                        inline(item).font(.system(size: 14))
                    }
                }
            }

        case .ordered(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(i + 1).").foregroundStyle(accent).monospacedDigit()
                        inline(item).font(.system(size: 14))
                    }
                }
            }

        case .quote(let content):
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(accent.opacity(0.6))
                    .frame(width: 3)
                inline(content)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

        case .code(let content):
            Text(content)
                .font(.system(size: 12.5, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

        case .rule:
            Divider().padding(.vertical, 2)
        }
    }

    private func inline(_ string: String) -> Text {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attributed = try? AttributedString(markdown: string, options: options) {
            return Text(attributed)
        }
        return Text(string)
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 22
        case 2: return 18
        case 3: return 16
        default: return 14
        }
    }
}

/// Splits Markdown source into renderable blocks. Intentionally small — it
/// covers the everyday cases without pulling in a full CommonMark engine.
enum MarkdownParser {
    enum Block {
        case heading(level: Int, text: String)
        case paragraph(String)
        case bullet([String])
        case ordered([String])
        case quote(String)
        case code(String)
        case rule
    }

    static func parse(_ text: String) -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: .newlines)
        var i = 0

        func flushParagraph(_ buffer: inout [String]) {
            guard !buffer.isEmpty else { return }
            blocks.append(.paragraph(buffer.joined(separator: " ")))
            buffer.removeAll()
        }

        var paragraph: [String] = []

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code block
            if trimmed.hasPrefix("```") {
                flushParagraph(&paragraph)
                var code: [String] = []
                i += 1
                while i < lines.count,
                      !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1 // skip closing fence
                blocks.append(.code(code.joined(separator: "\n")))
                continue
            }

            // Blank line ends a paragraph
            if trimmed.isEmpty {
                flushParagraph(&paragraph)
                i += 1
                continue
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph(&paragraph)
                blocks.append(.rule)
                i += 1
                continue
            }

            // Heading
            if let heading = parseHeading(trimmed) {
                flushParagraph(&paragraph)
                blocks.append(heading)
                i += 1
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                flushParagraph(&paragraph)
                var quote: [String] = []
                while i < lines.count {
                    let q = lines[i].trimmingCharacters(in: .whitespaces)
                    guard q.hasPrefix(">") else { break }
                    quote.append(String(q.dropFirst()).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.quote(quote.joined(separator: " ")))
                continue
            }

            // Unordered list
            if isBullet(trimmed) {
                flushParagraph(&paragraph)
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    guard isBullet(t) else { break }
                    items.append(String(t.dropFirst(2)))
                    i += 1
                }
                blocks.append(.bullet(items))
                continue
            }

            // Ordered list
            if let _ = orderedMarker(trimmed) {
                flushParagraph(&paragraph)
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    guard let marker = orderedMarker(t) else { break }
                    items.append(String(t.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.ordered(items))
                continue
            }

            // Default: paragraph text
            paragraph.append(trimmed)
            i += 1
        }

        flushParagraph(&paragraph)
        return blocks
    }

    private static func parseHeading(_ line: String) -> Block? {
        var level = 0
        for ch in line {
            if ch == "#" { level += 1 } else { break }
        }
        guard level > 0, level <= 6 else { return nil }
        let rest = line.dropFirst(level)
        guard rest.first == " " else { return nil }
        return .heading(level: level, text: rest.trimmingCharacters(in: .whitespaces))
    }

    private static func isBullet(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")
    }

    /// Returns the marker prefix (e.g. "1.") if the line is an ordered list item.
    private static func orderedMarker(_ line: String) -> String? {
        var digits = ""
        for ch in line {
            if ch.isNumber { digits.append(ch) } else { break }
        }
        guard !digits.isEmpty else { return nil }
        let after = line.dropFirst(digits.count)
        guard after.first == "." || after.first == ")" else { return nil }
        return digits + String(after.first!)
    }
}
