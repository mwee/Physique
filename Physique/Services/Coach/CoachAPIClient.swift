import Foundation

enum CoachAPIError: Error {
    case notConfigured   // no proxy URL set — fall back
    case network(Error)
    case badResponse(Int)
    case decoding(Error)
}

/// Thin transport to the backend proxy that holds the Anthropic key. This file never
/// sees an API key — it only knows the proxy URL from `AppConfig`.
struct CoachAPIClient {
    /// POST a JSON body to a proxy path, return the raw response text (assistant message).
    func post(path: String, body: [String: Any]) async throws -> String {
        guard let base = AppConfig.coachBaseURL else {
            throw CoachAPIError.notConfigured
        }

        let url = base.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CoachAPIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CoachAPIError.badResponse(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoachAPIError.badResponse(http.statusCode)
        }

        // Proxy returns { "text": "<assistant message>" }; fall back to raw UTF-8.
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = obj["text"] as? String {
            return text
        }
        return String(decoding: data, as: UTF8.self)
    }
}
