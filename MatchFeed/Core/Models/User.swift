import Foundation

// MARK: - API Response Models (Codable — maps directly to randomuser.me JSON)

struct UserResponse: Codable {
    let results: [RemoteUser]
    let info: PageInfo
}

struct RemoteUser: Codable {
    let login:    Login
    let name:     Name
    let dob:      Dob
    let location: Location
    let picture:  Picture
    let email: String
    let gender: String

    struct Login:    Codable { let uuid: String }
    struct Name:     Codable { let first: String; let last: String }
    struct Dob:      Codable { let age: Int }
    struct Location: Codable { let city: String; let country: String }
    struct Picture:  Codable { let large: String; let medium: String; let thumbnail: String }
}

struct PageInfo: Codable {
    let seed: String
    let results: Int
    let page: Int
}

// MARK: - Domain Model

/// Clean domain model — no Codable dependency, no framework imports.
struct UserProfile: Identifiable, Hashable {
    let id: String          // login.uuid — stable across pages (same seed)
    let firstName: String
    let lastName: String
    let age: Int
    let city: String
    let country: String
    let photoURL: URL?
    let thumbnailURL: URL?
    let email: String
    let gender: String

    var displayName: String { "\(firstName), \(age)" }
    var location:    String { "\(city), \(country)" }
}

// MARK: - Mapping

extension UserProfile {
    /// Maps a raw API object to a clean domain model.
    init(remote: RemoteUser) {
        self.id          = remote.login.uuid
        self.firstName   = remote.name.first.capitalized
        self.lastName    = remote.name.last.capitalized
        self.age         = remote.dob.age
        self.city        = remote.location.city
        self.country     = remote.location.country
        self.email  = remote.email
        self.gender = remote.gender
        self.photoURL    = URL(string: remote.picture.large)
        self.thumbnailURL = URL(string: remote.picture.thumbnail)
    }
}
