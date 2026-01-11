//  Jonathan Ritchey

import Foundation
import SwiftUI
import UIKit

public protocol SmartAsyncImageMemoryCacheProtocol {
    func image(for url: URL) async throws -> UIImage
}

// Image Manager that fetches images from url's and stores the result in cache, and persists it to disk.
public actor SmartAsyncImageMemoryCache: SmartAsyncImageMemoryCacheProtocol {
    public static let shared = SmartAsyncImageMemoryCache()
    private let cache = NSCache<NSURL, UIImage>() // NSCache is thread safe.
    private let diskCache: SmartAsyncImageDiskCache
    private let encoder: SmartAsyncImageEncoder
    private var inflightRequests: [URL: Task<UIImage, any Error>]
    private let urlSession: URLSession

    public init(
        encoder: SmartAsyncImageEncoder = SmartAsyncImageEncoder(),
        diskCache: SmartAsyncImageDiskCache = SmartAsyncImageDiskCache(),
        urlSession: URLSession = .shared
    ) {
        self.encoder = encoder
        self.diskCache = diskCache
        self.inflightRequests = [:]
        self.urlSession = urlSession
    }

    /// Clears the in-memory cache. Useful for test isolation.
    public func clearMemoryCache() {
        cache.removeAllObjects()
    }

    /// Returns the number of currently in-flight requests. Useful for testing task coalescing.
    public var inflightRequestCount: Int {
        inflightRequests.count
    }

    /// Checks if there's a cached image in memory for the given URL.
    public func hasCachedImage(for url: URL) -> Bool {
        cache.object(forKey: url as NSURL) != nil
    }
    
    public func image(for url: URL) async throws -> UIImage {
        // 1. in-memory
        if let image = cache.object(forKey: url as NSURL) {
            return image
        }
        // 2. disk
        if let image = try await diskCache.load(key: url) {
            return image
        }
        // 3. task coalescing (if url is already in-flight, wait for the result, don't make a new one)
        if let task = inflightRequests[url] {
            return try await task.value
        }
        let task = Task<UIImage, any Error> {
            try Task.checkCancellation()
            let (data, response) = try await urlSession.data(from: url)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200..<300).contains(response.statusCode) else {
                throw URLError(.badServerResponse)
            }
            guard let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            cache.setObject(image, forKey: url as NSURL)
            try Task.checkCancellation()
            Task.detached(priority: .utility) { try await self.diskCache.save(image, key: url) }
            return image
        }
        // 4. store the task
        self.inflightRequests[url] = task
        defer {
            self.inflightRequests[url] = nil
        }
        return try await task.value
    }
}

// MARK: - Test Helpers

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
