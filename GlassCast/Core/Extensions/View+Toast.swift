//
//  View+Toast.swift
//  GlassCast
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @State private var isShowing = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let message = message, isShowing {
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 16))

                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background {
                        GlassEffectContainer {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(999)
            }
        }
        .onChange(of: message) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isShowing = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        message = nil
                    }
                }
            }
        }
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
