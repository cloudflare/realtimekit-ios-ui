//
//  UIUtility.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public enum RtkUIUtility {
    public static func getTopViewController() -> UIViewController? {
        var topController = UIApplication.shared.windows.first?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        if let navController = topController as? UINavigationController {
            return navController.visibleViewController
        }

        return topController
    }

    public static func createLabel(text: String? = nil, alignment: NSTextAlignment = .center, weight: UIFont.Weight? = nil) -> RtkLabel {
        let label = RtkLabel()
        label.textAlignment = alignment
        label.text = text
        if weight != nil {
            if let currentFont = label.font {
                let newFontDescriptor = currentFont.fontDescriptor.addingAttributes([
                    .traits: [UIFontDescriptor.TraitKey.weight: weight],
                ])
                label.font = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
            }
        }

        return label
    }

    public static func wrapped(view: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(view)
        return wrapper
    }

    public static func createButton(text: String) -> RtkButton {
        let button = RtkButton(style: .solid, rtkButtonState: .active, appearance: AppTheme.shared.buttonAppearance)
        button.setTitle("  \(text)  ", for: .normal)
        return button
    }

    public static func createStackView(axis: NSLayoutConstraint.Axis, distribution: UIStackView.Distribution = .fill, spacing: CGFloat) -> BaseStackView {
        let stackView = BaseStackView()
        stackView.axis = axis
        stackView.distribution = distribution
        stackView.spacing = spacing
        return stackView
    }

    public static func createImageView(image: RtkImage?, contentMode: UIView.ContentMode = .scaleAspectFit) -> BaseImageView {
        let imageView = BaseImageView()
        imageView.setImage(image: image)
        imageView.contentMode = contentMode
        return imageView
    }

    public static func displayAlert(defaultActionTitle: String? = "OK", alertTitle: String, message: String) {
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: defaultActionTitle, style: .default, handler: nil)
        alertController.addAction(defaultAction)

        guard var topController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("keyWindow has no rootViewController")
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        topController.present(alertController, animated: true, completion: nil)
    }

    static func displayAlert(alertTitle: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        for action in actions {
            alertController.addAction(action)
        }

        guard var topController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("keyWindow has no rootViewController")
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        topController.present(alertController, animated: true, completion: nil)
    }
}
