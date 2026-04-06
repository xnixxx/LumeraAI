import Foundation

// MARK: - API Client

final class APIClient {
    private let baseURL: URL
    private var accessToken: String?
    private let session: URLSession

    init(baseURLString: String = "https://api.lumera.ai/v1") {
        self.baseURL = URL(string: baseURLString)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    func setToken(_ token: String) {
        accessToken = token
    }

    func post<B: Encodable>(_ path: String, body: B) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError
        }
    }

    func get<R: Decodable>(_ path: String) async throws -> R {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError
        }
        return try JSONDecoder().decode(R.self, from: data)
    }

    enum APIError: Error {
        case serverError
        case decodingError
        case unauthorized
    }
}
