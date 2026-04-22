import UIKit

// MARK: - Protocol

protocol ImageCacheProtocol {
    func image(for url: URL) async -> UIImage?
    func store(_ image: UIImage, for url: URL) async
    func loadOrFetch(url: URL) async -> UIImage?
}

// MARK: - Two-tier actor cache (memory + disk)

/// Thread-safe image cache backed by NSCache (memory) and the Caches directory (disk).
/// Marked `actor` so all mutations are serialised — no locks, no data races.
actor ImageCache: ImageCacheProtocol {

    static let shared = ImageCache()

    // Memory tier
    private let memoryCache = NSCache<NSURL, UIImage>()

    // Disk tier
    private let fileManager = FileManager.default
    private lazy var diskCacheURL: URL = {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("MatchFeed.ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Init

    init(memoryLimitBytes: Int = 50 * 1024 * 1024) {
        memoryCache.totalCostLimit = memoryLimitBytes
    }

    // MARK: - Public API

    func image(for url: URL) async -> UIImage? {
        // 1. Memory hit (fast path)
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }
        // 2. Disk hit (slower but still avoids a network round-trip)
        let path = diskPath(for: url)
        guard
            let data  = try? Data(contentsOf: path),
            let image = UIImage(data: data)
        else { return nil }

        // Promote to memory so next hit is instant
        memoryCache.setObject(image, forKey: url as NSURL, cost: data.count)
        return image
    }

    func store(_ image: UIImage, for url: URL) async {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        memoryCache.setObject(image, forKey: url as NSURL, cost: data.count)
        try? data.write(to: diskPath(for: url), options: .atomic)
    }

    /// Returns a cached image if available, otherwise fetches, stores, and returns it.
    func loadOrFetch(url: URL) async -> UIImage? {
        if let cached = await image(for: url) { return cached }
        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let image = UIImage(data: data)
        else { return nil }
        await store(image, for: url)
        return image
    }

    // MARK: - Private

    private func diskPath(for url: URL) -> URL {
        // Percent-encode the full URL string to create a safe filename
        let safe = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics)
            ?? url.lastPathComponent
        return diskCacheURL.appendingPathComponent(safe)
    }
}
