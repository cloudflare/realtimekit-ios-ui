//
//  RtkPluginScreenShareTabButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 03/01/23.
//

import UIKit

public class NextPreviousButtonView: UIView {
    public let previousButton: RtkControlBarButton
    public let nextButton: RtkControlBarButton
    private let firstLabel: RtkLabel
    private let secondLabel: RtkLabel
    private let slashLabel: RtkLabel

    private let tokenBorderRadius = DesignLibrary.shared.borderRadius
    private let tokenSpace = DesignLibrary.shared.space
    private let tokenColor = DesignLibrary.shared.color
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor

    private let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePaginationView ?? .extrarounded

    public var autolayoutModeEnable = true

    let autoLayoutImageView: BaseImageView = {
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image: ImageProvider.image(named: "icon_topbar_autolayout")))
        return imageView
    }()

    convenience init() {
        self.init(firsButtonImage: RtkImage(image: ImageProvider.image(named: "icon_left_arrow")), secondButtonImage: RtkImage(image: ImageProvider.image(named: "icon_right_arrow")))
    }

    init(firsButtonImage: RtkImage, secondButtonImage: RtkImage) {
        previousButton = RtkControlBarButton(image: firsButtonImage, appearance: AppTheme.shared.controlBarButtonAppearance)
        nextButton = RtkControlBarButton(image: secondButtonImage, appearance: AppTheme.shared.controlBarButtonAppearance)
        firstLabel = RtkUIUtility.createLabel()
        firstLabel.font = UIFont.systemFont(ofSize: 16)
        firstLabel.textColor = tokenTextColorToken.onBackground.shade900
        slashLabel = RtkUIUtility.createLabel(text: "/")
        slashLabel.font = UIFont.systemFont(ofSize: 16)
        slashLabel.textColor = tokenTextColorToken.onBackground.shade600
        secondLabel = RtkUIUtility.createLabel()
        secondLabel.font = UIFont.systemFont(ofSize: 12)
        secondLabel.textColor = tokenTextColorToken.onBackground.shade600
        super.init(frame: .zero)
        createView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createView() {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 0)
        addSubview(stackView)
        stackView.set(.fillSuperView(self))

        let buttonBaseViewPrevious = UIView()
        buttonBaseViewPrevious.addSubview(previousButton)
        previousButton.set(.sameTopBottom(buttonBaseViewPrevious),
                           .trailing(buttonBaseViewPrevious),
                           .leading(buttonBaseViewPrevious))
        let buttonBaseViewNext = UIView()
        buttonBaseViewNext.addSubview(nextButton)
        nextButton.set(.sameTopBottom(buttonBaseViewNext),
                       .trailing(buttonBaseViewNext),
                       .leading(buttonBaseViewNext))
        let titleBaseView = UIView()
        titleBaseView.addSubview(firstLabel)
        titleBaseView.addSubview(slashLabel)
        titleBaseView.addSubview(secondLabel)

        firstLabel.set(.sameTopBottom(titleBaseView),
                       .leading(titleBaseView))
        slashLabel.set(.sameTopBottom(titleBaseView),
                       .after(firstLabel),
                       .before(secondLabel))
        secondLabel.set(.sameTopBottom(titleBaseView),
                        .trailing(titleBaseView))
        titleBaseView.addSubview(autoLayoutImageView)
        autoLayoutImageView.set(.fillSuperView(titleBaseView))

        stackView.addArrangedSubviews(buttonBaseViewPrevious, titleBaseView, buttonBaseViewNext)
        backgroundColor = tokenColor.background.shade900
        autoLayoutImageView.backgroundColor = backgroundColor
        layer.masksToBounds = true
        layer.cornerRadius = tokenBorderRadius.getRadius(size: .two, radius: borderRadiusType)
    }

    func setText(first: String, second: String) {
        firstLabel.text = first
        secondLabel.text = second
    }
}

public protocol PluginScreenShareTabButtonDesignDependency: BaseAppearance {
    var selectedStateBackGroundColor: TextColorToken.Brand.Shade { get }
    var normalStateBackGroundColor: TextColorToken.Background.Shade { get }
    var cornerRadius: BorderRadiusToken.RadiusType { get }
    var titleColor: TextColorToken.Background.Shade { get }
    var activityIndicatorColor: TextColorToken.Background.Shade { get }
}

public class PluginScreenShareTabButtonDesignDependencyModel: PluginScreenShareTabButtonDesignDependency {
    public var designLibrary: RtkDesignTokens
    public var selectedStateBackGroundColor: TextColorToken.Brand.Shade
    public var normalStateBackGroundColor: TextColorToken.Background.Shade
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    public var titleColor: TextColorToken.Background.Shade
    public var activityIndicatorColor: TextColorToken.Background.Shade

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.designLibrary = designLibrary
        selectedStateBackGroundColor = designLibrary.color.textColor.onBrand.shade500
        normalStateBackGroundColor = designLibrary.color.textColor.onBackground.shade700
        titleColor = designLibrary.color.textColor.onBackground.shade900
        activityIndicatorColor = designLibrary.color.textColor.onBackground.shade900
    }
}

public class RtkPluginScreenShareTabButton: UIButton {
    private var normalImage: RtkImage?
    fileprivate var normalTitle: String
    private var selectedImage: RtkImage?
    fileprivate var selectedTitle: String?

    fileprivate var btnTitle: RtkLabel?
    private var baseActivityIndicatorView: BaseIndicatorView?
    fileprivate let appearance: PluginScreenShareTabButtonDesignDependency

    public var index: Int = 0
    public let id: String
    public var btnImageView: BaseImageView?

    public init(image: RtkImage?, title: String = "", id: String = "", appearance: PluginScreenShareTabButtonDesignDependency = PluginScreenShareTabButtonDesignDependencyModel()) {
        normalImage = image
        self.id = id
        self.appearance = appearance
        normalTitle = title
        super.init(frame: .zero)
        layer.cornerRadius = appearance.designLibrary.borderRadius.getRadius(size: .one, radius: appearance.cornerRadius)
        createButton()
        backgroundColor = appearance.normalStateBackGroundColor
        clipsToBounds = true
    }

    override public var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let image = selectedImage {
                    btnImageView?.setImage(image: image)
                }
                if let title = selectedTitle {
                    btnTitle?.setTextWhenInsideStackView(text: title)
                }
                backgroundColor = appearance.selectedStateBackGroundColor
            } else {
                if let image = normalImage {
                    btnImageView?.setImage(image: image)
                }
                btnTitle?.setTextWhenInsideStackView(text: normalTitle)
                backgroundColor = appearance.normalStateBackGroundColor
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setSelected(image: RtkImage) {
        selectedImage = RtkImage(image: image.image?.withRenderingMode(.alwaysTemplate), url: image.url)
    }

    public func setSelected(title: String) {
        selectedTitle = title
    }

    private func createButton() {
        let baseView = UIView()
        addSubview(baseView)
        baseView.set(.fillSuperView(self))
        baseView.isUserInteractionEnabled = false
        let buttonsComponent = getLabelAndImageOnlyView()
        btnTitle = buttonsComponent.title
        btnTitle?.setTextWhenInsideStackView(text: normalTitle)
        btnTitle?.textColor = appearance.titleColor
        btnImageView = buttonsComponent.imageView
        btnImageView?.tintColor = btnTitle?.textColor
        baseView.addSubview(buttonsComponent.stackView)
        buttonsComponent.stackView.set(.top(baseView, rtkSharedTokenSpace.space2, .greaterThanOrEqual),
                                       .centerY(baseView),
                                       .leading(baseView, rtkSharedTokenSpace.space2, .greaterThanOrEqual),
                                       .centerX(baseView))
    }

    private func getLabelAndImageOnlyView() -> (stackView: BaseStackView, title: RtkLabel, imageView: BaseImageView) {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: rtkSharedTokenSpace.space2)
        let imageView = RtkUIUtility.createImageView(image: normalImage)
        let title = RtkUIUtility.createLabel(text: normalTitle)
        title.font = UIFont.systemFont(ofSize: 14)
        stackView.addArrangedSubviews(imageView, title)
        return (stackView: stackView, title: title, imageView: imageView)
    }
}

public extension RtkPluginScreenShareTabButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        alpha = 0.6
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        alpha = 1.0
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        alpha = 1.0
    }
}

extension RtkPluginScreenShareTabButton {
    private func showActivityIndicator() {
        if baseActivityIndicatorView == nil {
            let baseIndicatorView = BaseIndicatorView.createIndicatorView()
            addSubview(baseIndicatorView)
            baseIndicatorView.set(.fillSuperView(self))
            baseActivityIndicatorView = baseIndicatorView
        }
        baseActivityIndicatorView?.indicatorView.color = appearance.activityIndicatorColor
        baseActivityIndicatorView?.indicatorView.startAnimating()
        baseActivityIndicatorView?.backgroundColor = backgroundColor
        bringSubviewToFront(baseActivityIndicatorView!)
        baseActivityIndicatorView?.isHidden = false
    }

    private func hideActivityIndicator() {
        baseActivityIndicatorView?.indicatorView.stopAnimating()
        baseActivityIndicatorView?.isHidden = true
    }
}

public class SyncScreenShareTabButton: RtkPluginScreenShareTabButton {
    override public var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let title = selectedTitle {
                    btnTitle?.setTextWhenInsideStackView(text: title)
                    backgroundColor = DesignLibrary.shared.color.status.danger
                }
            } else {
                btnTitle?.setTextWhenInsideStackView(text: normalTitle)
                backgroundColor = DesignLibrary.shared.color.status.success
            }
        }
    }
}
