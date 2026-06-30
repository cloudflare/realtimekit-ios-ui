//
//  BaseProtocols.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

protocol Searchable {
    func search(text: String) -> Bool
}

protocol ReusableObject: AnyObject {}

extension ReusableObject {
    public static var reuseIdentifier: String {
        String(describing: self)
    }
}

public protocol SetTopbar {
    var topBar: RtkNavigationBar { get }
    var shouldShowTopBar: Bool { get }
}

extension SetTopbar where Self: UIViewController {
    func addTopBar(dismissAnimation: Bool, completion: (() -> Void)? = nil) {
        view.addSubview(topBar)
        if shouldShowTopBar {
            topBar.setBackButtonClick { [weak self] _ in
                guard let self else { return }
                if isModal {
                    dismiss(animated: dismissAnimation, completion: completion)
                } else {
                    navigationController?.popViewController(animated: dismissAnimation)
                    completion?()
                }
            }
            topBar.set(.sameLeadingTrailing(view),
                       .top(view),
                       .height(44))
        } else {
            topBar.set(.sameLeadingTrailing(view),
                       .top(view),
                       .height(0))
        }
    }
}

protocol KeyboardObservable: AnyObject {
    var keyboardObserver: KeyboardObserver? { get set }
    func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                onHide: @escaping () -> Void)
    func stopKeyboardObserving()
}

extension KeyboardObservable {
    public func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                       onHide: @escaping () -> Void)
    {
        keyboardObserver = KeyboardObserver(onShow: onShow, onHide: onHide)
    }

    public func stopKeyboardObserving() {
        keyboardObserver?.stopObserving()
        keyboardObserver = nil
    }
}
