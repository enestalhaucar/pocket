import Foundation

/// A single stored entry in pocket.
struct Item: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case text   // snippet, note, anything copyable
        case file   // an arbitrary file kept inside the vault store
    }

    var id: UUID = UUID()
    var title: String
    var kind: Kind = .text

    /// For `.text` items this is the copyable content.
    /// For `.file` items this is the original file name (e.g. "key.pem").
    var body: String = ""

    /// Raw bytes for `.file` items. Always nil for `.text`.
    var fileData: Data? = nil

    /// When true the item lives in the Kasa (vault) and needs Touch ID to reveal.
    var locked: Bool = false

    /// Pinned items sort to the top of their list.
    var pinned: Bool = false

    /// Frecency: how often and how recently this item was copied.
    var useCount: Int = 0
    var lastUsedAt: Date? = nil

    var createdAt: Date = Date()

    var isFile: Bool { kind == .file }

    /// A short, single-line preview used in the list.
    var preview: String {
        if isFile { return body }
        let firstLine = body.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        return firstLine.isEmpty ? body : firstLine
    }
}
