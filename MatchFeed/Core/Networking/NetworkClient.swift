import Foundation

// MARK: - Protocol (enables mock injection in tests)

protocol NetworkClientProtocol {
    func fetch<T: Decodable>(_ endpoint: any Endpoint) async throws -> T
}

// MARK: - URLSession abstraction (for unit-test injection)

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Concrete client

/// Generic async/await networking layer.
/// Marked as `actor` so retry/auth state mutation is race-free.
actor NetworkClient: NetworkClientProtocol {

    static let shared = NetworkClient()

    private let session: any URLSessionProtocol
    private let decoder: JSONDecoder

    init(session: any URLSessionProtocol = URLSession.shared) {
        self.session = session
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = d
    }

    // MARK: - Fetch

    func fetch<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        let request = try endpoint.urlRequest()

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw error  // propagate URLError (no connectivity, timeout, etc.)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.statusCode(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
