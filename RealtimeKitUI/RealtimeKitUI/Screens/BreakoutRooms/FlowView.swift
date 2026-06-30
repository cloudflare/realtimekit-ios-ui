//
//  FlowView.swift
//  RealtimeKitUI
//
//  A UIView that lays out its subviews left-to-right and wraps to the next row
//  when a child would overflow the available width — analogous to Android's FlowLayout
//  introduced for breakout-room participant chips.
//

import UIKit

final class FlowView: UIView {
    /// Horizontal gap between chips in the same row.
    var horizontalSpacing: CGFloat = 6
    /// Vertical gap between rows.
    var verticalSpacing: CGFloat = 6

    // MARK: - Height tracking

    /// Tracks the last computed height so we invalidate intrinsicContentSize only
    /// when the height actually changes, preventing layout feedback loops.
    private var lastKnownHeight: CGFloat = -1

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        let h = flow(in: bounds.width, apply: true)
        if abs(h - lastKnownHeight) > 0.5 {
            lastKnownHeight = h
            // Tell Auto Layout our intrinsic height changed so the parent can resize.
            invalidateIntrinsicContentSize()
        }
    }

    /// Invalidate whenever a chip is added or removed so the first layout pass can
    /// compute the correct height even before bounds are set.
    override func didAddSubview(_: UIView) {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override func willRemoveSubview(_: UIView) {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override var intrinsicContentSize: CGSize {
        // intrinsicContentSize is queried before bounds are set during the first Auto
        // Layout pass.  Use the superview width as a proxy; fall back to the screen width.
        let availableWidth: CGFloat = if bounds.width > 0 {
            bounds.width
        } else if let sv = superview, sv.bounds.width > 0 {
            // Subtract the leading inset this view has inside its parent.
            sv.bounds.width - frame.minX * 2
        } else {
            UIScreen.main.bounds.width
        }
        let h = flow(in: max(1, availableWidth), apply: false)
        return CGSize(width: UIView.noIntrinsicMetric, height: max(h, 0))
    }

    // MARK: - Public helpers

    /// Returns the total height this view would need to fit all chips at the given width.
    /// Use this to pre-populate an explicit height constraint before Auto Layout runs.
    func calculateHeight(for width: CGFloat) -> CGFloat {
        flow(in: max(1, width), apply: false)
    }

    // MARK: - Internal layout engine

    /// Arranges subviews into rows.  When `apply` is true, sets each subview's frame.
    /// Always returns the total height required.
    @discardableResult
    private func flow(in width: CGFloat, apply: Bool) -> CGFloat {
        guard !subviews.isEmpty else { return 0 }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            // systemLayoutSizeFitting gives the correct compressed size for Auto-Layout
            // views such as ParticipantChipView.
            let size = subview.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let chipW = ceil(size.width)
            let chipH = ceil(size.height)

            if x > 0, x + chipW > width {
                y += rowHeight + verticalSpacing
                x = 0
                rowHeight = 0
            }
            if apply {
                subview.frame = CGRect(x: x, y: y, width: chipW, height: chipH)
            }
            x += chipW + horizontalSpacing
            rowHeight = max(rowHeight, chipH)
        }
        return y + rowHeight
    }
}
