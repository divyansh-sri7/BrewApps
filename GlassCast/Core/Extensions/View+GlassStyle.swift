//
//  View+GlassStyle.swift
//  GlassCast
//

import SwiftUI

// MARK: - Glass Style Modifiers

extension View {
    func glassCard(cornerRadius: CGFloat = 24, opacity: Double = 0.15) -> some View {
        self
            .background {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    func glassButton(cornerRadius: CGFloat = 16, opacity: Double = 0.2) -> some View {
        self
            .background {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white.opacity(opacity))
                }
            }
    }

    func glassField(cornerRadius: CGFloat = 12) -> some View {
        self
            .background {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        }
                }
            }
    }
}

// MARK: - Enhanced Glass Container

struct EnhancedGlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let depth: GlassDepth

    enum GlassDepth {
        case subtle
        case medium
        case prominent

        var opacity: Double {
            switch self {
            case .subtle: return 0.1
            case .medium: return 0.15
            case .prominent: return 0.2
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .subtle: return 8
            case .medium: return 12
            case .prominent: return 16
            }
        }
    }

    init(
        cornerRadius: CGFloat = 24,
        depth: GlassDepth = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.depth = depth
    }

    var body: some View {
        content
            .background {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
            }
            .shadow(
                color: .black.opacity(0.08),
                radius: depth.shadowRadius,
                y: depth.shadowRadius / 2
            )
    }
}
