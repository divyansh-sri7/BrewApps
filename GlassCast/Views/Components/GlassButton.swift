//
//  GlassButton.swift
//  GlassCast
//
//  Created by Claude on 20/01/26.
//

import SwiftUI

struct GlassButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.2))
                }
            }
        }
        .disabled(isLoading)
    }
}
