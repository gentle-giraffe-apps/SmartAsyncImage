//  Jonathan Ritchey

import SmartAsyncImage
import SwiftUI

struct ContentView: View {
    private let sampleImages = [
        (id: 10, title: "Forest"),
        (id: 20, title: "Architecture"),
        (id: 30, title: "Nature"),
        (id: 40, title: "Urban"),
        (id: 50, title: "Landscape"),
        (id: 60, title: "Abstract"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Simple usage with default placeholder
                    Section {
                        SmartAsyncImage(url: URL(string: "https://picsum.photos/id/1/400/300")!)
                            .aspectRatio(4/3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } header: {
                        sectionHeader("Simple Usage")
                    }

                    // Custom content with phase handling
                    Section {
                        SmartAsyncImage(url: URL(string: "https://picsum.photos/id/15/400/300")!) { phase in
                            switch phase {
                            case .empty, .loading:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                VStack {
                                    Image(systemName: "wifi.slash")
                                        .font(.largeTitle)
                                    Text("Failed to load")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } header: {
                        sectionHeader("Custom Phase Handling")
                    }

                    // Grid of images
                    Section {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(sampleImages, id: \.id) { item in
                                VStack {
                                    SmartAsyncImage(url: URL(string: "https://picsum.photos/id/\(item.id)/200/200")!)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(item.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        sectionHeader("Image Grid")
                    }
                }
                .padding()
            }
            .navigationTitle("SmartAsyncImage Demo")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
