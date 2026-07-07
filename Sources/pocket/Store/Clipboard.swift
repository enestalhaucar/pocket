import AppKit
import UniformTypeIdentifiers

/// Copies items to the system pasteboard.
enum Clipboard {
    static func copy(_ item: Item) {
        let pb = NSPasteboard.general
        pb.clearContents()

        if item.isFile, let data = item.fileData {
            // Write to a temp file and put its URL on the pasteboard so it can be
            // pasted into Finder, Mail, Slack, etc.
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("pocket", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent(item.body.isEmpty ? "file" : item.body)
            do {
                try data.write(to: url, options: .atomic)
                pb.writeObjects([url as NSURL])
            } catch {
                NSLog("pocket: failed to stage file for copy: \(error)")
            }
        } else {
            pb.setString(item.body, forType: .string)
        }
    }
}
