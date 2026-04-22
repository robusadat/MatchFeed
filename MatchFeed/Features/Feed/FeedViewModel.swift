import Foundation
import Observation

// MARK: - Swipe Direction

enum SwipeDirection { case like, pass }

// MARK: - ViewModel

/// Feed ViewModel using the Swift 5.9 @Observable macro.
/// No @Published needed — any property read inside a SwiftUI body
/// automatically creates a fine-grained dependency.
@Observable
final class FeedViewModel {

    // MARK: - State (observed by the view)
    var profiles:     [UserProfile] = []
    var isLoading:    Bool = false
    var errorMessage: String?

    // MARK: - Private cursor state
    private var currentPage  = 1
    private var canLoadMore  = true
    private let pageSize     = 10

    // MARK: - Dependencies
    private let network: any NetworkClientProtocol

    init(network: any NetworkClientProtocol = NetworkClient.shared) {
        self.network = network
    }

    // MARK: - Intents (called from the View / ViewController)

    /// Load the first page, resetting any previous state.
    func loadInitial() async {
        guard !isLoading else { return }
        currentPage = 1
        canLoadMore = true
        profiles    = []
        await fetchNextPage()
    }

    /// Called for each visible cell — triggers a fetch when near the end.
    func loadMoreIfNeeded(currentIndex: Int) async {
        let triggerIndex = profiles.count - 4   // start fetching 4 items before the end
        guard currentIndex >= triggerIndex, !isLoading, canLoadMore else { return }
        await fetchNextPage()
    }

    /// Optimistic swipe: remove locally first, then sync with server.
    func swipe(profile: UserProfile, direction: SwipeDirection) async {
        profiles.removeAll { $0.id == profile.id }
        // TODO: POST /swipe { userId: profile.id, direction: direction } to your backend
    }

    // MARK: - Private

    private func fetchNextPage() async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: UserResponse = try await network.fetch(
                RandomUserEndpoint.fetchUsers(page: currentPage, results: pageSize)
            )
            let newProfiles = response.results.map(UserProfile.init)
            profiles.append(contentsOf: newProfiles)
            currentPage += 1
            canLoadMore  = newProfiles.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
