//
//  View+Extensions.swift
//  GlassCast
//
//  SwiftUI view extensions
//

import SwiftUI

extension View {
    func glassBackground(opacity: Double = 0.2) -> some View {
        background {
            GlassEffectContainer {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(opacity))
            }
        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
