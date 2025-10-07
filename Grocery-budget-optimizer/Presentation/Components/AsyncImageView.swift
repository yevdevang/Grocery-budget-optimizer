//
//  AsyncImageView.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(url: URL?, width: CGFloat = 50, height: CGFloat = 50, cornerRadius: CGFloat = 8) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    init(urlString: String?, width: CGFloat = 50, height: CGFloat = 50, cornerRadius: CGFloat = 8) {
        self.url = URL(string: urlString ?? "")
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
                .overlay {
                    if url != nil {
                        // Loading state
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        // No image state
                        Image(systemName: "cube.box")
                            .foregroundStyle(.gray)
                    }
                }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AsyncImageView(urlString: "https://img.rami-levy.co.il/product/7290109580074/small.jpg")
        AsyncImageView(urlString: nil)
        AsyncImageView(urlString: "invalid-url")
    }
    .padding()
}