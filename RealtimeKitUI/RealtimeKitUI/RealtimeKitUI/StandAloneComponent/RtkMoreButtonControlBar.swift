//
//  RtkMoreButtonControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

open class RtkMoreButtonControlBar: RtkControlBarButton {
    private let meeting: RealtimeKitClient
    private unowned let presentingViewController: UIViewController
    private let settingViewControllerCompletion: (() -> Void)?
    private var bottomSheet: RtkMoreMenuBottomSheet!

    public init(meeting: RealtimeKitClient, presentingViewController: UIViewController, settingViewControllerCompletion: (() -> Void)? = nil) {
        self.meeting = meeting
        self.settingViewControllerCompletion = settingViewControllerCompletion
        self.presentingViewController = presentingViewController
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_more_tabbar")), title: "More")
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        accessibilityIdentifier = "TabBar_More_Button"
        NotificationCenter.default.addObserver(self, selector: #selector(newChatArrived(notification:)), name: Notification.Name("Notify_NewChatArrived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newPollArrived(notification:)), name: Notification.Name("Notify_NewPollArrived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(participantUpdate(notification:)), name: Notification.Name("Notify_ParticipantListUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recordingUpdate(notification:)), name: Notification.Name("Notify_RecordingUpdate"), object: nil)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: RtkControlBarButton) {
        button.notificationBadge.isHidden = true
        createMoreMenu(shown: presentingViewController.view)
    }

    private func createMoreMenu(shown _: UIView) {
        bottomSheet = RtkMoreMenuBottomSheet(menus: getMenu(), meeting: meeting, presentingViewController: presentingViewController)
        bottomSheet.show()
    }

    private func isExtensionProperlyConfigured() -> Bool {
        guard let infoDictionary = Bundle.main.infoDictionary else { return false }
        guard let groupIdentifier = infoDictionary["RTKRTCAppGroupIdentifier"] else { return false }
        guard let groupIdentifier = infoDictionary["RTKRTCScreenSharingExtension"] else { return false }
        return true
    }

    private func getMenu() -> [MenuType] {
        var menus = [MenuType]()

        if meeting.localUser.permissions.host.canMuteAudio {
            menus.append(.muteAllAudio)
        }

        if meeting.localUser.permissions.host.canMuteVideo {
            menus.append(.muteAllVideo)
        }

        if meeting.localUser.canEnableScreenShare() {
            if isExtensionProperlyConfigured() == false {
                print("Please add upload extension in your main app to allow ScreenShare to work properly,\n Please follow Rtk documentation https://docs.realtime.cloudflare.com/ios-core/local-user/screen-share-guide")
            } else {
                if meeting.localUser.screenShareEnabled {
                    menus.append(.stopScreenShare)
                } else {
                    menus.append(.startScreenShare)
                }
            }
        }
        //        menus.append(.shareMeetingUrl)
        let recordingState = meeting.recording.recordingState
        let permissions = meeting.localUser.permissions

        let hostPermission = permissions.host
        if hostPermission.canTriggerRecording {
            if recordingState == .recording || recordingState == .starting {
                menus.append(.recordingStop)
            } else {
                menus.append(.recordingStart)
            }
        }
        let pluginPermission = permissions.plugins

        if pluginPermission.canLaunch {
            menus.append(.plugins)
        }

        let pollPermission = permissions.polls
        if pollPermission.canCreate || pollPermission.canView || pollPermission.canVote {
            let count = Shared.data.getUnviewPollCount(totalPolls: meeting.polls.items.count)
            menus.append(.poll(notificationMessage: count > 0 ? "\(count)" : ""))
        }

        menus.append(.settings)

        let chatCount = Shared.data.getUnreadChatCount(totalMessage: meeting.chat.messages.count)
        menus.append(.chat(notificationMessage: chatCount > 0 ? "\(chatCount)" : ""))

        var message = ""
        let pending = meeting.getPendingParticipantCount()

        if pending > 0 {
            message = "\(pending)"
        }
        menus.append(contentsOf: [.participants(notificationMessage: message), .cancel])
        return menus
    }

    @objc
    func newChatArrived(notification _: NSNotification) {
        bottomSheet?.reload(features: getMenu())
    }

    @objc
    func newPollArrived(notification _: NSNotification) {
        bottomSheet?.reload(features: getMenu())
    }

    @objc
    func recordingUpdate(notification _: NSNotification) {
        bottomSheet?.reload(features: getMenu())
    }

    @objc
    func participantUpdate(notification _: NSNotification) {
        bottomSheet?.reload(features: getMenu())
    }

    public func hideBottomSheet() {
        bottomSheet?.hide()
    }
}
