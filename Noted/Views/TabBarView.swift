import SwiftUI

struct TabBarView: View {
    @EnvironmentObject private var store: NoteStore

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<NoteStore.tabCount, id: \.self) { index in
                dot(for: index)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func dot(for index: Int) -> some View {
        let isSelected = index == store.selectedIndex
        return Circle()
            .fill(TabColor.color(at: index))
            .frame(width: 13, height: 13)
            .overlay {
                Circle()
                    .strokeBorder(.primary.opacity(isSelected ? 0.55 : 0), lineWidth: 1.5)
                    .padding(-3)
            }
            .opacity(isSelected ? 1 : 0.5)
            .scaleEffect(isSelected ? 1.0 : 0.85)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            .contentShape(Rectangle())
            .onTapGesture { store.selectedIndex = index }
            .help("Tab \(index + 1)  (⌘\((index + 1) % 10))")
    }
}
