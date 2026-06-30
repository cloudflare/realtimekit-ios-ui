//
//  RtkMoreMenuBottomSheet.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import ReplayKit
import UIKit

class RtkMoreMenuBottomSheet {
    private let presentingViewController: UIViewController
    private let settingViewControllerCompletion: (() -> Void)?
    private let meeting: RealtimeKitClient

    init(menus: [MenuType], meeting: RealtimeKitClient, presentingViewController: UIViewController, settingViewControllerCompletion: (() -> Void)? = nil) {
        self.settingViewControllerCompletion = settingViewControllerCompletion
        self.presentingViewController = presentingViewController
        self.meeting = meeting

        create(menus: menus)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var moreMenu: RtkMoreMenu!

    func create(menus: [MenuType]) {
        moreMenu = RtkMoreMenu(features: menus, onSelect: { [weak self] menuType in
            guard let self else { return }
            switch menuType {
            case .muteAllAudio:
                muteAllAudio()
            case .muteAllVideo:
                muteAllVideo()
            case .shareMeetingUrl:
                shareMeetingUrl()
            case .chat:
                onChatTapped()
            case .startScreenShare:
                onScreenShareTapped()
            case .stopScreenShare:
                onStopScreenShareTapped()
            case .poll:
                launchPollsScreen()
            case .recordingStart:
                meeting.recording.start { _ in }
            case .recordingStop:
                meeting.recording.stop { _ in }
            case .settings:
                launchSettingScreen()
            case .plugins:
                onPluginTapped()
            case .participants:
                launchParticipantScreen()
            case .aiTranscript:
                launchAiTranscriptScreen()
            case .breakoutRooms:
                launchBreakoutRoomsScreen()
            default:
                print("Not Supported for now")
            }
        })
        moreMenu.accessibilityIdentifier = "MoreMenu_BottomSheet"
    }

    func reload(title: String? = nil, features: [MenuType]) {
        moreMenu.reload(title: title, features: features)
    }

    func show() {
        moreMenu.show(on: presentingViewController.view)
    }

    func hide() {
        moreMenu.hideSheet()
    }
}

private extension RtkMoreMenuBottomSheet {
    private func launchPollsScreen() {
        let controller = RtkShowPollsViewController(meeting: meeting)
        presentingViewController.present(controller, animated: true)
        Shared.data.setPollViewCount(totalPolls: meeting.polls.items.count)
    }

    private func launchSettingScreen() {
        let controller = RtkSettingViewController(nameTag: meeting.localUser.name, meeting: meeting, completion: settingViewControllerCompletion)
        controller.view.backgroundColor = presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        presentingViewController.present(controller, animated: true)
    }

    private func shareMeetingUrl() {
        if let name = URL(string: "https://demo.realtime.cloudflare.com/meeting?id=\(meeting.meta.meetingId)"), !name.absoluteString.isEmpty {
            let objectsToShare = [name]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            presentingViewController.present(activityVC, animated: true, completion: nil)
        } else {
            // show alert for not available
        }
    }

    private func muteAllAudio() {
        meeting.participants.disableAllAudio()
    }

    private func muteAllVideo() {
        meeting.participants.disableAllVideo()
    }

    private func launchParticipantScreen() {
        var controller: UIViewController = ParticipantViewControllerFactory.getParticipantViewController(meeting: meeting)

        if meeting.meta.meetingType == RtkMeetingType.webinar {
            controller = WebinarParticipantViewController(viewModel: WebinarParticipantViewControllerModel(rtkClient: meeting))
        }
        controller.view.backgroundColor = presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        presentingViewController.present(controller, animated: true)
    }

    private func onChatTapped() {
        let controller = RtkChatViewController(meeting: meeting)
        controller.modalPresentationStyle = .fullScreen
        presentingViewController.present(controller, animated: true, completion: nil)
        Shared.data.setChatReadCount(totalMessage: meeting.chat.messages.count)
    }

    private func onScreenShareTapped() {
        meeting.localUser.enableScreenShare(onResult: { error in
            if let error {
                print("RtkMoreMenuBottomSheet: enableScreenShare failed: \(error)")
            }
        })
    }

    private func onStopScreenShareTapped() {
        meeting.localUser.disableScreenShare(onResult: { error in
            if let error {
                print("RtkMoreMenuBottomSheet: disableScreenShare failed: \(error)")
            }
        })
    }

    private func launchAiTranscriptScreen() {
        let controller = RtkAiTranscriptViewController(meeting: meeting)
        controller.view.backgroundColor = presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        presentingViewController.present(controller, animated: true)
    }

    private func launchBreakoutRoomsScreen() {
        let controller = RtkBreakoutRoomsViewController(meeting: meeting)
        controller.modalPresentationStyle = .fullScreen
        // RTK-8210: hide the More Options overlay as soon as a room switch begins so the
        // sheet is not left open behind the meeting view after the breakout VC dismisses.
        controller.onRoomSwitchStarted = { [weak self] in
            self?.moreMenu?.hideSheet()
        }
        presentingViewController.present(controller, animated: true)
    }

    private func onPluginTapped() {
        let controller = RtkPluginViewController(plugins: meeting.plugins.all)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        presentingViewController.present(navigationController, animated: false, completion: nil)
    }
}
