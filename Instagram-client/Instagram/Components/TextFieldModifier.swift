//
//  TextFieldModifier.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 27/02/25.
//

import SwiftUI

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .autocorrectionDisabled()
            .padding(10)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke()
            }
    }
}

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
