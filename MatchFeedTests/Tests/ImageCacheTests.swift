import XCTest
@testable import MatchFeed

final class ImageCacheTests: XCTestCase {

    private var cache: ImageCache!

    override func setUp() async throws {
        try await super.setUp()
        cache = ImageCache(memoryLimitBytes: 10 * 1024 * 1024)  // 10 MB for tests
    }

    override func tearDown() async throws {
        cache = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func test_storeAndRetrieve_fromMemory() async {
        let url   = URL(string: "https://example.com/test.jpg")!
        let image = UIImage(systemName: "person.fill")!

        await cache.store(image, for: url)
        let retrieved = await cache.image(for: url)

        XCTAssertNotNil(retrieved)
    }

    func test_retrieveUnknownURL_returnsNil() async {
        let url = URL(string: "https://example.com/unknown-\(UUID()).jpg")!
        let result = await cache.image(for: url)
        XCTAssertNil(result)
    }

    func test_storeTwice_doesNotCrash() async {
        let url   = URL(string: "https://example.com/double.jpg")!
        let image = UIImage(systemName: "star.fill")!

        await cache.store(image, for: url)
        await cache.store(image, for: url)  // should overwrite cleanly

        let result = await cache.image(for: url)
        XCTAssertNotNil(result)
    }
}
