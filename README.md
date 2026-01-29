# SmartAsyncImage

A smarter, faster `AsyncImage` for SwiftUI with built-in in-memory and disk caching, cancellation, and Swift 6 concurrency.

[![CI](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
![Bazel](https://img.shields.io/badge/Bazel-enabled-555?logo=bazel)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Commit activity](https://img.shields.io/github/commit-activity/y/gentle-giraffe-apps/SmartAsyncImage)
![Last commit](https://img.shields.io/github/last-commit/gentle-giraffe-apps/SmartAsyncImage)

[![Coverage](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/branch/main/graph/badge.svg)](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage)
[![DeepSource Static Analysis](https://img.shields.io/badge/DeepSource-Static%20Analysis-0A2540?logo=deepsource&logoColor=white)](https://deepsource.io/)
[![DeepSource](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage.svg/?label=active+issues&show_trend=true)](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage/)
[![DeepSource](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage.svg/?label=resolved+issues&show_trend=true)](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage/)

<sub><strong>Codecov Snapshot</strong></sub><br/>
<a href="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage">
  <img
    src="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/graphs/icicle.svg"
    height="80"
    alt="Code coverage snapshot by file and module (Codecov tree graph)"
  />
</a>

💬 **[Join the discussion. Feedback and questions welcome](https://github.com/gentle-giraffe-apps/SmartAsyncImage/discussions)**

## Features
- SwiftUI-friendly API with an observable view model
- Smart phase handling: `empty`, `loading`, `success(Image)`, `failure(Error)`
- In-memory caching protocol with pluggable implementations
- Disk cache for persistence across launches
- Swift Concurrency (`async/await`) with cooperative cancellation
- MainActor-safe state updates

## Requirements
- iOS 17+
- Swift 6.2+
- Swift Package Manager

## 📦 Installation (Swift Package Manager)

### Via Xcode

1. Open your project in Xcode
2. Go to **File → Add Packages...**
3. Enter the repository URL: `https://github.com/gentle-giraffe-apps/SmartAsyncImage.git`
4. Choose a version rule (or `main` while developing)
5. Add the **SmartAsyncImage** product to your app target

## Demo App

A runnable SwiftUI demo app is included in this repository using a local package reference.

**Path:**
```
Demo/SmartAsyncImageDemo/SmartAsyncDemo.xcodeproj
```

### How to Run
1. Clone the repository:
   ```bash
   git clone https://github.com/gentle-giraffe-apps/SmartAsyncImage.git
   ```
2. Open the demo project:
   ```
   Demo/SmartAsyncImageDemo/SmartAsyncDemo.xcodeproj
   ```
3. Select an iOS 17+ simulator.
4. Build & Run (⌘R).

The project is preconfigured with a local Swift Package reference to `SmartAsyncImage` and should run without any additional setup.

## Usage

### Quick Example (SwiftUI)
```swift
import SwiftUI
import SmartAsyncImage

struct MinimalRemoteImageView: View {
    let imageURL = URL(string: "https://picsum.photos/300")

    var body: some View {
    
        // replace: AsyncImage(url: imageURL) { phase in
        // ---------------------------------------------
        // with:
        
        SmartAsyncImage(url: imageURL) { phase in
        
        // ----------------------------------------------
        
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "photo")
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 150, height: 150)
    }
}
```

## Architecture

```mermaid
flowchart TD
    SAI["SmartAsyncImage<br/>(SwiftUI View)"] --> VM["SmartAsyncImage<br/>ViewModel"]
    VM --> Phase["SmartAsyncImage<br/>Phase"]
    VM --> MemProto["SmartAsyncImageMemory<br/>CacheProtocol"]
    MemProto --> Mem["SmartAsyncImage<br/>MemoryCache<br/>(actor)"]
    Mem --> Disk["SmartAsyncImage<br/>DiskCache"]
    Disk --> Encoder["SmartAsyncImage<br/>Encoder"]
    Mem --> URLSession[["URLSession"]]
```

---

## 🤖 Tooling Note

Portions of drafting and editorial refinement in this repository were accelerated using large language models (including ChatGPT, Claude, and Gemini) under direct human design, validation, and final approval. All technical decisions, code, and architectural conclusions are authored and verified by the repository maintainer.

---

## 🔐 License

MIT License
Free for personal and commercial use.

---

## 👤 Author

Built by **Jonathan Ritchey**
Gentle Giraffe Apps
Senior iOS Engineer --- Swift | SwiftUI | Concurrency

![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fgentle-giraffe-apps%2FSmartAsyncImage)
