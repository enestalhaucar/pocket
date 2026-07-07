import SwiftUI

struct ItemRowView: View {
    let item: Item
    let copied: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onToggleLock: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(item.preview)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .privacySensitive(item.locked)
            }
            Spacer(minLength: 4)

            if copied {
                Label("Kopyalandı", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .labelStyle(.iconOnly)
            } else if hovering {
                actions
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(hovering ? Color.primary.opacity(0.06) : .clear,
                    in: RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: onCopy)
        .help("Tıkla → kopyala")
        .contextMenu {
            Button("Kopyala", action: onCopy)
            Button("Düzenle", action: onEdit)
            Button(item.locked ? "Kasadan çıkar" : "Kasaya taşı", action: onToggleLock)
            Divider()
            Button("Sil", role: .destructive, action: onDelete)
        }
    }

    private var icon: String {
        if item.isFile { return "doc.fill" }
        if item.locked { return "lock.fill" }
        return "text.alignleft"
    }

    private var actions: some View {
        HStack(spacing: 8) {
            iconButton("square.on.square", "Kopyala", onCopy)
            iconButton("pencil", "Düzenle", onEdit)
            iconButton(item.locked ? "lock.open" : "lock", item.locked ? "Kasadan çıkar" : "Kasaya taşı", onToggleLock)
            iconButton("trash", "Sil", onDelete)
        }
        .foregroundStyle(.secondary)
    }

    private func iconButton(_ symbol: String, _ help: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}
