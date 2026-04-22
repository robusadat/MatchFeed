import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get  = "GET"
    case post = "POST"
}

// MARK: - Endpoint Protocol

protocol Endpoint {
    var baseURL: URL     { get }
    var path: String     { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var body: Data?      { get }
}

extension Endpoint {
    var body: Data? { nil }

    func urlRequest() throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody   = body
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}

// MARK: - randomuser.me Endpoints

enum RandomUserEndpoint: Endpoint {
    case fetchUsers(page: Int, results: Int = 10, seed: String = "matchfeed")

    var baseURL: URL { URL(string: "https://randomuser.me")! }
    var path: String { "/api/" }
    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .fetchUsers(page, results, seed):
            return [
                URLQueryItem(name: "page",    value: "\(page)"),
                URLQueryItem(name: "results", value: "\(results)"),
                URLQueryItem(name: "seed",    value: seed),
            ]
        }
    }
}
