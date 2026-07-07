import SwiftUI
import UniformTypeIdentifiers

struct EditItemView: View {
    @EnvironmentObject private var store: Store

    let existing: Item?
    let onDone: () -> Void

    @State private var title: String
    @State private var body_: String
    @State private var locked: Bool
    @State private var fileData: Data?
    @State private var fileName: String
    @State private var isFile: Bool

    init(item: Item?, startLocked: Bool, onDone: @escaping () -> Void) {
        self.existing = item
        self.onDone = onDone
        _title = State(initialValue: item?.title ?? "")
        _body_ = State(initialValue: item?.isFile == true ? "" : (item?.body ?? ""))
        _locked = State(initialValue: item?.locked ?? startLocked)
        _fileData = State(initialValue: item?.fileData)
        _fileName = State(initialValue: item?.isFile == true ? (item?.body ?? "") : "")
        _isFile = State(initialValue: item?.isFile ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDone) {
                    Image(systemName: "chevron.left")
                    Text("Geri")
                }
                .buttonStyle(.borderless)
                Spacer()
                Text(existing == nil ? "Yeni öğe" : "Düzenle")
                    .font(.headline)
                Spacer()
                Button("Kaydet", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
            .padding(12)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    field("Başlık") {
                        TextField("örn. Ev adresi, IBAN, API key", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    if isFile {
                        field("Dosya") {
                            HStack {
                                Image(systemName: "doc.fill").foregroundStyle(.secondary)
                                Text(fileName.isEmpty ? "Dosya seçilmedi" : fileName)
                                    .lineLimit(1)
                                Spacer()
                                Button("Seç…", action: pickFile)
                            }
                        }
                    } else {
                        field("İçerik") {
                            TextEditor(text: $body_)
                                .frame(height: 96)
                                .font(.system(size: 13, design: .monospaced))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3)))
                        }
                    }

                    if existing == nil {
                        Toggle(isOn: $isFile) {
                            Label("Bunun yerine dosya ekle", systemImage: "paperclip")
                        }
                        .onChange(of: isFile) { _, on in if on { pickFile() } }
                    }

                    Toggle(isOn: $locked) {
                        Label("Kasada tut (\(Biometrics.label) ile kilitli)", systemImage: "lock.fill")
                    }

                    if existing != nil {
                        Button(role: .destructive) {
                            if let e = existing { store.delete(e) }
                            onDone()
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(12)
            }
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return isFile ? fileData != nil : !body_.isEmpty
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else {
            if fileData == nil { isFile = false }
            return
        }
        fileData = try? Data(contentsOf: url)
        fileName = url.lastPathComponent
        if title.isEmpty { title = url.lastPathComponent }
        isFile = fileData != nil
    }

    private func save() {
        var item = existing ?? Item(title: "")
        item.title = title.trimmingCharacters(in: .whitespaces)
        item.locked = locked
        if isFile {
            item.kind = .file
            item.body = fileName
            item.fileData = fileData
        } else {
            item.kind = .text
            item.body = body_
            item.fileData = nil
        }
        if existing == nil {
            store.add(item)
        } else {
            store.update(item)
        }
        onDone()
    }
}
