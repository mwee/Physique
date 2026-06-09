import Foundation

/// App-wide configuration sourced from the build (Info.plist), never from hardcoded
/// secrets. The Anthropic/LLM API key lives only in the backend proxy; the app knows
/// only the proxy's base URL, supplied at build time via a gitignored `Secrets.xcconfig`.
/// When unset, `coachBaseURL` is nil and the coach falls back to the offline generator.
enum AppConfig {
    static var coachBaseURL: URL? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "COACH_API_BASE_URL") as? String
        else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
}
