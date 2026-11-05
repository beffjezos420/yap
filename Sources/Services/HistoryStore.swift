import Foundation
import SwiftData

/// Behind a protocol so the coordinator can be unit-tested with a fake.
@MainActor
protocol HistoryStoring: AnyObject {
    func save(text: String, duration: Double?, device: String?)
}

extension HistoryStoring {
    /// The latest saved transcript, for the menu bar's quick copy. Optional so
    /// test fakes stay unchanged.
    func mostRecent() -> Transcript? {
        (self as? HistoryStore)?.recent(limit: 1).first
    }

    /// Whether any transcript has been recorded, so menu-bar actions can enable
    /// themselves. Optional so test fakes stay unchanged.
    func hasAnyTranscript() -> Bool {
        (self as? HistoryStore)?.recent(limit: 1).isEmpty == false
    }

    /// Every saved transcript, newest first. Optional so test fakes stay unchanged.
    func allTranscripts() -> [Transcript] {
        (self as? HistoryStore)?.recent() ?? []
    }
}

@MainActor
final class HistoryStore: HistoryStoring {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(text: String, duration: Double?, device: String?) {
        let transcript = Transcript(text: text, durationSeconds: duration, inputDeviceName: device)
        context.insert(transcript)
        try? context.save()
    }

    func recent(limit: Int? = nil) -> [Transcript] {
        var descriptor = FetchDescriptor<Transcript>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(_ transcript: Transcript) {
        context.delete(transcript)
        try? context.save()
    }

    func clearAll() {
        for transcript in recent() {
            context.delete(transcript)
        }
        try? context.save()
    }
}
