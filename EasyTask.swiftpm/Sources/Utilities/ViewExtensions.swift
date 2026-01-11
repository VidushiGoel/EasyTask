import SwiftUI

// MARK: - Conditional Modifier

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply different modifiers based on a condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
}

// MARK: - Platform-Specific Modifiers

extension View {
    /// Apply modifier only on iOS
    @ViewBuilder
    func iOS<Content: View>(_ transform: (Self) -> Content) -> some View {
        #if os(iOS)
        transform(self)
        #else
        self
        #endif
    }

    /// Apply modifier only on macOS
    @ViewBuilder
    func macOS<Content: View>(_ transform: (Self) -> Content) -> some View {
        #if os(macOS)
        transform(self)
        #else
        self
        #endif
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    let color: Color
    let isCompact: Bool

    func body(content: Content) -> some View {
        content
            .padding(isCompact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.1))
                    )
                    .overlay(
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: 4)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    )
            )
    }
}

extension View {
    func cardStyle(color: Color, isCompact: Bool = false) -> some View {
        modifier(CardStyle(color: color, isCompact: isCompact))
    }
}

// MARK: - Haptic Feedback

#if os(iOS)
import UIKit

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}
#endif

// MARK: - Shimmer Effect (for loading states)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.5),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Keyboard Dismissal

#if os(iOS)
extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
#endif
