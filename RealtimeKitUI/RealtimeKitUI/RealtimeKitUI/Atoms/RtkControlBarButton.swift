//
//  RtkControlBarButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 29/12/22.
//

import UIKit

public protocol RtkControlBarButtonAppearance: BaseAppearance {
    var cornerRadius: BorderRadiusToken.RadiusType { get }
    var selectedStateTintColor: TextColorToken.Background.Shade { get }
    var normalStateTintColor: TextColorToken.Background.Shade { get }
    var activityIndicatorColor: TextColorToken.Background.Shade { get }
}

public class RtkControlBarButtonAppearanceModel: RtkControlBarButtonAppearance {
    public var selectedStateTintColor: TextColorToken.Background.Shade
    public var normalStateTintColor: TextColorToken.Background.Shade
    public var activityIndicatorColor: TextColorToken.Background.Shade
    public var designLibrary: RtkDesignTokens
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.designLibrary = designLibrary
        selectedStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        normalStateTintColor = designLibrary.color.textColor.onBackground.shade1000
        activityIndicatorColor = designLibrary.color.textColor.onBackground.shade900
    }
}

open class RtkControlBarButton: UIButton {
    private var normalImage: RtkImage
    private var normalTitle: String
    private var selectedImage: RtkImage?
    private var selectedTitle: String?
    public var selectedStateTintColor: UIColor
    public var normalStateTintColor: UIColor

    private var btnImageView: UIImageView?
    var btnTitle: RtkLabel?
    private var baseActivityIndicatorView: BaseIndicatorView?
    private var previousTitle: String?

    public var notificationBadge = RtkNotificationBadgeView()
    let appearance: RtkControlBarButtonAppearance

    public init(image: RtkImage, title: String = "", appearance: RtkControlBarButtonAppearance = RtkControlBarButtonAppearanceModel()) {
        self.appearance = appearance
        normalImage = RtkImage(image: image.image?.withRenderingMode(.alwaysTemplate), url: image.url)
        normalTitle = title
        normalStateTintColor = self.appearance.normalStateTintColor
        selectedStateTintColor = self.appearance.selectedStateTintColor
        super.init(frame: .zero)
        layer.cornerRadius = self.appearance.designLibrary.borderRadius.getRadius(size: .one, radius: self.appearance.cornerRadius)
        createButton()
        backgroundColor = self.appearance.designLibrary.color.background.shade900
        clipsToBounds = true
    }

    override public var isEnabled: Bool {
        didSet {
            if isEnabled == false {
                btnImageView?.tintColor = appearance.designLibrary.color.textColor.onBackground.shade600
            } else {
                btnImageView?.tintColor = appearance.designLibrary.color.textColor.onBackground.shade1000
            }
        }
    }

    override public var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let image = selectedImage {
                    btnImageView?.image = image.image
                }
                btnImageView?.tintColor = selectedStateTintColor
                if let title = selectedTitle {
                    btnTitle?.setTextWhenInsideStackView(text: title)
                }
            } else {
                btnImageView?.image = normalImage.image
                btnImageView?.tintColor = normalStateTintColor
                btnTitle?.setTextWhenInsideStackView(text: normalTitle)
            }
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setSelected(image: RtkImage? = nil, title: String? = nil) {
        selectedImage = RtkImage(image: image?.image?.withRenderingMode(.alwaysTemplate), url: image?.url)
        selectedTitle = title
        isSelected = true
    }

    public func setDefault(image: RtkImage? = nil, title: String? = nil) {
        normalImage = RtkImage(image: image?.image?.withRenderingMode(.alwaysTemplate), url: image?.url)
        if let title {
            normalTitle = title
        }
        isSelected = false
    }

    private func createButton() {
        let baseView = UIView()
        addSubview(baseView)
        baseView.set(.fillSuperView(self, rtkSharedTokenSpace.space1))
        baseView.isUserInteractionEnabled = false
        let buttonsComponent = getLabelAndImageOnlyView()
        btnTitle = buttonsComponent.title
        btnTitle?.setTextWhenInsideStackView(text: normalTitle)
        btnTitle?.textColor = appearance.designLibrary.color.textColor.onBackground.shade1000
        btnImageView = buttonsComponent.imageView
        btnImageView?.tintColor = appearance.designLibrary.color.textColor.onBackground.shade1000
        baseView.addSubview(buttonsComponent.stackView)
        buttonsComponent.stackView.set(.top(baseView, 0.0, .greaterThanOrEqual),
                                       .centerY(baseView),
                                       .leading(baseView, 0.0, .greaterThanOrEqual),
                                       .centerX(baseView))
        baseView.addSubview(notificationBadge)
        let height = rtkSharedTokenSpace.space4
        notificationBadge.set(.top(baseView),
                              .trailing(baseView),
                              .height(height),
                              .width(height * 2.5, .lessThanOrEqual))
        notificationBadge.layer.cornerRadius = height / 2.0
        notificationBadge.layer.masksToBounds = true
        notificationBadge.backgroundColor = rtkSharedTokenColor.brand.shade500
        notificationBadge.isHidden = true
    }

    private func getLabelAndImageOnlyView() -> (stackView: BaseStackView, title: RtkLabel, imageView: UIImageView) {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 4)
        let imageView = RtkUIUtility.createImageView(image: normalImage)
        let title = RtkUIUtility.createLabel(text: normalTitle)
        title.font = UIFont.systemFont(ofSize: 12)
        title.minimumScaleFactor = 0.7
        title.adjustsFontSizeToFitWidth = true
        stackView.addArrangedSubviews(imageView, title)
        return (stackView: stackView, title: title, imageView: imageView)
    }

    func clean() {}
}

public extension RtkControlBarButton {
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

extension RtkControlBarButton {
    func showActivityIndicator(title: String = "") {
        previousTitle = btnTitle?.text
        if baseActivityIndicatorView == nil {
            let baseIndicatorView = BaseIndicatorView.createIndicatorView()
            baseActivityIndicatorView = baseIndicatorView
        }
        baseActivityIndicatorView?.removeFromSuperview()
        if title.count >= 0 {
            if let baseActivityIndicatorView, let btnImageView {
                btnImageView.addSubview(baseActivityIndicatorView)
                baseActivityIndicatorView.set(.fillSuperView(btnImageView))
                baseActivityIndicatorView.isHidden = true
            }
        } else {
            if let baseActivityIndicatorView {
                addSubview(baseActivityIndicatorView)
                baseActivityIndicatorView.set(.fillSuperView(self))
                baseActivityIndicatorView.isHidden = true
            }
        }
        if baseActivityIndicatorView?.isHidden == true {
            baseActivityIndicatorView?.indicatorView.color = appearance.activityIndicatorColor
            baseActivityIndicatorView?.indicatorView.startAnimating()
            baseActivityIndicatorView?.backgroundColor = backgroundColor
            bringSubviewToFront(baseActivityIndicatorView!)
            baseActivityIndicatorView?.isHidden = false
            isUserInteractionEnabled = false
            btnTitle?.setTextWhenInsideStackView(text: title)
        }
    }

    func hideActivityIndicator() {
        if let title = previousTitle {
            btnTitle?.setTextWhenInsideStackView(text: title)
        }

        if baseActivityIndicatorView?.isHidden == false {
            baseActivityIndicatorView?.indicatorView.stopAnimating()
            baseActivityIndicatorView?.isHidden = true
            isUserInteractionEnabled = true
        }
    }
}

public class RtkControlBarSpacerButton: RtkControlBarButton {
    public init(space: CGSize) {
        super.init(image: RtkImage())
        set(.size(space.width, space.height))
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
