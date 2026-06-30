//
//  RtkEndMeetingButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 30/06/23.
//
import RealtimeKit
import UIKit

open class RtkEndMeetingControlBarButton: RtkControlBarButton {
    private let meeting: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener
    private let onClick: ((RtkEndMeetingControlBarButton, RtkLeaveDialog.RtkLeaveDialogAlertButtonType) -> Void)?
    public var shouldShowAlertOnClick = true
    private let alertPresentingController: UIViewController

    public init(meeting: RealtimeKitClient, alertViewController: UIViewController, onClick: ((RtkEndMeetingControlBarButton, RtkLeaveDialog.RtkLeaveDialogAlertButtonType) -> Void)? = nil, appearance: RtkControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        self.meeting = meeting
        alertPresentingController = alertViewController
        self.onClick = onClick
        rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_end_meeting_tabbar")), title: "", appearance: appearance)
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        DispatchQueue.main.async {
            self.backgroundColor = appearance.designLibrary.color.status.danger
            self.set(.width(48),
                     .height(48))
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: RtkEndMeetingControlBarButton) {
        if shouldShowAlertOnClick {
            let dialog = RtkLeaveDialog(meeting: meeting) { alertAction in
                if alertAction == .willLeaveMeeting || alertAction == .willEndMeetingForAll {
                    self.showActivityIndicator()
                } else if alertAction == .didLeaveMeeting || alertAction == .didEndMeetingForAll {
                    self.hideActivityIndicator()
                    if alertAction == .didLeaveMeeting {
                        self.onClick?(self, .didLeaveMeeting)
                    } else if alertAction == .didEndMeetingForAll {
                        self.onClick?(self, .didEndMeetingForAll)
                    }
                }
            }
            dialog.show(on: alertPresentingController)
        } else {
            // When we are not showing alert then on clicking we can directly end call
            showActivityIndicator()
            rtkSelfListener.leaveMeeting(kickAll: false, completion: { [weak self] _ in
                guard let self else { return }
                hideActivityIndicator()
                onClick?(button, .nothing)
            })
        }
    }

    deinit {
        self.rtkSelfListener.clean()
    }
}
