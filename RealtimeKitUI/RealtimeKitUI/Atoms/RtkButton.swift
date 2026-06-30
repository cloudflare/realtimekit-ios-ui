//
//  RtkButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public protocol RtkButtonAppearance: BaseAppearance {
    var style: RtkButton.Style { get set }
    var state: RtkButton.States { get set }
    var backgroundColor: BrandColorToken.Shade { get set }
    var iconBackgroundColorToken: BackgroundColorToken.Shade { get set }
    var titleColor: TextColorToken.Background.Shade { get set }
    var cornerRadius: BorderRadiusToken.RadiusType { get set }
    var borderWidthType: BorderWidthToken.Width { get set }
    var selectedStateTintColor: TextColorToken.Background.Shade { get set }
    var normalStateTintColor: TextColorToken.Background.Shade { get set }
    var activityIndicatorColor: TextColorToken.Background.Shade { get set }
}

protocol RtkButtonApplyStyle {
    func applyStyle(style: RtkButton.Style)
}

protocol RtkButtonApplyStates {
    func applyState(state: RtkButton.States)
}

public class RtkButtonAppearanceModel: RtkButtonAppearance {
    public var designLibrary: RtkDesignTokens
    public var selectedStateTintColor: TextColorToken.Background.Shade
    public var normalStateTintColor: TextColorToken.Background.Shade

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.designLibrary = designLibrary
        backgroundColor = designLibrary.color.brand.shade500
        titleColor = designLibrary.color.textColor.onBackground.shade1000
        selectedStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        normalStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        iconBackgroundColorToken = designLibrary.color.background.shade900
        activityIndicatorColor = designLibrary.color.textColor.onBackground.shade900
    }

    public var style: RtkButton.Style = .solid
    public var state: RtkButton.States = .active
    public var backgroundColor: BrandColorToken.Shade
    public var iconBackgroundColorToken: BackgroundColorToken.Shade
    public var activityIndicatorColor: TextColorToken.Background.Shade
    public var titleColor: TextColorToken.Background.Shade
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    public var borderWidthType: BorderWidthToken.Width = .thin
}

class BaseIndicatorView: UIView {
    let indicatorView: UIActivityIndicatorView = {
        let inidicator = UIActivityIndicatorView(style: .medium)
        inidicator.hidesWhenStopped = true
        return inidicator
    }()

    static func createIndicatorView() -> BaseIndicatorView {
        let baseView = BaseIndicatorView()
        baseView.addSubview(baseView.indicatorView)
        baseView.indicatorView.set(.centerView(baseView))
        return baseView
    }

    override var isHidden: Bool {
        get {
            super.isHidden
        }
        set {
            super.isHidden = newValue
            if newValue == true {
                indicatorView.stopAnimating()
            }
        }
    }
}

open class RtkButton: UIButton, BaseAtom {
    var isConstraintAdded: Bool = false

    public enum Style {
        case solid
        case line
        case iconLeftLabel(icon: RtkImage)
        case iconRightLabel(icon: RtkImage)
        case text
        case textIconLeft(icon: RtkImage)
        case textIconRight(icon: RtkImage)
        case iconOnly(icon: RtkImage)
        case splitButton
    }

    public enum States {
        case active
        case disabled
        case hover
        case focus
        case pressed
    }

    public enum Size {
        case small
        case medium
        case large

        func width() -> CGFloat {
            switch self {
            case .large:
                84
            case .medium:
                68
            case .small:
                46
            }
        }

        func height() -> CGFloat {
            switch self {
            case .large:
                40
            case .medium:
                32
            case .small:
                24
            }
        }
    }

    private enum IconPlacementDirection {
        case left
        case right
    }

    private let iconButtonSize = 48.0

    var style: Style = .solid
    var rtkButtonState: States = .active
    var size: Size
    var borderRadiusType: BorderRadiusToken.RadiusType
    var borderWidthType: BorderWidthToken.Width
    private var appearance: RtkButtonAppearance
    private var isLoading = false
    private var baseActivityIndicatorView: BaseIndicatorView?
    private var baseContentView: UIView!
    private var titleTextAtom: RtkLabel!
    private var iconImageView: UIImageView!

    private var heightConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var clickAction: ((RtkButton) -> Void)?
    public var selectedStateTintColor: UIColor
    public var normalStateTintColor: UIColor

    override public var isSelected: Bool {
        didSet {
            if isSelected == true {
                tintColor = selectedStateTintColor
            } else {
                tintColor = normalStateTintColor
            }
        }
    }

    public init(style: Style = .solid, rtkButtonState: States = .active, size: Size = .large, appearance: RtkButtonAppearance = RtkButtonAppearanceModel()) {
        self.style = style
        self.appearance = appearance
        self.size = size
        self.rtkButtonState = rtkButtonState
        normalStateTintColor = self.appearance.normalStateTintColor
        selectedStateTintColor = self.appearance.selectedStateTintColor
        borderRadiusType = self.appearance.cornerRadius
        borderWidthType = self.appearance.borderWidthType
        super.init(frame: .zero)
        createButton(style: style)
        applyStyle(style: style)
        applyWidthHeightConstraint(style: style)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setButtonHeight(constant: CGFloat) {
        if heightConstraint != nil {
            heightConstraint?.constant = constant
        } else {
            heightConstraint = heightAnchor.constraint(equalToConstant: constant)
        }
        heightConstraint?.isActive = true
    }

    private func setButtonWidth(constant: CGFloat) {
        if widthConstraint != nil {
            widthConstraint?.constant = constant
        } else {
            widthConstraint = widthAnchor.constraint(equalToConstant: constant)
        }
        widthConstraint?.isActive = true
    }

    func setClickAction(click: @escaping (RtkButton) -> Void) {
        clickAction = click
        addTarget(self, action: #selector(click(button:)), for: .touchUpInside)
    }

    @objc private func click(button: RtkButton) {
        clickAction?(button)
    }

    func createButton(style: Style) {
        let baseView = UIView()
        baseView.isUserInteractionEnabled = false
        var useDefaultButton = false
        var stackView: BaseStackView!
        switch style {
        case .iconLeftLabel:
            let result = getLabelAndImageOnlyView(dir: .left)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        case .textIconLeft:
            let result = getLabelAndImageOnlyView(dir: .left)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        case .iconRightLabel:
            let result = getLabelAndImageOnlyView(dir: .right)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        case .textIconRight:
            let result = getLabelAndImageOnlyView(dir: .right)
            stackView = result.stackView
            titleTextAtom = result.title
            iconImageView = result.imageView
        default:
            useDefaultButton = true
            print("We are going to use default button except all above defined cases and split button case")
        }
        if useDefaultButton == false {
            baseContentView = baseView
            baseContentView.addSubview(stackView)
            addContrainst(style: style, stackView: stackView)
        }
        layer.masksToBounds = true
    }

    private func addContrainst(style _: Style, stackView _: UIStackView) {
        addSubview(baseContentView)
        baseContentView.set(.fillSuperView(self))
    }

    private func getLabelOnlyView() -> (stackView: BaseStackView, title: RtkLabel) {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: rtkSharedTokenSpace.space1)
        let title = RtkUIUtility.createLabel(text: "")
        stackView.addArrangedSubviews(title)
        return (stackView, title)
    }

    private func getIconOnlyView(image: RtkImage) -> (stackView: BaseStackView, imageView: UIImageView) {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: rtkSharedTokenSpace.space1)
        let iconView = RtkUIUtility.createImageView(image: image)
        stackView.addArrangedSubviews(iconView)
        return (stackView, iconView)
    }

    private func getLabelAndImageOnlyView(dir: IconPlacementDirection = .left) -> (stackView: BaseStackView, title: RtkLabel, imageView: UIImageView) {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: rtkSharedTokenSpace.space1)
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image: nil))
        let title = RtkUIUtility.createLabel(text: "")
        if dir == .left {
            stackView.addArrangedSubviews(imageView, title)
        } else if dir == .right {
            stackView.addArrangedSubviews(title, imageView)
        }
        return (stackView: stackView, title: title, imageView: imageView)
    }
}

extension RtkButton: RtkButtonApplyStyle {
    func applyStyle(style: Style) {
        // MARK: You can't apply any style, We want to check first what is the style in which button is created for eg. If button is created in Text style then we can't apply icon style on it. Instead we can apply solid, line and text interchangeably.

        resetContentViewAppearance()
        switch style {
        case .solid:
            backgroundColor = appearance.backgroundColor
            setTitleColor(appearance.titleColor, for: .normal)
            layer.cornerRadius = appearance.designLibrary.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        case .line:
            setTitleColor(appearance.backgroundColor, for: .normal)
            layer.cornerRadius = appearance.designLibrary.borderRadius.getRadius(size: .one, radius: borderRadiusType)
            layer.borderWidth = appearance.designLibrary.borderSize.getWidth(size: .one, width: borderWidthType)
            layer.borderColor = appearance.backgroundColor.cgColor
        case .text:
            setTitleColor(appearance.designLibrary.color.textColor.onBrand.shade700, for: .normal)
        case .iconLeftLabel:
            break
        case .iconRightLabel:
            break
        case .textIconLeft:
            break
        case .textIconRight:
            break
        case let .iconOnly(icon):
            backgroundColor = appearance.iconBackgroundColorToken
            setImage(icon.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            tintColor = normalStateTintColor
            layer.cornerRadius = appearance.designLibrary.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        case .splitButton:
            break
        }
    }

    private func applyWidthHeightConstraint(style: Style) {
        switch style {
        case .solid:
            setButtonHeight(constant: size.height())
        case .line:
            setButtonHeight(constant: size.height())
            setButtonWidth(constant: size.width())
        case .iconLeftLabel:
            break
        case .iconRightLabel:
            break
        case .text:
            setButtonHeight(constant: size.height())
            setButtonWidth(constant: size.width())
        case .textIconLeft:
            break
        case .textIconRight:
            break
        case .iconOnly:
            setButtonWidth(constant: iconButtonSize)
            setButtonHeight(constant: iconButtonSize)
        case .splitButton:
            break
        }
    }

    private func setContentViewColor(color: UIColor) {
        baseContentView.backgroundColor = color
        baseContentView.layer.borderColor = color.cgColor
    }

    private func resetContentViewAppearance() {
        layer.cornerRadius = 0.0
        layer.borderWidth = 0.0
        layer.borderColor = UIColor.clear.cgColor
        backgroundColor = .clear
    }
}

extension RtkButton: RtkButtonApplyStates {
    func applyState(state: States) {
        let currentStyle = style
        if case .solid = currentStyle {
            applyStatesOnSolidStyle(state: state)
        } else if case .line = currentStyle {
            applyStatesOnLineStyle(state: state)
        } else if case .text = currentStyle {
            applyStatesOnTextStyle(state: state)
        }
    }

    private func applyStatesOnSolidStyle(state: States) {
        switch state {
        case .active:
            break
        case .disabled:
            break
        case .focus:
            break
        case .hover:
            break
        case .pressed:
            break
        }
    }

    private func applyStatesOnLineStyle(state: States) {
        switch state {
        case .active:
            break
        case .disabled:
            break
        case .focus:
            break
        case .hover:
            break
        case .pressed:
            break
        }
    }

    private func applyStatesOnTextStyle(state: States) {
        switch state {
        case .active:
            break
        case .disabled:
            break
        case .focus:
            break
        case .hover:
            break
        case .pressed:
            break
        }
    }
}

public extension RtkButton {
    internal func prepareForReuse() {
        hideActivityIndicator()
    }

    func showActivityIndicator() {
        if baseActivityIndicatorView == nil {
            let baseIndicatorView = BaseIndicatorView.createIndicatorView()
            addSubview(baseIndicatorView)
            baseIndicatorView.set(.fillSuperView(self))
            baseIndicatorView.isHidden = true
            baseActivityIndicatorView = baseIndicatorView
        }
        if baseActivityIndicatorView?.isHidden == true {
            baseActivityIndicatorView?.indicatorView.color = appearance.activityIndicatorColor
            baseActivityIndicatorView?.indicatorView.startAnimating()
            baseActivityIndicatorView?.backgroundColor = backgroundColor
            bringSubviewToFront(baseActivityIndicatorView!)
            baseActivityIndicatorView?.isHidden = false
            isUserInteractionEnabled = false
        }
        isLoading = true
    }

    func hideActivityIndicator() {
        if baseActivityIndicatorView?.isHidden == false {
            baseActivityIndicatorView?.indicatorView.stopAnimating()
            baseActivityIndicatorView?.isHidden = true
        }
        isUserInteractionEnabled = true
        isLoading = false
    }
}
