import SwiftUI

struct ItemRowView: View {
    let item: Item
    let selected: Bool
    let copied: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onTogglePin: () -> Void
    let onToggleLock: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(item.pinned ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    if item.pinned {
                        Image(systemName: "pin.fill").font(.system(size: 9)).foregroundStyle(.tint)
                    }
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                }
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
        .background(background, in: RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: onCopy)
        .help("Tıkla → kopyala")
        .contextMenu {
            Button("Kopyala", action: onCopy)
            Button("Düzenle", action: onEdit)
            Button(item.pinned ? "Sabitlemeyi kaldır" : "Sabitle", action: onTogglePin)
            Button(item.locked ? "Kasadan çıkar" : "Kasaya taşı", action: onToggleLock)
            Divider()
            Button("Sil", role: .destructive, action: onDelete)
        }
    }

    private var background: AnyShapeStyle {
        if selected { return AnyShapeStyle(Color.accentColor.opacity(0.18)) }
        if hovering { return AnyShapeStyle(Color.primary.opacity(0.06)) }
        return AnyShapeStyle(Color.clear)
    }

    private var icon: String {
        if item.isFile { return "doc.fill" }
        if item.locked { return "lock.fill" }
        return "text.alignleft"
    }

    private var actions: some View {
        HStack(spacing: 8) {
            iconButton("square.on.square", "Kopyala", onCopy)
            iconButton(item.pinned ? "pin.slash" : "pin", item.pinned ? "Sabitlemeyi kaldır" : "Sabitle", onTogglePin)
            iconButton("pencil", "Düzenle", onEdit)
            iconButton("trash", "Sil", onDelete)
        }
        .foregroundStyle(.secondary)
    }

    private func iconButton(_ symbol: String, _ help: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(.borderless)
            .help(help)
    }
}

struct HistoryRowView: View {
    let entry: ClipEntry
    let selected: Bool
    let copied: Bool
    let onCopy: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(entry.preview)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer(minLength: 4)

            if copied {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else if hovering {
                HStack(spacing: 8) {
                    button("tray.and.arrow.down", "Kaydet", onSave)
                    button("xmark", "Sil", onDelete)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(background, in: RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(perform: onCopy)
        .help("Tıkla → kopyala")
        .contextMenu {
            Button("Kopyala", action: onCopy)
            Button("Kalıcıya kaydet", action: onSave)
            Divider()
            Button("Sil", role: .destructive, action: onDelete)
        }
    }

    private var background: AnyShapeStyle {
        if selected { return AnyShapeStyle(Color.accentColor.opacity(0.18)) }
        if hovering { return AnyShapeStyle(Color.primary.opacity(0.06)) }
        return AnyShapeStyle(Color.clear)
    }

    private func button(_ symbol: String, _ help: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(.borderless)
            .help(help)
    }
}
