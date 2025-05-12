//
//  CircularProfileImageView.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 05/03/25.
//

import SwiftUI
import Kingfisher

struct CircularProfileImageView: View {
    let urlString: String?
    let size: ProfileImageSize

    init(urlString: String? = nil, size: ProfileImageSize) {
        self.urlString = urlString
        self.size = size
    }

    var body: some View {
        Group {
            if let urlString = urlString, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        placeholderImage
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimensions, height: size.dimensions)
                    .clipShape(Circle())
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "person")
            .resizable()
            .scaledToFit()
            .frame(width: size.value, height: size.value)
            .foregroundStyle(.gray)
            .padding()
            .background(Color(.systemGray5))
            .clipShape(Circle())
            .frame(width: size.dimensions, height: size.dimensions)
    }
}


enum ProfileImageSize {
    case xSmall
    case small
    case medium
    case large
    
    var value: CGFloat {
        switch self {
        case .xSmall:
            return 20
        case .small:
            return 40
        case .medium:
            return 50
        case .large:
            return 60
        }
    }
    
    var dimensions: CGFloat {
        switch self {
        case .xSmall:
            return 32
        case .small:
            return 52
        case .medium:
            return 64
        case .large:
            return 80
        }
    }
}

#Preview {
    CircularProfileImageView(size: .small)
}
