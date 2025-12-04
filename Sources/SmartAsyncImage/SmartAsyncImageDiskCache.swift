//  Jonathan Ritchey

import Foundation
import UIKit

public struct SmartAsyncImageDiskCache: Sendable {
    public let directory: URL
    public let encoder: SmartAsyncImageEncoder
    
    public init(
        fileManager: FileManager = .default,
        folder: String = "SmartAsyncImageCache",
        encoder: SmartAsyncImageEncoder = SmartAsyncImageEncoder()
    ) {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = cacheDir.appendingPathComponent(folder)
        self.encoder = encoder
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    public func save(
        _ image: UIImage,
        key: URL
    ) async throws {
        guard let data = image.pngData() else {
            throw CocoaError(.fileWriteUnknown)
        }
        let filename = encoder.encode(key) + ".img"
        let url = directory.appendingPathComponent(filename)
        try await Task(priority: .utility) {
            try Task.checkCancellation()
            try data.write(to: url, options: .atomic)
        }.value
    }
    
    public func load(
        key: URL
    ) async throws -> UIImage? {
        let filename = encoder.encode(key) + ".img"
        let url = directory.appendingPathComponent(filename)
        return try await Task(priority: .utility) {
            try Task.checkCancellation()
            let data: Data
            do {
                data = try Data(contentsOf: url, options: [.mappedIfSafe])
            } catch {
                return nil // file not found or permission error.
            }
            try Task.checkCancellation()
            guard let image = UIImage(data: data)?.preparingForDisplay() else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return image
        }.value
    }
}
