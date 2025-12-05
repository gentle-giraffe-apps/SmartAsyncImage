# SmartAsyncImage

A smarter, faster `AsyncImage` for SwiftUI with built-in in-memory and disk caching, cancellation, and Swift 6 concurrency.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
[![Coverage](https://img.shields.io/badge/coverage-87%25-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

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
