import Foundation

/// One captured clipboard entry (the "Geçmiş" tab).
struct ClipEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var capturedAt: Date = Date()

    var preview: String {
        let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        return line.trimmingCharacters(in: .whitespaces)
    }
}

/// The full on-disk payload, encrypted as a single blob.
struct StoreData: Codable {
    var items: [Item] = []
    var history: [ClipEntry] = []
}
