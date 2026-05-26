//
//  WebinarViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 17/04/23.
//

import RealtimeKit
import UIKit

public enum WebinarStageStatus {
    case canJoinStage
    case joiningStage
    case alreadyOnStage
    case leavingFromStage
    case canRequestToJoinStage
    case requestingToJoinStage
    case inRequestedStateToJoinStage
    case viewOnly
}

public class WebinarViewController: MeetingViewController {
    private var waitingView: WaitingRoomView?
    var webinarViewModel: WebinarViewModel?

    override public func viewDidLoad() {
        super.viewDidLoad()
        webinarViewModel = WebinarViewModel(rtkClient: meeting)
        webinarViewModel?.stageDelegate = self
    }

    func createWaitingView(message: String) -> WaitingRoomView {
        let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {})
        waitingView.backgroundColor = view.backgroundColor
        gridBaseView.addSubview(waitingView)
        waitingView.set(.fillSuperView(gridBaseView))
        waitingView.button.isHidden = true
        waitingView.show(message: message)
        return waitingView
    }

    override public func refreshMeetingGrid(forRotation: Bool = false) {
        super.refreshMeetingGrid(forRotation: forRotation)
        waitingView?.removeFromSuperview()
        let mediaPermission = meeting.localUser.permissions.media

        if mediaPermission.audioPermission == MediaPermission.allowed || mediaPermission.video.permission == MediaPermission.allowed, meeting.participants.active.isEmpty, StageStatus.getStageStatus(rtkClient: meeting) == .canJoinStage {
            waitingView = createWaitingView(message: "The stage is empty.\nYou are off stage. You can manage stage request from the participants tab.")
        } else if meeting.participants.active.isEmpty, meeting.localUser.stageStatus != .onStage {
            waitingView = createWaitingView(message: "Webinar has not yet been started")
        }
    }

    override func getBottomBar() -> RtkControlBar {
        getTabBar()
    }

    func getTabBar() -> RtkControlBar {
        RtkWebinarControlBar(meeting: meeting, delegate: nil, dataSource: nil, presentingViewController: self) { _ in
        } settingViewControllerCompletion: {
            [weak self] in
            guard let self else { return }
            refreshMeetingGridTile(participant: meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self else { return }
            viewModel.clean()
            onFinishedMeeting()
        }
    }

    func updateNotificationWithToast(message: String) {
        view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false)
        updateMoreButtonNotificationBubble()
        NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
    }
}

extension WebinarViewController: @preconcurrency RtkStageDelegate {
    func onPresentRequestAdded(participant: RtkRemoteParticipant) {
        updateNotificationWithToast(message: "\(participant.name) has requested to join stage")
    }

    func onPresentRequestWithdrawn(participant: RtkRemoteParticipant) {
        updateNotificationWithToast(message: "\(participant.name) has cancelled to join stage")
    }
}
