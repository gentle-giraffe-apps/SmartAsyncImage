//  Jonathan Ritchey

import SwiftUI

public struct SmartAsyncImage<Content: View>: View {
    @State private var viewModel: SmartAsyncImageViewModel
    private let content: (SmartAsyncImagePhase) -> Content

    public init(
        url: URL,
        cache: SmartAsyncImageMemoryCacheProtocol? = nil,
        @ViewBuilder content: @escaping (SmartAsyncImagePhase) -> Content
    ) {
        _viewModel = State(initialValue: SmartAsyncImageViewModel(url: url, cache: cache ?? SmartAsyncImageMemoryCache.shared))
        self.content = content
    }

    public var body: some View {
        content(viewModel.phase)
            .onAppear { viewModel.load() }
            .onDisappear { viewModel.cancel() }
    }
}

extension SmartAsyncImage where Content == Image {
    public init(
        url: URL,
        cache: SmartAsyncImageMemoryCacheProtocol? = nil,
        placeholder: @escaping () -> Image = { Image(systemName: "photo") }
    ) {
        _viewModel = State(
            initialValue: SmartAsyncImageViewModel(
                url: url,
                cache: cache ?? SmartAsyncImageMemoryCache.shared
            )
        )
        self.content = { phase in
            switch phase {
            case .empty, .loading:
                placeholder()
            case .failure:
                Image(systemName: "exclamationmark.triangle")
            case .success(let image):
                image.resizable()
            }
        }
    }
}
