import XCTest
@testable import MatchFeed

// MARK: - FeedViewModelTests

final class FeedViewModelTests: XCTestCase {

    private var sut: FeedViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = FeedViewModel(network: MockNetworkClient(fixture: .successTen))
    }

    override func tearDown() async throws {
        // Memory leak check: the SUT should deallocate when we nil it out
        weak var weakSUT: FeedViewModel? = sut
        sut = nil
        XCTAssertNil(weakSUT, "Memory leak — FeedViewModel was not deallocated")
        try await super.tearDown()
    }

    // MARK: - Happy path

    func test_loadInitial_populatesProfiles() async {
        await sut.loadInitial()

        XCTAssertEqual(sut.profiles.count, 10)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadInitial_setsCorrectDisplayName() async {
        await sut.loadInitial()

        let first = try! XCTUnwrap(sut.profiles.first)
        XCTAssertEqual(first.displayName, "User, 25")
    }

    // MARK: - Error path

    func test_loadInitial_onNetworkError_setsErrorMessage() async {
        sut = FeedViewModel(network: MockNetworkClient(fixture: .failure))
        await sut.loadInitial()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.profiles.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Swipe

    func test_swipe_removesProfileOptimistically() async {
        await sut.loadInitial()
        let target = sut.profiles[0]

        await sut.swipe(profile: target, direction: .like)

        XCTAssertFalse(sut.profiles.contains(target))
    }

    // MARK: - Pagination guard

    func test_loadMoreIfNeeded_doesNotFetch_whenAlreadyLoading() async {
        // loadInitial is running; a concurrent call should be a no-op
        let task1 = Task { await self.sut.loadInitial() }
        let task2 = Task { await self.sut.loadMoreIfNeeded(currentIndex: 8) }
        await task1.value
        await task2.value
        // Should still only have 10 (one page), not 20
        XCTAssertEqual(sut.profiles.count, 10)
    }
}

// MARK: - Mock Network

enum NetworkFixture { case successTen, failure }

actor MockNetworkClient: NetworkClientProtocol {

    let fixture: NetworkFixture
    init(fixture: NetworkFixture) { self.fixture = fixture }

    func fetch<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        switch fixture {
        case .failure:
            throw NetworkError.statusCode(500)

        case .successTen:
            let users: [RemoteUser] = (0..<10).map { i in
                RemoteUser(
                    login:    .init(uuid: "uuid-\(i)"),
                    name:     .init(first: "User",  last: "\(i)"),
                    dob:      .init(age: 25),
                    location: .init(city: "NYC", country: "US"),
                    picture:  .init(large: "", medium: "", thumbnail: "")
                )
            }
            let response = UserResponse(
                results: users,
                info: PageInfo(seed: "test", results: 10, page: 1)
            )
            // Safe cast — tests always call fetch expecting UserResponse
            guard let typed = response as? T else {
                throw NetworkError.decodingFailed(
                    NSError(domain: "MockCast", code: -1)
                )
            }
            return typed
        }
    }
}
