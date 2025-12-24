//  Jonathan Ritchey

import Foundation
import Observation
import SwiftUI
import UIKit

public enum SmartAsyncImagePhase { case empty, loading, success(Image), failure(Error) }

@MainActor
@Observable
public final class SmartAsyncImageViewModel {

    public var phase: SmartAsyncImagePhase = .empty
    private let url: URL?
    private let cache: SmartAsyncImageMemoryCacheProtocol

    // 1) Hold onto the active task
    private var loadTask: Task<Void, Never>?

    init(url: URL?, cache: SmartAsyncImageMemoryCacheProtocol) {
        self.url = url
        self.cache = cache
    }

    func load() {
        // 2) Avoid duplicate loads, or cancel previous if you want to restart
        guard case .empty = phase else { return }
        phase = .loading

        // 3) Create a cancelable task and store it
        loadTask = Task { [url, cache] in
            guard let url else {
                await MainActor.run { self.phase = .failure(URLError(.badURL)) }
                return
            }
            do {
                let image = try await cache.image(for: url)
                await MainActor.run { self.phase = .success(Image(uiImage: image)) }
            } catch is CancellationError {
                await MainActor.run { self.phase = .empty }
            } catch {
                await MainActor.run { self.phase = .failure(error) }
            }
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        phase = .empty
    }
}
