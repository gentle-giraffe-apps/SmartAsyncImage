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
    ) throws {
        guard let data = image.pngData() else {
            throw CocoaError(.fileWriteUnknown)
        }
        let filename = encoder.encode(key) + ".img"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
    }
        
    public func load(
        key: URL
    ) throws -> UIImage? {
        let filename = encoder.encode(key) + ".img"
        let url = directory.appendingPathComponent(filename)
        let data: Data
        do {
            data = try Data(contentsOf: url) // , options: [.mappedIfSafe])
        } catch {
            return nil // file not found or permission error.
        }
        guard let image = UIImage(data: data) else { // ?.preparingForDisplay
            throw CocoaError(.fileReadCorruptFile)
        }
        return image
    }

    /// Forces the image to fully decode and redraw itself into a new context.
    /// This sanitizes the image data without using lossy compression (like JPEG).
    func sanitizedLossless(image: UIImage) -> UIImage? {
        let size = image.size
        
        // 1. Create a renderer for the image's original size and scale.
        // The 'opaque: false' and 'scale: 0.0' ensure it respects transparency
        // and uses the device's main screen scale (e.g., @3x).
        let renderer = UIGraphicsImageRenderer(size: size, format: image.imageRendererFormat)
        
        // 2. Draw the image into the new context. This forces the decoding.
        let sanitizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return sanitizedImage
    }
}
