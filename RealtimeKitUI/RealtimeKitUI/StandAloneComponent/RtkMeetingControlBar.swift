//
//  RtkMeetingControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public protocol RtkMeetingControlBarDataSource: AnyObject {
    func getMicControlBarButton(for meeting: RealtimeKitClient) -> RtkControlBarButton?
    func getVideoControlBarButton(for meeting: RealtimeKitClient) -> RtkControlBarButton?
}

open class RtkMeetingControlBar: RtkControlBar {
    public weak var dataSource: RtkMeetingControlBarDataSource? {
        didSet {
            if dataSource != nil {
                addButtons(meeting: meeting)
            }
        }
    }

    private let meeting: RealtimeKitClient

    override public init(meeting: RealtimeKitClient, delegate: RtkTabBarDelegate?, presentingViewController: UIViewController, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel(), settingViewControllerCompletion: (() -> Void)? = nil, onLeaveMeetingCompletion: (() -> Void)? = nil) {
        self.meeting = meeting
        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, appearance: appearance, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
        addButtons(meeting: meeting)
        setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }

    override func onRotationChange() {
        super.onRotationChange()
        setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }

    private func addButtons(meeting: RealtimeKitClient) {
        var buttons = [RtkControlBarButton]()
        if meeting.localUser.permissions.media.canPublishAudio {
            let micButton = dataSource?.getMicControlBarButton(for: meeting) ?? RtkAudioButtonControlBar(meeting: meeting)
            buttons.append(micButton)
        }
        if meeting.localUser.permissions.media.canPublishVideo {
            let videoButton = dataSource?.getVideoControlBarButton(for: meeting) ?? RtkVideoButtonControlBar(rtkClient: meeting)
            buttons.append(videoButton)
        }
        if buttons.count > 0 {
            setButtons(buttons)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
