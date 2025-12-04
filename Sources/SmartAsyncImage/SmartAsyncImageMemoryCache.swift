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
    private var inflightRequests: [URL: Task<UIImage, Error>]
    
    public init(
        encoder: SmartAsyncImageEncoder = SmartAsyncImageEncoder(),
        diskCache: SmartAsyncImageDiskCache = SmartAsyncImageDiskCache()
    ) {
        self.encoder = encoder
        self.diskCache = diskCache
        self.inflightRequests = [:]
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
        let task = Task<UIImage, Error> {
            try Task.checkCancellation()
            let (data, response) = try await URLSession.shared.data(from: url)
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
            try await self.diskCache.save(image, key: url)
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
