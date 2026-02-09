# Development Guide

How to build, test, and contribute to SmartAsyncImage.

## Repository Layout

| Path | Description |
|------|-------------|
| `Package.swift` | SPM manifest (swift-tools-version 6.1, iOS 17+) |
| `MODULE.bazel` | Bazel module manifest (Bzlmod); depends on `rules_swift` and `rules_apple` |
| `Sources/SmartAsyncImage/SmartAsyncImage.swift` | SwiftUI view with two public initializers |
| `Sources/SmartAsyncImage/SmartAsyncImageViewModel.swift` | `@MainActor @Observable` ViewModel and `SmartAsyncImagePhase` enum |
| `Sources/SmartAsyncImage/SmartAsyncImageMemoryCache.swift` | Actor-based memory cache, cache protocol, task coalescing, network fetch |
| `Sources/SmartAsyncImage/SmartAsyncImageDiskCache.swift` | PNG disk persistence in system Caches directory |
| `Sources/SmartAsyncImage/SmartAsyncImageEncoder.swift` | URL-to-filename percent encoding |
| `Sources/SmartAsyncImage/BUILD.bazel` | Bazel `swift_library` target for the library |
| `Tests/SmartAsyncImageTests/SmartAsyncImageTests.swift` | All tests (Swift Testing framework) |
| `Demo/SmartAsyncImageDemo/` | Xcode demo app with local package reference |
| `Demo/SmartAsyncImageDemo/BUILD.bazel` | Bazel `ios_application` target for the demo |
| `Demo/SmartAsyncImageDemo/fastlane/Fastfile` | Fastlane lanes for build, test, and coverage |
| `.github/workflows/ci.yml` | GitHub Actions CI workflow |
| `.deepsource.toml` | DeepSource static analysis configuration |
| `Docs/` | This documentation folder |

## Build and Test

```bash
swift build                    # SPM build
swift test                     # SPM tests (no coverage)
bazel build //Sources/SmartAsyncImage:SmartAsyncImage   # Bazel library
bazel build //Demo/SmartAsyncImageDemo:SmartAsyncImageDemo  # Bazel demo
```

For Xcode, open `Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj` (local package reference is preconfigured).

Fastlane lanes (from `Demo/SmartAsyncImageDemo/`): `bundle exec fastlane ios build`, `bundle exec fastlane ios package_tests`, `bundle exec fastlane coverage_xml`. These use xcodebuild under the hood with coverage enabled and shared derived data at `.build/DerivedData`.

### Test Framework

Tests use **Swift Testing** (`import Testing`), not XCTest. Assertions use `#expect(...)` and `#require(...)`. Suites are declared with `@Suite`, tests with `@Test`.

### Network Requirement

Integration tests in `SmartAsyncImageMemoryCacheIntegrationTests` fetch real images from the network (Google favicon, Apple favicon, Google logo). These require an active internet connection.

## Testing Patterns

**`MockMemoryCache` actor** -- In-test `actor` conforming to `SmartAsyncImageMemoryCacheProtocol`. Supports configurable delay (`setDelay`) and forced failure (`setShouldFail`) for testing loading states, cancellation, and error paths without network access.

**UUID-isolated disk cache per test** -- Each disk cache test creates a `SmartAsyncImageDiskCache` with a `UUID`-suffixed folder name (e.g., `TestSmartAsyncImageCache_<UUID>`). A cleanup step removes the folder. Prevents cross-test pollution.

**`@MainActor` ViewModel tests** -- `SmartAsyncImageViewModelTests` is annotated `@MainActor` so ViewModel methods can be called synchronously. Tests use `Task.sleep` to allow async operations to settle before asserting phase transitions.

**Isolated cache instances** -- Integration tests use `createIsolatedCache()`, returning a fresh `SmartAsyncImageMemoryCache` backed by its own UUID-named disk cache folder. Avoids shared state from `.shared`.

## CI Pipeline

Defined in `.github/workflows/ci.yml`. Triggers on pushes to `main` and all pull requests. Runs on `macos-26`.

Key insight: the `build` lane compiles once with `build-for-testing` into shared derived data (`.build/DerivedData`), then the demo app build and `package_tests` lane (`test-without-building`) both reuse those artifacts, avoiding recompilation. Coverage is converted from `.xcresult` to Cobertura XML via `xcresultparser` and uploaded to Codecov.

## Quality Tools

**DeepSource** -- Configured in `.deepsource.toml`. Runs `swift` and `secrets` analyzers on commits to `main`. Excludes `.build/`, `.swiftpm/`, `DerivedData/`.

**Codecov** -- Line coverage uploaded from CI on pushes to `main` and pull requests.
