import Foundation

/// Caller-supplied monotonic time makes timeout and cycling deterministic.
public struct Typeahead: Sendable {
    public private(set) var query = ""
    public let timeout: TimeInterval
    private var lastTime: TimeInterval?

    public init(timeout: TimeInterval = 0.5) {
        precondition(timeout.isFinite && timeout > 0)
        self.timeout = timeout
    }

    public mutating func reset() { query = ""; lastTime = nil }

    public mutating func search(_ text: String, labels: [String], current: Int? = nil,
                                at time: TimeInterval, locale: Locale = .current) -> Int? {
        guard time.isFinite, !text.isEmpty else { return nil }
        if let lastTime, time - lastTime >= timeout || time < lastTime { query = "" }
        lastTime = time
        let fold: (String) -> String = {
            $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let character = fold(text)
        guard !character.isEmpty, !labels.isEmpty else { return nil }
        query += character
        func scan(_ prefix: String, start: Int) -> Int? {
            for offset in labels.indices {
                let index = ((start % labels.count) + labels.count + offset) % labels.count
                if fold(labels[index]).hasPrefix(prefix) { return index }
            }
            return nil
        }
        let start = query.count == 1 ? (current ?? -1) + 1 : max(current ?? 0, 0)
        if let match = scan(query, start: start) { return match }
        if query.allSatisfy({ String($0) == character }) {
            query = character
            return scan(character, start: (current ?? -1) + 1)
        }
        return nil
    }
}
