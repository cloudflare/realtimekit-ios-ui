//
//  RtkJoinButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 08/02/23.
//

import RealtimeKit
import UIKit

open class RtkJoinButton: RtkButton {
    let completion: ((RtkJoinButton, Bool) -> Void)?
    private let meeting: RealtimeKitClient

    public init(meeting: RealtimeKitClient, onClick: ((RtkJoinButton, Bool) -> Void)? = nil, appearance: RtkButtonAppearance = AppTheme.shared.buttonAppearance) {
        self.meeting = meeting
        completion = onClick
        super.init(appearance: appearance)
        setTitle("  Join  ", for: .normal)
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: RtkJoinButton) {
        let userName = meeting.localUser.name
        if userName.trimmingCharacters(in: .whitespaces).isEmpty || userName == "Join as XYZ" {
            RtkUIUtility.displayAlert(alertTitle: "Error", message: "Name Required")
        } else {
            button.showActivityIndicator()
            meeting.joinRoom(onSuccess: { [weak self] in
                guard let self else { return }
                button.hideActivityIndicator()
                completion?(button, true)
            }, onFailure: { [weak self] _ in
                guard let self else { return }
                button.hideActivityIndicator()
                completion?(button, false)
            })
        }
    }
}
