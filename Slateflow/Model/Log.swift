//
//  Log.swift
//  Slateflow
//
//  Lightweight local-only logging. Mirrors to the unified log (Console.app / `log show`)
//  and appends plain lines to a size-capped text file the user can attach to a GitHub issue.
//  Nothing is ever sent off the machine.
//

import Foundation
import OSLog

nonisolated enum Log {
    /// `~/Library/.../Application Support/Slateflow/Slate.log`
    static let fileURL = SelectionHistory.directoryURL.appendingPathComponent("Slate.log")

    private static let osLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Slateflow",
                                      category: "app")
    private static let queue = DispatchQueue(label: "com.ashifali.Slateflow.log")
    private static let maxBytes = 512 * 1024   // ~500 KB, then truncated

    static func event(_ message: String) {
        let m = redact(message)
        osLog.info("\(m, privacy: .public)")
        append("•", m)
    }

    static func error(_ message: String) {
        let m = redact(message)
        osLog.error("\(m, privacy: .public)")
        append("✗", m)
    }

    /// Strip the macOS account name so a shared log (GitHub issue) doesn't leak it.
    private static func redact(_ message: String) -> String {
        message.replacingOccurrences(of: #"/Users/[^/\s"]+"#, with: "~",
                                     options: .regularExpression)
    }

    private static func append(_ mark: String, _ message: String) {
        let line = "\(Self.stamp())  \(mark) \(message)\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            let fm = FileManager.default
            if let size = (try? fm.attributesOfItem(atPath: fileURL.path)[.size]) as? Int,
               size > maxBytes {
                try? fm.removeItem(at: fileURL)
            }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func stamp() -> String { formatter.string(from: Date()) }
}
