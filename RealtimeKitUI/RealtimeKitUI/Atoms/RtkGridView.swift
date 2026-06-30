//
//  RtkGridView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 06/01/23.
//

import UIKit

public class GridView<CellContainerView: UIView>: UIView {
    struct Paddings {
        let top: CGFloat = 20
        let bottom: CGFloat = 20
        let leading: CGFloat = 10
        let trailing: CGFloat = 10
        let interimPadding: CGFloat = 10
    }

    let maxItems: UInt
    private let maxItemsInRow: UInt = 2
    private let paddings = Paddings()
    private var views: [CellContainerView]!
    private var frames: [CGRect]!

    private var currentVisibleItem: UInt
    private var previousAnimation = true
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private let getChildView: () -> CellContainerView
    private let scrollView = UIScrollView()
    private let scrollContentView = UIView()

    public init(maxItems: UInt = 9, showingCurrently: UInt, getChildView: @escaping () -> CellContainerView) {
        self.maxItems = maxItems
        self.getChildView = getChildView
        if isDebugModeOn {
            print("Debug RtkUIKit | Creating GridView showingCurrently \(showingCurrently)")
        }
        currentVisibleItem = showingCurrently
        super.init(frame: .zero)
        createSubView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func settingFrames(visibleItemCount: UInt, animation: Bool = true, completion: @escaping (Bool) -> Void) {
        currentVisibleItem = visibleItemCount
        previousAnimation = animation
        layoutIfNeeded()
        frames = frameForPortrait(itemsCount: visibleItemCount, width: scrollView.frame.width, height: scrollView.frame.height)
        scrollContentView.get(.width)?.constant = scrollView.frame.width
        scrollContentView.get(.height)?.constant = scrollView.frame.height
        initialize(views: views, frames: frames, animation: animation, completion: completion)
    }

    public func settingFramesForLandScape(visibleItemCount: UInt, animation: Bool = true, completion: @escaping (Bool) -> Void) {
        currentVisibleItem = visibleItemCount
        previousAnimation = animation
        layoutIfNeeded()
        frames = frameForLandscape(itemsCount: visibleItemCount, width: scrollView.frame.width, height: scrollView.frame.height)
        scrollContentView.get(.width)?.constant = scrollView.frame.width
        scrollContentView.get(.height)?.constant = scrollView.frame.height
        initialize(views: views, frames: frames, animation: animation, completion: completion)
    }

    public func settingFramesForPluginsActiveInPortraitMode(visibleItemCount: UInt, animation: Bool = true, completion: @escaping (Bool) -> Void) {
        currentVisibleItem = visibleItemCount
        previousAnimation = animation
        frames = getFramesForHorizontal(itemsCount: visibleItemCount, height: scrollView.frame.height)
        scrollContentView.get(.width)?.constant = (frames.last?.maxX ?? 0) + paddings.trailing
        scrollContentView.get(.height)?.constant = scrollView.frame.height

        initialize(views: views, frames: frames, animation: animation, completion: completion)
    }

    public func settingFramesForPluginsActiveInLandscapeMode(visibleItemCount: UInt, animation: Bool = true, completion: @escaping (Bool) -> Void) {
        currentVisibleItem = visibleItemCount
        previousAnimation = animation
        frames = getFramesForLandscapeVertical(itemsCount: visibleItemCount, width: scrollView.frame.width)
        scrollContentView.get(.width)?.constant = scrollView.frame.width
        scrollContentView.get(.height)?.constant = (frames.last?.maxY ?? 0) + paddings.bottom
        initialize(views: views, frames: frames, animation: animation, completion: completion)
    }

    public func prepareForReuse(childView: (CellContainerView) -> Void) {
        for i in 0 ..< maxItems {
            if let peerView = self.childView(index: Int(i)) {
                childView(peerView)
            }
        }
    }

    public func childView(index: Int) -> CellContainerView? {
        if index >= 0, index < maxItems {
            return views[index]
        }
        return nil
    }
}

extension GridView {
    private func getFramesForHorizontal(itemsCount: UInt, height: CGFloat) -> [CGRect] {
        var x = paddings.leading
        let width = height * 0.8
        let height = height - (paddings.top + paddings.bottom)

        var result = [CGRect]()
        for _ in 0 ..< itemsCount {
            let frame = CGRect(x: x, y: paddings.top, width: width, height: height)
            x += (paddings.interimPadding + width)
            result.append(frame)
        }
        return result
    }

    private func getFramesForLandscapeVertical(itemsCount: UInt, width: CGFloat) -> [CGRect] {
        var y = paddings.top
        let height = width * 0.8
        let width = width - (paddings.leading + paddings.trailing)

        var result = [CGRect]()
        for _ in 0 ..< itemsCount {
            let frame = CGRect(x: paddings.leading, y: y, width: width, height: height)
            y += (paddings.interimPadding + height)
            result.append(frame)
        }
        return result
    }
}

extension GridView {
    private func createSubView() {
        addSubViews(scrollView)
        scrollView.addSubview(scrollContentView)
        scrollView.set(.fillSuperView(self))
        scrollContentView.set(.fillSuperView(scrollView), .width(0), .height(0))
        views = createView(baseView: scrollContentView)
    }

    private func createView(baseView: UIView) -> [CellContainerView] {
        var result = [CellContainerView]()
        for i in 0 ..< maxItems {
            let view = getChildView()
            view.tag = Int(i)
            view.translatesAutoresizingMaskIntoConstraints = false
            baseView.addSubview(view)
            result.append(view)
            if isDebugModeOn {
                let label = RtkUIUtility.createLabel(text: "View No: \(i) test \(view)")
                label.textColor = .black
                label.layer.zPosition = 1.0
                view.addSubview(label)
                label.numberOfLines = 0
                label.set(.centerY(view), .sameLeadingTrailing(view, 20))
            }
        }
        return result
    }

    private func initialize(views: [CellContainerView], frames: [CGRect], animation: Bool, completion: @escaping (Bool) -> Void) {
        if animation {
            if isDebugModeOn {
                print("Debug RtkUIKit | loading Child view with Animations == true")
            }
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                let viewToShow = frames.count
                for i in 0 ..< views.count {
                    let view = views[i]

                    if i < viewToShow {
                        if view.get(.top) == nil {
                            view.set(.top(self.scrollContentView, frames[i].minY))
                        }
                        if view.get(.leading) == nil {
                            view.set(.leading(self.scrollContentView, frames[i].minX))
                        }
                        if view.get(.width) == nil {
                            view.set(.width(frames[i].width))
                        }
                        if view.get(.height) == nil {
                            view.set(.height(frames[i].height))
                        }
                        view.get(.top)?.constant = frames[i].minY
                        view.get(.leading)?.constant = frames[i].minX
                        view.get(.width)?.constant = frames[i].width
                        view.get(.height)?.constant = frames[i].height
                    } else {
                        if view.get(.width) == nil {
                            view.set(.width(0))
                        }
                        if view.get(.height) == nil {
                            view.set(.height(0))
                        }
                        view.get(.width)?.constant = 0
                        view.get(.height)?.constant = 0
                    }
                }
                self.scrollContentView.layoutIfNeeded()
            } completion: { finish in
                completion(finish)
            }
        } else {
            if isDebugModeOn {
                print("Debug RtkUIKit | loading Child view with Animations == false")
            }

            let viewToShow = frames.count
            for i in 0 ..< views.count {
                let view = views[i]
                if i < viewToShow {
                    if view.get(.top) == nil {
                        view.set(.top(scrollContentView, frames[i].minY))
                    }
                    if view.get(.leading) == nil {
                        view.set(.leading(scrollContentView, frames[i].minX))
                    }
                    if view.get(.width) == nil {
                        view.set(.width(frames[i].width))
                    }
                    if view.get(.height) == nil {
                        view.set(.height(frames[i].height))
                    }
                    view.get(.top)?.constant = frames[i].minY
                    view.get(.leading)?.constant = frames[i].minX
                    view.get(.width)?.constant = frames[i].width
                    view.get(.height)?.constant = frames[i].height
                } else {
                    if view.get(.width) == nil {
                        view.set(.width(0))
                    }
                    if view.get(.height) == nil {
                        view.set(.height(0))
                    }
                    view.get(.width)?.constant = 0
                    view.get(.height)?.constant = 0
                }
            }
            completion(true)
        }
    }

    private func frameForLandscape(itemsCount: UInt, width: CGFloat, height: CGFloat) -> [CGRect] {
        if isDebugModeOn {
            print("Debug RtkUIKit | frame(itemsCount Width \(width) Height \(height) ")
        }
        let itemsCount = itemsCount > maxItems ? maxItems : itemsCount
        let rows = numOfRowsOfLandscape(itemsCount: itemsCount)
        if itemsCount <= 3 {
            return getFrameForMiddleRow(items: itemsCount, rowFrame: CGRect(x: 0, y: 0, width: width, height: height))
        } else {
            var result = [CGRect]()
            let rowHeight = height / CGFloat(rows)
            let rowWidth = width
            let firsRowFrame = CGRect(x: paddings.leading, y: paddings.top, width: rowWidth, height: rowHeight)
            let firstRowItemCount = UInt(ceil(Float64(itemsCount) / CGFloat(rows)))
            let framesFirstRow = getFrameForFirstRow(items: firstRowItemCount, rowFrame: firsRowFrame)
            let itemsInSecondRow = (itemsCount - firstRowItemCount)
            let framesSecondRow = getFrameForLastRow(items: firstRowItemCount, rowFrame: CGRect(x: paddings.leading, y: rowHeight, width: rowWidth, height: rowHeight))
            result.append(contentsOf: framesFirstRow)
            for i in 0 ..< itemsInSecondRow {
                result.append(framesSecondRow[Int(i)])
            }
            return result
        }
    }

    private func frameForPortrait(itemsCount: UInt, width: CGFloat, height: CGFloat) -> [CGRect] {
        if isDebugModeOn {
            print("Debug RtkUIKit | frame(itemsCount Width \(width) Height \(height) ")
        }
        if itemsCount <= 0 {
            return [CGRect]()
        }

        let itemsCount = itemsCount > maxItems ? maxItems : itemsCount
        let rows = numOfRowsOfPortrait(itemsCount: itemsCount)
        if itemsCount == 1 {
            let itemWidth = width - (paddings.leading + paddings.trailing)
            let itemHeight = height - (paddings.top + paddings.bottom)
            return [CGRect(x: paddings.leading, y: paddings.top, width: itemWidth, height: itemHeight)]
        } else if itemsCount == 2 {
            var result = [CGRect]()
            let rowHeight = height / CGFloat(rows)
            let rowWidth = width
            let firsRowFrame = CGRect(x: paddings.leading, y: paddings.top, width: rowWidth, height: rowHeight)
            let framesFirstRow = getFrameForFirstRow(items: 1, rowFrame: firsRowFrame)
            let framesSecondRow = getFrameForLastRow(items: 1, rowFrame: CGRect(x: paddings.leading, y: rowHeight, width: rowWidth, height: rowHeight))
            result.append(contentsOf: framesFirstRow)
            result.append(contentsOf: framesSecondRow)
            return result
        }

        return getFrameForPortrait(itemsCount: itemsCount, rows: rows, width: width, height: height)
    }

    private func getFrameForPortrait(itemsCount: UInt, rows: UInt, width: CGFloat, height: CGFloat) -> [CGRect] {
        let rowHeight = height / CGFloat(rows)
        let rowWidth = width
        var result = [CGRect]()
        var items: UInt = 0
        var y: CGFloat = 0.0
        for row in 1 ... rows {
            if row == 1 {
                // First row items will always equal to 'maxItemsInRow'
                result.append(contentsOf: getFrameForFirstRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += maxItemsInRow
            } else if row == rows {
                // Last row items can be less than 'maxItemsInRow'
                var itemsLeft = itemsCount - items
                if itemsLeft > maxItemsInRow {
                    itemsLeft = maxItemsInRow
                }
                // Last row must have frame similar to two items but frame added in result is equivalent to items present
                let frames = getFrameForLastRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight))
                if itemsLeft == 1 {
                    result.append(frames[0])
                } else {
                    result.append(contentsOf: frames)
                }
                items += itemsLeft
            } else {
                // Middle row items will always equal to 'maxItemsInRow'
                result.append(contentsOf: getFrameForMiddleRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += maxItemsInRow
            }
            y += rowHeight
        }

        return result
    }

    private func frame(itemsCount: UInt, rows: UInt, width: CGFloat, height: CGFloat) -> [CGRect] {
        let rowHeight = height / CGFloat(rows)
        let rowWidth = width
        var result = [CGRect]()
        var items: UInt = 0
        var y: CGFloat = 0.0
        for row in 1 ... rows {
            if row == 1 {
                // First row items will always equal to 'maxItemsInRow'
                result.append(contentsOf: getFrameForFirstRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += maxItemsInRow

            } else if row == rows {
                // Last row items can be less than 'maxItemsInRow'
                var itemsLeft = itemsCount - items
                if itemsLeft > maxItemsInRow {
                    itemsLeft = maxItemsInRow
                }
                result.append(contentsOf: getFrameForLastRow(items: itemsLeft, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += itemsLeft

            } else {
                // Middle row items will always equal to 'maxItemsInRow'
                result.append(contentsOf: getFrameForMiddleRow(items: maxItemsInRow, rowFrame: CGRect(x: 0, y: y, width: rowWidth, height: rowHeight)))
                items += maxItemsInRow
            }
            y += rowHeight
        }

        return result
    }

    private func getFrameForFirstRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let top = paddings.top
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame: CGRect?

        let totalInterimSpace = (CGFloat(items) - 1) * paddings.interimPadding
        let itemWidth = (rowFrame.width - (paddings.leading + paddings.trailing + totalInterimSpace)) / CGFloat(items)
        let itemHeight = rowFrame.height - (paddings.top) - (paddings.interimPadding / 2.0)

        for _ in 0 ..< items {
            if let preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidth, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }

        return result
    }

    private func getFrameForMiddleRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let halfInterimSpace = paddings.interimPadding / 2.0
        let top = rowFrame.origin.y + halfInterimSpace
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame: CGRect?

        let totalInterimSpace = (CGFloat(items) - 1) * paddings.interimPadding
        let totalPaddingSpace = paddings.leading + paddings.trailing + totalInterimSpace
        let itemWidth = (rowFrame.width - totalPaddingSpace) / CGFloat(items)
        let itemHeight = rowFrame.height - paddings.interimPadding

        for _ in 0 ..< items {
            if let preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidth, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }

        return result
    }

    func getFrameForLastRow(items: UInt, rowFrame: CGRect) -> [CGRect] {
        let top = rowFrame.origin.y + (paddings.interimPadding / 2.0)
        var result = [CGRect]()
        var x = paddings.leading
        var preFrame: CGRect?
        let totalInterimSpace = (CGFloat(items) - 1) * paddings.interimPadding
        let totalPaddingSpace = paddings.leading + paddings.trailing + totalInterimSpace

        let itemWidth = (rowFrame.width - totalPaddingSpace) / CGFloat(items)
        let itemHeight = rowFrame.height - (paddings.bottom) - (paddings.interimPadding / 2.0)

        for _ in 0 ..< items {
            if let preFrame {
                x = preFrame.maxX + paddings.interimPadding
            }
            let frame = CGRect(x: x, y: top, width: itemWidth, height: itemHeight)
            result.append(frame)
            preFrame = frame
        }
        return result
    }

    private func numOfRowsOfPortrait(itemsCount: UInt) -> UInt {
        if itemsCount == 1 {
            return 1
        }
        if itemsCount == 2 || itemsCount < 4 {
            return 2
        }
        return UInt(ceil(Float64(itemsCount) / CGFloat(maxItemsInRow)))
    }

    private func numOfRowsOfLandscape(itemsCount: UInt) -> UInt {
        if itemsCount <= 3 {
            return 1
        }
        return 2
    }
}

class RtkMeetingGridView {}
