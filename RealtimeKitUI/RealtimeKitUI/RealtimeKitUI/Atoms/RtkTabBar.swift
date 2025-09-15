//
//  RtkTabBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 29/12/22.
//

import RealtimeKit
import UIKit

public protocol RtkTabBarDelegate: AnyObject {
    func didTap(button: RtkControlBarButton, atIndex index: NSInteger)
    func getTabBarHeightForPortrait() -> CGFloat
    func getTabBarWidthForLandscape() -> CGFloat
}

public protocol RtkControlBarAppearance: BaseAppearance {
    var backgroundColor: BackgroundColorToken.Shade { get set }
}

public class RtkControlBarAppearanceModel: RtkControlBarAppearance {
    public var designLibrary: RtkDesignTokens

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.designLibrary = designLibrary
        backgroundColor = designLibrary.color.background.shade900
    }

    public var backgroundColor: BackgroundColorToken.Shade
}

open class RtkTabBar: UIView, AdaptableUI {
    public var portraitConstraints = [NSLayoutConstraint]()
    public var landscapeConstraints = [NSLayoutConstraint]()
    private var previousOrientationIsLandscape = UIScreen.isLandscape()
    private enum Constants {
        static let tabBarAnimationDuration: Double = 1.5
    }

    private lazy var containerView: UIView = .init()

    public weak var delegate: RtkTabBarDelegate?

    private let tokenSpace = DesignLibrary.shared.space

    public let stackView = UIStackView()

    private var appearance: RtkControlBarAppearance
    private let bottomSpace: CGFloat
    @objc public static var baseHeight: CGFloat = 50.0
    @objc public static var defaultBottomAdjustForNonNotch: CGFloat = 15.0
    private let baseWidthForLandscape: CGFloat = 57

    public private(set) var buttons: [RtkControlBarButton] = []

    private var selectedButton: RtkControlBarButton? {
        didSet {}
    }

    private var heightConstraint: NSLayoutConstraint?
    private var widthLandscapeConstraint: NSLayoutConstraint?

    public func setHeight() {
        removeHeightWidthConstraint()
        var extra = RtkTabBar.defaultBottomAdjustForNonNotch
        if superview!.safeAreaInsets.bottom != 0 {
            extra = superview!.safeAreaInsets.bottom
        }
        let height = RtkTabBar.baseHeight + extra
        heightConstraint = heightAnchor.constraint(equalToConstant: delegate?.getTabBarHeightForPortrait() ?? height)
        heightConstraint?.isActive = true
    }

    public func setWidth() {
        var extra = RtkTabBar.defaultBottomAdjustForNonNotch
        if UIScreen.isLandscape(), superview!.safeAreaInsets.right != 0 {
            extra = superview!.safeAreaInsets.right
        }
        setWidth(extra: extra)
    }

    private func removeHeightConstraint() {
        if let constraint = heightConstraint {
            constraint.isActive = false
            removeConstraint(constraint)
        }
    }

    private func removeWidthConstraint() {
        if let constraint = widthLandscapeConstraint {
            constraint.isActive = false
            removeConstraint(constraint)
        }
    }

    private func setWidth(extra: CGFloat) {
        removeHeightWidthConstraint()
        let width = baseWidthForLandscape + extra
        widthLandscapeConstraint = widthAnchor.constraint(equalToConstant: delegate?.getTabBarWidthForLandscape() ?? width)
        widthLandscapeConstraint?.isActive = true
    }

    private func removeHeightWidthConstraint() {
        removeHeightConstraint()
        removeWidthConstraint()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("initwithcoder not supported")
    }

    public init(delegate: RtkTabBarDelegate?, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel()) {
        self.appearance = appearance
        bottomSpace = tokenSpace.space1
        super.init(frame: .zero)
        backgroundColor = appearance.backgroundColor
        self.delegate = delegate
        createViews()
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override open func updateConstraints() {
        super.updateConstraints()
        applyConstraintAsPerOrientation()
        if UIScreen.isLandscape() {
            stackView.axis = .vertical
            setWidth()
        } else {
            stackView.axis = .horizontal
            setHeight()
        }
    }

    @objc func onOrientationChange() {
        let currentOrientationIsLandscape = UIScreen.isLandscape()
        if previousOrientationIsLandscape != currentOrientationIsLandscape {
            previousOrientationIsLandscape = currentOrientationIsLandscape
            onRotationChange()
        }
    }

    func onRotationChange() {
        removeHeightWidthConstraint()
        setOrientationConstraintAsInactive()
        setNeedsUpdateConstraints()
    }

    private func createViews() {
        translatesAutoresizingMaskIntoConstraints = false
        createContainerView()
        createStackView()
        layoutViews()
    }

    private func createContainerView() {
        addSubview(containerView)
        bringSubviewToFront(containerView)
        backgroundColor = appearance.backgroundColor
    }

    private func createStackView() {
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.clipsToBounds = true
    }

    private func layoutViews() {
        stackView.set(.fillSuperView(containerView))
        addPortraitConstraintsForContainerView()
        addLandscapeConstraintsForContainerView()
        applyOnlyConstraintAsPerOrientation()
    }

    private func addPortraitConstraintsForContainerView() {
        containerView.set(.sameLeadingTrailing(self, tokenSpace.space4),
                          .top(self, tokenSpace.space2),
                          .height(RtkTabBar.baseHeight),
                          .bottom(self, tokenSpace.space2, .greaterThanOrEqual), isActive: false)
        portraitConstraints.append(contentsOf: [containerView.get(.leading)!,
                                                containerView.get(.trailing)!,
                                                containerView.get(.top)!,
                                                containerView.get(.height)!,
                                                containerView.get(.bottom)!])
    }

    private func addLandscapeConstraintsForContainerView() {
        containerView.set(.sameTopBottom(self, tokenSpace.space4),
                          .leading(self, tokenSpace.space2),
                          .trailing(self, tokenSpace.space2, .greaterThanOrEqual),
                          .width(baseWidthForLandscape), isActive: false)
        landscapeConstraints.append(contentsOf: [containerView.get(.leading)!,
                                                 containerView.get(.trailing)!,
                                                 containerView.get(.top)!,
                                                 containerView.get(.bottom)!,
                                                 containerView.get(.width)!])
    }

    public func setButtons(_ buttons: [RtkControlBarButton]) {
        for button in self.buttons {
            button.clean()
            stackView.removeFully(view: button.superview!)
        }
        self.buttons.removeAll()
        self.buttons = buttons

        for button in self.buttons {
            let baseView = BaseView()
            baseView.addSubview(button)

            button.set(.top(baseView, 0.0, .greaterThanOrEqual),
                       .centerY(baseView),
                       .centerX(baseView),
                       .leading(baseView, 0.0, .greaterThanOrEqual))
            button.backgroundColor = backgroundColor
            stackView.addArrangedSubview(baseView)
        }
    }

    public func selectButton(at index: Int) {
        if index >= 0, index < buttons.count {
            selectedButton = buttons[index]
        }
    }

    public func getButton(at index: Int) -> RtkControlBarButton? {
        if index >= 0, index < buttons.count {
            return buttons[index]
        }
        return nil
    }

    public func setItemsOrientation(axis: NSLayoutConstraint.Axis) {
        stackView.axis = axis
    }
}

open class RtkControlBar: RtkTabBar {
    public let moreButton: RtkMoreButtonControlBar
    public private(set) var endCallButton: RtkEndMeetingControlBarButton
    private unowned let presentingViewController: UIViewController
    private let meeting: RealtimeKitClient
    private let endCallCompletion: (() -> Void)?

    public init(meeting: RealtimeKitClient, delegate: RtkTabBarDelegate?, presentingViewController: UIViewController, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel(), settingViewControllerCompletion: (() -> Void)? = nil, onLeaveMeetingCompletion: (() -> Void)? = nil) {
        self.meeting = meeting
        self.presentingViewController = presentingViewController
        let moreButton = RtkMoreButtonControlBar(meeting: meeting, presentingViewController: presentingViewController, settingViewControllerCompletion: settingViewControllerCompletion)
        self.moreButton = moreButton
        moreButton.accessibilityIdentifier = "More_ControlBarButton"
        endCallCompletion = onLeaveMeetingCompletion
        let endCallButton = RtkEndMeetingControlBarButton(meeting: meeting, alertViewController: presentingViewController) { _, _ in
            onLeaveMeetingCompletion?()
        }
        endCallButton.accessibilityIdentifier = "End_ControlBarButton"
        self.endCallButton = endCallButton

        super.init(delegate: delegate, appearance: appearance)
        setButtons([RtkControlBarButton]())
    }

    // Override this if you don't want to add More and Call Buttons by defaults
    open func addDefaultButtons(_ buttons: [RtkControlBarButton]) -> [RtkControlBarButton] {
        buttons
    }

    override public func setButtons(_ buttons: [RtkControlBarButton]) {
        var buttons = buttons
        buttons.append(contentsOf: addDefaultButtons(getDefaultButton()))
        super.setButtons(buttons)
    }

    private func getDefaultButton() -> [RtkControlBarButton] {
        var defaultButtons = [RtkControlBarButton]()
        defaultButtons.append(moreButton)
        endCallButton = getEndCallButton()
        endCallButton.accessibilityIdentifier = "End_ControlBarButton"
        defaultButtons.append(endCallButton)
        return defaultButtons
    }

    private func getEndCallButton() -> RtkEndMeetingControlBarButton {
        let endCallButton = RtkEndMeetingControlBarButton(meeting: meeting, alertViewController: presentingViewController) { _, _ in
            self.endCallCompletion?()
        }
        return endCallButton
    }

    public func setTabBarButtonTitles(numOfLines: Int) {
        for button in buttons {
            button.btnTitle?.numberOfLines = numOfLines
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
