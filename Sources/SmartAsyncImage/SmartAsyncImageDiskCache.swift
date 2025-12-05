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
        try await Task.detached {
            try data.write(to: url, options: .atomic)
        }.value
    }
    
    public func load(
        key: URL
    ) async throws -> UIImage? {
        let filename = encoder.encode(key) + ".img"
        let url = directory.appendingPathComponent(filename)
        let data: Data
        do {
            data = try Data(contentsOf: url) // , options: [.mappedIfSafe])
        } catch {
            return nil // file not found or permission error.
        }
        let loadTask = Task {
            return UIImage(data: data)
        }
        guard let image = await loadTask.value else { // ?.preparingForDisplay
            throw CocoaError(.fileReadCorruptFile)
        }
        return image
    }
}
