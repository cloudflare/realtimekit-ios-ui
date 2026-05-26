//
//  UIViewExtension.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 07/12/22.
//

import UIKit

let toastTag = 5555

extension UIViewController {
    var isOnScreen: Bool {
        isViewLoaded && view.window != nil
    }
}

extension UIView {
    func wrapperView() -> UIView {
        let view = UIView()
        view.addSubview(self)
        return view
    }

    func blink() {
        alpha = 0.2
        UIView.animate(withDuration: 1, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: { self.alpha = 1.0 }, completion: nil)
    }

    func stopBlink() {
        layer.removeAllAnimations()
    }

    func getSubviewsOf<T: UIView>(view: UIView) -> [T] {
        var subviews = [T]()

        for subview in view.subviews {
            subviews += getSubviewsOf(view: subview) as [T]

            if let subview = subview as? T {
                subviews.append(subview)
            }
        }

        return subviews
    }

    func addSubViews(_ views: UIView...) {
        for view in views {
            addSubview(view)
        }
    }
}

// MARK: Add Toast method function in UIView Extension so can use in whole project.

extension UIView {
    func removeToast() {
        viewWithTag(toastTag)?.removeFromSuperview()
    }

    func showToast(toastMessage: String, duration: CGFloat, uiBlocker: Bool = true, showInBottom: Bool = false, bottomSpace: CGFloat = 0) {
        DispatchQueue.main.async {
            // View to blur bg and stopping user interaction
            self.removeToast()
            let toastView = self.createToastView(toastMessage: toastMessage, duration: duration, uiBlocker: uiBlocker, bottom: showInBottom, bottomSpace: bottomSpace)
            toastView.tag = toastTag
            self.addSubview(toastView)
            toastView.set(.fillSuperView(self))
        }
    }

    private func createToastView(toastMessage: String, duration: CGFloat, uiBlocker: Bool, bottom: Bool, bottomSpace: CGFloat) -> UIView {
        let bgView = UIView(frame: frame)
        bgView.backgroundColor = UIColor(red: CGFloat(255.0 / 255.0), green: CGFloat(255.0 / 255.0), blue: CGFloat(255.0 / 255.0), alpha: CGFloat(0.1))
        // Label For showing toast text
        let lblMessage = UILabel()
        lblMessage.numberOfLines = 2
        lblMessage.lineBreakMode = .byWordWrapping
        lblMessage.textColor = .white
        lblMessage.textAlignment = .center
        lblMessage.font = UIFont(name: "Helvetica Neue", size: 17)
        lblMessage.text = toastMessage
        lblMessage.layer.cornerRadius = 8
        lblMessage.layer.masksToBounds = true
        let baseLabelView = lblMessage.wrapperView()
        bgView.addSubview(baseLabelView)
        baseLabelView.addSubview(lblMessage)
        lblMessage.set(.fillSuperView(baseLabelView, 8))
        baseLabelView.layer.cornerRadius = 8
        baseLabelView.layer.masksToBounds = true
        baseLabelView.backgroundColor = UIColor(red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: CGFloat(0.8))

        baseLabelView.set(.leading(bgView, 16, .greaterThanOrEqual), .centerX(bgView))
        if bottom == false {
            baseLabelView.set(.centerY(bgView))
        } else {
            baseLabelView.set(.bottom(bgView, 16 + bottomSpace))
        }

        if duration >= 0 {
            UIView.animate(withDuration: 2.5, delay: TimeInterval(duration)) {
                baseLabelView.alpha = 0
                bgView.alpha = 0
            } completion: { _ in
                bgView.removeFromSuperview()
            }
        }
        bgView.isUserInteractionEnabled = uiBlocker
        return bgView
    }

    func setRandomColor(view: UIView) {
        view.backgroundColor = getRandomColor()
        for subview in view.subviews {
            setRandomColor(view: subview)
        }
    }

    private func getRandomColor() -> UIColor {
        // Generate between 0 to 1
        let red = CGFloat(drand48())
        let green = CGFloat(drand48())
        let blue = CGFloat(drand48())

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension CGFloat {
    func getMinimum(value2: CGFloat) -> CGFloat {
        if self < value2 {
            self
        } else {
            value2
        }
    }
}

extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        for view in views {
            addArrangedSubview(view)
        }
    }

    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}

extension UIViewController {
    var isModal: Bool {
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
}

@nonobjc extension UIViewController {
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)
        DispatchQueue.main.async {
            if let frame {
                child.view.frame = frame
            }
            self.view.addSubview(child.view)
            child.didMove(toParent: self)
        }
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension UITableViewCell: ReusableObject {}

extension UISearchBar {
    func changeText(color: UIColor) {
        if let textFieldInsideSearchBar = value(forKey: "searchField") as? UITextField,
           let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView
        {
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = color
            textFieldInsideSearchBar.textColor = color
        }
        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: color]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
    }
}

extension Bundle {
    static let resources: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            return Bundle(for: ImageProvider.self)
        #endif
    }()
}

extension UIViewController {
    func isLandscape(size: CGSize) -> Bool {
        size.width > size.height
    }
}

extension UIScreen {
    static var deviceOrientation: UIDeviceOrientation {
        var interfaceOrientation: UIInterfaceOrientation = .portrait
        if #available(iOS 13.0, *) {
            if let orientation = UIApplication.shared.windows
                .first?
                .windowScene?
                .interfaceOrientation
            {
                interfaceOrientation = orientation
            }
        } else {
            interfaceOrientation = UIApplication.shared.statusBarOrientation
        }

        switch interfaceOrientation {
        case .portrait:
            return .portrait

        case .portraitUpsideDown:
            return .portraitUpsideDown

        case .landscapeLeft:
            return .landscapeLeft

        case .landscapeRight:
            return .landscapeRight

        case .unknown:
            return .unknown

        @unknown default:
            return .unknown
        }
    }

    static func isLandscape() -> Bool {
        if UIScreen.deviceOrientation == .landscapeLeft || UIScreen.deviceOrientation == .landscapeRight {
            return true
        }
        return false
    }
}

extension RtkLabel {
    func numberOfLinesRequired() -> Int {
        guard let text, let font else {
            return 0
        }

        let labelWidth = frame.width
        let singleLineHeight = font.lineHeight

        // Calculate the height required for the text
        let maxSize = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font]
        let boundingRect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        let requiredHeight = ceil(boundingRect.height)
        // Calculate the number of lines needed
        return Int(requiredHeight / singleLineHeight)
    }
}
