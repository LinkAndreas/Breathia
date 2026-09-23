import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Where a foldable iPhone's display bends while it stands partly folded, so a
/// layout can keep content off the crease.
struct DisplayFold: Equatable {
    enum Axis {
        /// A crease from top to bottom: the display opens like a book.
        case vertical
        /// A crease from side to side: the display stands like a laptop.
        case horizontal
    }

    let axis: Axis
    /// The crease's x (vertical) or y (horizontal) in the window's — SwiftUI's
    /// global — coordinate space.
    let position: CGFloat
}

extension EnvironmentValues {
    /// The display's fold while the hinge is partly open and the app fills the
    /// display; `nil` otherwise. Set by `readsDisplayFold()`.
    @Entry var displayFold: DisplayFold?
}

extension View {
    /// Tracks the hinge and puts the fold in the environment of this view.
    func readsDisplayFold() -> some View {
        #if os(iOS)
        modifier(DisplayFoldReader())
        #else
        self
        #endif
    }
}

#if os(iOS)
private struct DisplayFoldReader: ViewModifier {
    @State private var fold: DisplayFold?

    func body(content: Content) -> some View {
        content
            .environment(\.displayFold, fold)
            .background {
                HingeObserver(fold: $fold)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

private struct HingeObserver: UIViewRepresentable {
    @Binding var fold: DisplayFold?

    func makeUIView(context: Context) -> HingeObservingView {
        let view = HingeObservingView()
        view.onFoldChange = { fold = $0 }
        return view
    }

    func updateUIView(_ view: HingeObservingView, context: Context) {
        view.onFoldChange = { fold = $0 }
    }
}

private final class HingeObservingView: UIView {
    var onFoldChange: ((DisplayFold?) -> Void)?

    private var isPartiallyOpen = false
    private var reportedFold: DisplayFold?

    override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 27.1, *) {
            addInteraction(UIHingeInteraction { [weak self] _, update in
                self?.isPartiallyOpen = update.hinge?.status == .partiallyOpen
                self?.updateFold()
            })
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // The window resizes and rotates with the display; the fold moves with it.
    override func layoutSubviews() {
        super.layoutSubviews()
        updateFold()
    }

    private func updateFold() {
        let fold = currentFold()
        guard fold != reportedFold else { return }
        reportedFold = fold
        onFoldChange?(fold)
    }

    /// The hinge reports whether it's bent, not where. A book-style fold bends the
    /// display across the middle of its longer side, so the crease is only placed
    /// when the window covers the whole display; in a smaller window it could fall
    /// anywhere.
    private func currentFold() -> DisplayFold? {
        guard isPartiallyOpen,
              let window,
              let displayBounds = window.windowScene?.screen.bounds,
              window.bounds.size == displayBounds.size
        else { return nil }
        let bounds = window.bounds
        return bounds.width > bounds.height
            ? DisplayFold(axis: .vertical, position: bounds.midX)
            : DisplayFold(axis: .horizontal, position: bounds.midY)
    }
}
#endif
