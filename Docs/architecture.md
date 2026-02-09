# Architecture

Technical reference for the SmartAsyncImage library internals.

## Component Overview

| Type | File | Isolation | Responsibility |
|------|------|-----------|----------------|
| `SmartAsyncImage<Content>` | `SmartAsyncImage.swift` | `@MainActor` (SwiftUI View) | SwiftUI drop-in view; wires `onAppear`/`onDisappear` to ViewModel |
| `SmartAsyncImagePhase` | `SmartAsyncImageViewModel.swift` | `Sendable` (enum) | Load state: `empty`, `loading`, `success(Image)`, `failure(Error)` |
| `SmartAsyncImageViewModel` | `SmartAsyncImageViewModel.swift` | `@MainActor @Observable` | Owns the `Task`, drives phase transitions, delegates fetching to cache |
| `SmartAsyncImageMemoryCacheProtocol` | `SmartAsyncImageMemoryCache.swift` | Any (protocol) | Single-method abstraction (`image(for:)`) for injectable/mockable caching |
| `SmartAsyncImageMemoryCache` | `SmartAsyncImageMemoryCache.swift` | `actor` | Coordinates memory cache, disk cache, network fetch, and task coalescing |
| `SmartAsyncImageDiskCache` | `SmartAsyncImageDiskCache.swift` | `Sendable` struct | PNG persistence in `Library/Caches/SmartAsyncImageCache/`; I/O in detached tasks |
| `SmartAsyncImageEncoder` | `SmartAsyncImageEncoder.swift` | `Sendable` struct | Percent-encodes a URL into a filename-safe string (internal `encode`/`decode`) |

**Concurrency notes:** `Package.swift` enables `StrictConcurrency` and `ExistentialAny` upcoming features on both library and test targets (swift-tools-version 6.1). The view and ViewModel share `@MainActor` isolation. The memory cache actor serializes `NSCache` and `inflightRequests` without manual locking. Disk cache and encoder are stateless `Sendable` structs.

## Image Load Lifecycle

A complete load/cancel cycle from view appearance to rendered image:

1. **`SmartAsyncImage.body`** renders and SwiftUI calls `onAppear`.
2. **`ViewModel.load()`** is invoked on the main actor. A `guard` check ensures `phase == .empty`; duplicate calls are no-ops. Phase transitions to `.loading`.
3. **A `Task` is created** and stored in `loadTask`. The closure captures `url` and `cache` by value to avoid retaining `self`.
4. **`cache.image(for: url)`** is called, entering the actor-isolated `SmartAsyncImageMemoryCache`.
5. **Memory lookup** -- `NSCache<NSURL, UIImage>` is checked first. On hit, the `UIImage` is returned immediately.
6. **Disk lookup** -- `SmartAsyncImageDiskCache.load(key:)` hashes the URL via `SmartAsyncImageEncoder`, reads `<hash>.img` from the Caches directory, and decodes it into a `UIImage`. On hit, the image is returned.
7. **Task coalescing check** -- if `inflightRequests[url]` already holds a `Task`, the caller awaits that existing task instead of creating a new network request.
8. **Network fetch** -- a new `Task<UIImage, any Error>` is created and stored in `inflightRequests[url]`. Inside the task:
   - `Task.checkCancellation()` (checkpoint 1)
   - `URLSession.data(from: url)` performs the download
   - `Task.checkCancellation()` (checkpoint 2)
   - HTTP response is validated (status 200..<300)
   - `UIImage(data:)` decodes the response body
   - The image is stored in `NSCache`
   - `Task.checkCancellation()` (checkpoint 3)
   - A `Task.detached(priority: .utility)` writes the PNG to disk without blocking the return
9. **`inflightRequests[url]`** is set to `nil` via `defer` after the task's value is awaited, regardless of success or failure.
10. **Back in the ViewModel**, the returned `UIImage` is wrapped in `Image(uiImage:)` and phase transitions to `.success` on `MainActor.run`.
11. **Error paths** -- `CancellationError` resets phase to `.empty`; all other errors set `.failure(error)`.
12. **Disappearance** -- SwiftUI calls `onDisappear`, which invokes `ViewModel.cancel()`. This cancels `loadTask`, nils it out, and resets phase to `.empty`.

## Caching Strategy

**Three-level lookup order** (checked sequentially within `SmartAsyncImageMemoryCache.image(for:)`):

| Level | Storage | Survives |
|-------|---------|----------|
| 1. Memory | `NSCache<NSURL, UIImage>` | App lifecycle (evicted under memory pressure) |
| 2. Disk | PNG files (`<percent-encoded-url>.img`) | App restarts (cleared by OS under storage pressure) |
| 3. Network | `URLSession.shared` (or injected session) | N/A |

**Task coalescing** -- `inflightRequests: [URL: Task<UIImage, any Error>]` ensures concurrent requests for the same URL share a single network task. Entry is inserted before `await task.value` and removed in a `defer` block.

## Design Decisions

- **UIKit dependency** -- `UIImage` for decoding, PNG serialization (`pngData()`), and `NSCache` storage. SwiftUI `Image` is only constructed at the view layer via `Image(uiImage:)`.
- **iOS 17+ minimum** -- Required for `@Observable` (Observation framework), avoiding `@Published`/`ObservableObject` boilerplate.
- **Protocol for memory cache** -- `SmartAsyncImageMemoryCacheProtocol` with a single `image(for:)` requirement allows tests to inject a `MockMemoryCache` actor without network or disk.
- **Actor over class** -- `SmartAsyncImageMemoryCache` is an `actor` to serialize `inflightRequests` and `NSCache` access. Although `NSCache` is itself thread-safe, the coalescing dictionary is not.
- **Sendable struct for disk cache** -- Holds only a `URL` and encoder (both `Sendable`). I/O dispatched to detached tasks; no mutable state.
- **Detached disk writes** -- `Task.detached(priority: .utility)` so writes don't inherit the actor's executor or block the image return.
- **`@State` for ViewModel** -- `@Observable` classes work with `@State` in iOS 17+, avoiding `ObservableObject` entirely.
- **Convenience init behavior** -- Uses `placeholder()` for `.empty`/`.loading`, `exclamationmark.triangle` for `.failure`, `image.resizable()` for `.success`.
