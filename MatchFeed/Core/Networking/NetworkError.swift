import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Invalid URL"
        case .invalidResponse:       return "Invalid server response"
        case .statusCode(let code):  return "Server error: HTTP \(code)"
        case .decodingFailed(let e): return "Decoding failed: \(e.localizedDescription)"
        }
    }
}
