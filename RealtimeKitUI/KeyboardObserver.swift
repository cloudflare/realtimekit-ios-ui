//
//  KeyboardObserver.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

class KeyboardObserver {
    private var onShowHandler: ((_ keyboardFrame: CGRect) -> Void)?
    private var onHideHandler: (() -> Void)?

    init(onShow: @escaping (_ keyboardFrame: CGRect) -> Void, onHide: @escaping () -> Void) {
        onShowHandler = onShow
        onHideHandler = onHide
        startObserving()
    }

    private func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func handleKeyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        onShowHandler?(keyboardFrame)
    }

    @objc private func handleKeyboardWillHide(notification _: Notification) {
        onHideHandler?()
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
        onShowHandler = nil
        onHideHandler = nil
    }
}
