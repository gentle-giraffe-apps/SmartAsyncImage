//  Jonathan Ritchey

import Testing
import Foundation
import UIKit
import SwiftUI
@testable import SmartAsyncImage

// MARK: - SmartAsyncImageEncoder Tests

@Suite("SmartAsyncImageEncoder Tests")
struct SmartAsyncImageEncoderTests {
    let encoder = SmartAsyncImageEncoder()

    @Test("Encode URL to safe filename string")
    func encodeURLToSafeString() {
        let url = URL(string: "https://example.com/image.png")!
        let encoded = encoder.encode(url)

        #expect(!encoded.contains("/"))
        #expect(!encoded.contains(":"))
        #expect(!encoded.isEmpty)
    }

    @Test("Decode encoded string back to URL")
    func decodeStringToURL() {
        let originalURL = URL(string: "https://example.com/image.png")!
        let encoded = encoder.encode(originalURL)
        let decoded = encoder.decode(encoded)

        #expect(decoded == originalURL)
    }

    @Test("Encode and decode URL with query parameters")
    func encodeDecodeWithQueryParams() {
        let url = URL(string: "https://example.com/image.png?size=large&format=webp")!
        let encoded = encoder.encode(url)
        let decoded = encoder.decode(encoded)

        #expect(decoded == url)
    }

    @Test("Encode and decode URL with special characters")
    func encodeDecodeWithSpecialChars() {
        let url = URL(string: "https://example.com/path/to/image%20file.png")!
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
        let testURL = URL(string: "https://example.com/test-image.png")!

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

        let testURL = URL(string: "https://example.com/non-existent.png")!
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

        let url1 = URL(string: "https://example.com/image1.png")!
        let url2 = URL(string: "https://example.com/image2.png")!

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

// MARK: - SmartAsyncImageMemoryCache Tests

@Suite("SmartAsyncImageMemoryCache Tests")
struct SmartAsyncImageMemoryCacheTests {

    @Test("Cache returns same image for same URL")
    func cacheReturnsSameImage() async throws {
        let mockCache = MockMemoryCache()
        let testURL = URL(string: "https://example.com/test.png")!
        let testImage = createTestImage(color: .purple, size: CGSize(width: 64, height: 64))

        await mockCache.setImage(testImage, for: testURL)

        let retrieved = try await mockCache.image(for: testURL)
        #expect(retrieved === testImage)
    }

    @Test("Cache miss returns nil from mock")
    func cacheMissReturnsNil() async {
        let mockCache = MockMemoryCache()
        let testURL = URL(string: "https://example.com/nonexistent.png")!

        let result = await mockCache.getImage(for: testURL)
        #expect(result == nil)
    }
}

// MARK: - SmartAsyncImageViewModel Tests

@Suite("SmartAsyncImageViewModel Tests")
@MainActor
struct SmartAsyncImageViewModelTests {

    @Test("Initial phase is empty")
    func initialPhaseIsEmpty() {
        let url = URL(string: "https://example.com/image.png")!
        let mockCache = MockMemoryCache()
        let viewModel = SmartAsyncImageViewModel(url: url, cache: mockCache)

        if case .empty = viewModel.phase {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected phase to be .empty")
        }
    }

    @Test("Load transitions to loading phase")
    func loadTransitionsToLoading() async {
        let url = URL(string: "https://example.com/image.png")!
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
        let url = URL(string: "https://example.com/image.png")!
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
        let url = URL(string: "https://example.com/image.png")!
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
        let url = URL(string: "https://example.com/image.png")!
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
        let url = URL(string: "https://example.com/image.png")!
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
