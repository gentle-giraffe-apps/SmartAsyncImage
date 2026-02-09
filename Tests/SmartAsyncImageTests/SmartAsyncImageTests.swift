//  Jonathan Ritchey

import Testing
import Foundation
import UIKit
import SwiftUI
@testable import SmartAsyncImage

// MARK: - Test Helpers (Mock)

actor MockMemoryCache: SmartAsyncImageMemoryCacheProtocol {
    private var cache: [URL: UIImage] = [:]
    private var shouldFail = false
    private var delay: TimeInterval = 0

    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
    }

    func getImage(for url: URL) -> UIImage? {
        return cache[url]
    }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func setDelay(_ value: TimeInterval) {
        delay = value
    }

    func image(for url: URL) async throws -> UIImage {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldFail {
            throw URLError(.badServerResponse)
        }

        guard let image = cache[url] else {
            throw URLError(.resourceUnavailable)
        }

        return image
    }
}

// MARK: - SmartAsyncImageEncoder Tests

@Suite("SmartAsyncImageEncoder Tests")
struct SmartAsyncImageEncoderTests {
    let encoder = SmartAsyncImageEncoder()

    @Test("Encode URL to safe filename string")
    func encodeURLToSafeString() throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let encoded = encoder.encode(url)

        #expect(!encoded.contains("/"))
        #expect(!encoded.contains(":"))
        #expect(!encoded.isEmpty)
    }

    @Test("Decode encoded string back to URL")
    func decodeStringToURL() throws {
        let originalURL = try #require(URL(string: "https://example.com/image.png"))
        let encoded = encoder.encode(originalURL)
        let decoded = encoder.decode(encoded)

        #expect(decoded == originalURL)
    }

    @Test("Encode and decode URL with query parameters")
    func encodeDecodeWithQueryParams() throws {
        let url = try #require(URL(string: "https://example.com/image.png?size=large&format=webp"))
        let encoded = encoder.encode(url)
        let decoded = encoder.decode(encoded)

        #expect(decoded == url)
    }

    @Test("Encode and decode URL with special characters")
    func encodeDecodeWithSpecialChars() throws {
        let url = try #require(URL(string: "https://example.com/path/to/image%20file.png"))
        let encoded = encoder.encode(url)
        let decoded = encoder.decode(encoded)

        #expect(decoded == url)
    }

    @Test("Decode invalid string returns nil")
    func decodeInvalidStringReturnsNil() {
        let decoded = encoder.decode("not a valid url after decoding %%%")
        #expect(decoded == nil)
    }
}

// MARK: - SmartAsyncImageDiskCache Tests

@Suite("SmartAsyncImageDiskCache Tests")
struct SmartAsyncImageDiskCacheTests {

    @Test("Initialize creates cache directory")
    func initCreatesDirectory() throws {
        let fileManager = FileManager.default
        let testFolder = "TestSmartAsyncImageCache_\(UUID().uuidString)"
        let diskCache = SmartAsyncImageDiskCache(fileManager: fileManager, folder: testFolder)

        #expect(fileManager.fileExists(atPath: diskCache.directory.path))

        // Cleanup
        try? fileManager.removeItem(at: diskCache.directory)
    }

    @Test("Save and load image")
    func saveAndLoadImage() async throws {
        let fileManager = FileManager.default
        let testFolder = "TestSmartAsyncImageCache_\(UUID().uuidString)"
        let diskCache = SmartAsyncImageDiskCache(fileManager: fileManager, folder: testFolder)

        let testImage = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
        let testURL = try #require(URL(string: "https://example.com/test-image.png"))

        try await diskCache.save(testImage, key: testURL)
        let loadedImage = try await diskCache.load(key: testURL)

        #expect(loadedImage != nil)
        // Compare pixel dimensions (accounting for scale)
        let originalPixelWidth = testImage.size.width * testImage.scale
        let originalPixelHeight = testImage.size.height * testImage.scale
        let loadedPixelWidth = (loadedImage?.size.width ?? 0) * (loadedImage?.scale ?? 1)
        let loadedPixelHeight = (loadedImage?.size.height ?? 0) * (loadedImage?.scale ?? 1)
        #expect(loadedPixelWidth == originalPixelWidth)
        #expect(loadedPixelHeight == originalPixelHeight)

        // Cleanup
        try? fileManager.removeItem(at: diskCache.directory)
    }

    @Test("Load non-existent image returns nil")
    func loadNonExistentReturnsNil() async throws {
        let fileManager = FileManager.default
        let testFolder = "TestSmartAsyncImageCache_\(UUID().uuidString)"
        let diskCache = SmartAsyncImageDiskCache(fileManager: fileManager, folder: testFolder)

        let testURL = try #require(URL(string: "https://example.com/non-existent.png"))
        let loadedImage = try await diskCache.load(key: testURL)

        #expect(loadedImage == nil)

        // Cleanup
        try? fileManager.removeItem(at: diskCache.directory)
    }

    @Test("Save multiple images with different keys")
    func saveMultipleImages() async throws {
        let fileManager = FileManager.default
        let testFolder = "TestSmartAsyncImageCache_\(UUID().uuidString)"
        let diskCache = SmartAsyncImageDiskCache(fileManager: fileManager, folder: testFolder)

        let image1 = createTestImage(color: .red, size: CGSize(width: 50, height: 50))
        let image2 = createTestImage(color: .blue, size: CGSize(width: 100, height: 100))

        let url1 = try #require(URL(string: "https://example.com/image1.png"))
        let url2 = try #require(URL(string: "https://example.com/image2.png"))

        try await diskCache.save(image1, key: url1)
        try await diskCache.save(image2, key: url2)

        let loaded1 = try await diskCache.load(key: url1)
        let loaded2 = try await diskCache.load(key: url2)

        #expect(loaded1 != nil)
        #expect(loaded2 != nil)
        // Compare pixel dimensions (accounting for scale)
        let pixel1Width = (loaded1?.size.width ?? 0) * (loaded1?.scale ?? 1)
        let pixel2Width = (loaded2?.size.width ?? 0) * (loaded2?.scale ?? 1)
        #expect(pixel1Width == image1.size.width * image1.scale)
        #expect(pixel2Width == image2.size.width * image2.scale)

        // Cleanup
        try? fileManager.removeItem(at: diskCache.directory)
    }
}

// MARK: - SmartAsyncImageMemoryCache Tests (Mock)

@Suite("SmartAsyncImageMemoryCache Mock Tests")
struct SmartAsyncImageMemoryCacheMockTests {

    @Test("Mock Cache returns same image for same URL")
    func mockCacheReturnsSameImage() async throws {
        let mockCache = MockMemoryCache()
        let testURL = try #require(URL(string: "https://example.com/test.png"))
        let testImage = createTestImage(color: .purple, size: CGSize(width: 64, height: 64))

        await mockCache.setImage(testImage, for: testURL)

        let retrieved = try await mockCache.image(for: testURL)
        #expect(retrieved === testImage)
    }

    @Test("Mock Cache miss returns nil from mock")
    func mockCacheMissReturnsNil() async throws {
        let mockCache = MockMemoryCache()
        let testURL = try #require(URL(string: "https://example.com/nonexistent.png"))

        let result = await mockCache.getImage(for: testURL)
        #expect(result == nil)
    }
}

// MARK: - SmartAsyncImageMemoryCache Integration Tests

@Suite("SmartAsyncImageMemoryCache Integration Tests")
struct SmartAsyncImageMemoryCacheIntegrationTests {

    // Use stable, small image URLs for testing
    // Using computed properties with fallbacks to avoid force unwraps
    static var testImageURL: URL {
        URL(string: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") ?? URL(filePath: "/")
    }
    static var smallImageURL: URL {
        URL(string: "https://www.google.com/favicon.ico") ?? URL(filePath: "/")
    }
    static var anotherImageURL: URL {
        URL(string: "https://www.apple.com/favicon.ico") ?? URL(filePath: "/")
    }

    /// Creates an isolated cache instance with its own disk cache folder
    func createIsolatedCache() -> (cache: SmartAsyncImageMemoryCache, diskCache: SmartAsyncImageDiskCache, folder: String) {
        let folder = "TestSmartAsyncImageCache_\(UUID().uuidString)"
        let diskCache = SmartAsyncImageDiskCache(fileManager: .default, folder: folder)
        let cache = SmartAsyncImageMemoryCache(diskCache: diskCache)
        return (cache, diskCache, folder)
    }

    /// Cleans up the test disk cache folder
    func cleanup(folder: String) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = cacheDir.appendingPathComponent(folder)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test("Fetch image from network successfully")
    func fetchImageFromNetwork() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        let image = try await cache.image(for: Self.testImageURL)

        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }

    @Test("Memory cache returns cached image on second fetch")
    func memoryCacheReturnsCachedImage() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        // First fetch - should hit network
        let hasCachedBefore = await cache.hasCachedImage(for: Self.testImageURL)
        #expect(!hasCachedBefore)

        let image1 = try await cache.image(for: Self.testImageURL)

        // Verify it's now in memory cache
        let hasCachedAfter = await cache.hasCachedImage(for: Self.testImageURL)
        #expect(hasCachedAfter)

        // Second fetch - should return from memory cache
        let image2 = try await cache.image(for: Self.testImageURL)

        // Both images should have the same dimensions
        #expect(image1.size == image2.size)
    }

    @Test("Clear memory cache removes cached images")
    func clearMemoryCacheRemovesImages() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        // Fetch and cache an image
        _ = try await cache.image(for: Self.testImageURL)

        // Verify it's in cache
        let hasCachedBefore = await cache.hasCachedImage(for: Self.testImageURL)
        #expect(hasCachedBefore)

        // Clear the cache
        await cache.clearMemoryCache()

        // Verify it's no longer in memory cache
        let hasCachedAfter = await cache.hasCachedImage(for: Self.testImageURL)
        #expect(!hasCachedAfter)
    }

    @Test("Task coalescing: concurrent requests share single network call")
    func taskCoalescingSharesNetworkCall() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        // Use same URL to test coalescing
        let testURL = Self.smallImageURL

        // Launch multiple concurrent requests for the same URL
        async let image1 = cache.image(for: testURL)
        async let image2 = cache.image(for: testURL)
        async let image3 = cache.image(for: testURL)

        // All should succeed and return images
        let results = try await [image1, image2, image3]

        // All images should be valid
        for image in results {
            #expect(image.size.width > 0)
            #expect(image.size.height > 0)
        }

        // All images should have the same size (they're the same image)
        #expect(results[0].size == results[1].size)
        #expect(results[1].size == results[2].size)
    }

    @Test("Inflight request count is zero when idle")
    func inflightRequestCountZeroWhenIdle() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        let inflightRequestCount = await cache.inflightRequestCount
        #expect(inflightRequestCount == 0)
    }

    @Test("Disk cache persists image after memory cache clear")
    func diskCachePersistsImage() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        // Use the small image URL
        let testURL = Self.smallImageURL

        // Fetch image (goes to network, saves to disk)
        let originalImage = try await cache.image(for: testURL)

        // Wait a moment for disk save to complete (it's detached)
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Clear memory cache
        await cache.clearMemoryCache()

        // Verify memory cache is clear
        let hasCached = await cache.hasCachedImage(for: testURL)
        #expect(!hasCached)

        // Fetch again - should come from disk cache
        let cachedImage = try await cache.image(for: testURL)

        // Should have the same dimensions
        #expect(cachedImage.size.width == originalImage.size.width)
        #expect(cachedImage.size.height == originalImage.size.height)
    }

    @Test("Invalid URL throws error")
    func invalidURLThrowsError() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        // This URL returns a 404
        let invalidURL = try #require(URL(string: "https://httpstat.us/404"))

        do {
            _ = try await cache.image(for: invalidURL)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            // Expected - should throw an error
            #expect(Bool(true))
        }
    }

    @Test("Non-image URL throws error")
    func nonImageURLThrowsError() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        // This returns JSON, not an image
        let jsonURL = try #require(URL(string: "https://httpbin.org/json"))

        do {
            _ = try await cache.image(for: jsonURL)
            #expect(Bool(false), "Expected error to be thrown for non-image data")
        } catch {
            // Expected - should throw an error because data is not a valid image
            #expect(Bool(true))
        }
    }

    @Test("Multiple different URLs are cached independently")
    func multipleDifferentURLsCachedIndependently() async throws {
        let (cache, _, folder) = createIsolatedCache()
        defer { cleanup(folder: folder) }

        let url1 = Self.smallImageURL
        let url2 = Self.anotherImageURL

        // Fetch both
        let image1 = try await cache.image(for: url1)
        let image2 = try await cache.image(for: url2)

        // Both should be cached
        let hasCached1 = await cache.hasCachedImage(for: url1)
        let hasCached2 = await cache.hasCachedImage(for: url2)

        #expect(hasCached1)
        #expect(hasCached2)

        // Both images should have dimensions (they're different favicons but both valid)
        #expect(image1.size.width > 0)
        #expect(image2.size.width > 0)
    }

// todo: failing on github actions
//    @Test("Cache with custom URLSession works")
//    func cacheWithCustomURLSessionWorks() async throws {
//        let folder = "TestSmartAsyncImageCache_\(UUID().uuidString)"
//        let diskCache = SmartAsyncImageDiskCache(fileManager: .default, folder: folder)
//
//        // Create a custom URLSession with a short timeout
//        let config = URLSessionConfiguration.default
//        config.timeoutIntervalForRequest = 30
//        let customSession = URLSession(configuration: config)
//
//        let cache = SmartAsyncImageMemoryCache(diskCache: diskCache, urlSession: customSession)
//        defer { cleanup(folder: folder) }
//
//        let image = try await cache.image(for: Self.testImageURL)
//        #expect(image.size.width > 0)
//    }
}

// MARK: - SmartAsyncImageViewModel Tests

@Suite("SmartAsyncImageViewModel Tests")
@MainActor
struct SmartAsyncImageViewModelTests {

    @Test("Initial phase is empty")
    func initialPhaseIsEmpty() throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let mockCache = MockMemoryCache()
        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)

        if case .empty = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .empty")
        }
    }

    @Test("Load transitions to loading phase")
    func loadTransitionsToLoading() async throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let mockCache = MockMemoryCache()
        await mockCache.setDelay(1.0) // Add delay to catch loading state

        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)
        viewModel.load()

        // Give a tiny moment for the state to update
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        if case .loading = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .loading")
        }

        viewModel.cancel()
    }

    @Test("Load succeeds with cached image")
    func loadSucceedsWithCachedImage() async throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let mockCache = MockMemoryCache()
        let testImage = createTestImage(color: .cyan, size: CGSize(width: 32, height: 32))
        await mockCache.setImage(testImage, for: url)

        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)
        viewModel.load()

        // Wait for async load to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        if case .success = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .success")
        }
    }

    @Test("Load fails with error")
    func loadFailsWithError() async throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let mockCache = MockMemoryCache()
        await mockCache.setShouldFail(true)

        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)
        viewModel.load()

        // Wait for async load to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        if case .failure = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .failure")
        }
    }

    @Test("Cancel resets phase to empty")
    func cancelResetsPhaseToEmpty() async throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let mockCache = MockMemoryCache()
        await mockCache.setDelay(5.0) // Long delay

        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)
        viewModel.load()

        // Wait a bit then cancel
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        viewModel.cancel()

        if case .empty = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .empty after cancel")
        }
    }

    @Test("Multiple loads are ignored if not empty")
    func multipleLoadsIgnored() async throws {
        let url = try #require(URL(string: "https://example.com/image.png"))
        let mockCache = MockMemoryCache()
        await mockCache.setDelay(0.5)

        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)
        viewModel.load()
        viewModel.load() // Second call should be ignored
        viewModel.load() // Third call should be ignored

        // Check that phase moved to loading (not reset)
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        if case .loading = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .loading")
        }

        viewModel.cancel()
    }
}

// MARK: - SmartAsyncImagePhase Tests

@Suite("SmartAsyncImagePhase Tests")
struct SmartAsyncImagePhaseTests {

    @Test("Phase empty case")
    func phaseEmpty() {
        let phase: SmartAsyncImagePhase = .empty
        if case .empty = phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Phase loading case")
    func phaseLoading() {
        let phase: SmartAsyncImagePhase = .loading
        if case .loading = phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Phase success case")
    func phaseSuccess() {
        let image = Image(systemName: "photo")
        let phase: SmartAsyncImagePhase = .success(image)
        if case .success = phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Phase failure case")
    func phaseFailure() {
        let error = URLError(.badURL)
        let phase: SmartAsyncImagePhase = .failure(error)
        if case .failure(let e) = phase {
            #expect((e as? URLError)?.code == .badURL)
        } else {
            #expect(Bool(false))
        }
    }
}

// MARK: - Test Helpers

func createTestImage(color: UIColor, size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}
