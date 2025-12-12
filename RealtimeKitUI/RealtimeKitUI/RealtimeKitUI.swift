//
//  RealtimeKitUI.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 30/01/23.
//

import Foundation
import RealtimeKit
import UIKit

public class RtkNotificationConfig {
    public class RtkNotification {
        public var playSound = true
        public var showToast = true

        init(playSound: Bool = true, showToast: Bool = true) {
            self.playSound = playSound
            self.showToast = showToast
        }
    }

    public var participantJoined = RtkNotification()
    public var participantLeft = RtkNotification()
    public var newChatArrived = RtkNotification()
    public var newPollArrived = RtkNotification()
}

public protocol RealtimeKitUILifeCycle {
    func webinarJoinStagePopupDidShow()
    func webinarJoinStagePopupDidHide(click buttonType: RealtimeKitUI.WebinarAlertButtonType)
    func meetingScreenDidShow()
    func meetingScreenWillShow()
}

public protocol RtkUIFlowCoordinatorDelegate {
    func showSetUpScreen(completion: () -> Void) -> SetupViewControllerDataSource?
    func showGroupCallMeetingScreen(meeting: RealtimeKitClient, completion: @escaping () -> Void) -> UIViewController?
    func showWebinarMeetingScreen(meeting: RealtimeKitClient, completion: @escaping () -> Void) -> UIViewController?
}

public class RealtimeKitUI {
    public enum WebinarAlertButtonType {
        case confirmAndJoin
        case cancel
    }

    private let configurationV2: RtkMeetingInfo
    public let rtkClient: RealtimeKitClient
    public let appTheme: AppTheme
    public let designLibrary: DesignLibrary
    public let notification = RtkNotificationConfig()
    public let flowDelegate: RtkUIFlowCoordinatorDelegate?
    var completion: (() -> Void)!

    #if DEBUG
        static let isDebugModeOn = true
    #else
        static let isDebugModeOn = false
    #endif

    public var delegate: RealtimeKitUILifeCycle? {
        didSet {
            Shared.data.delegate = delegate
        }
    }

    public init(meetingInfo: RtkMeetingInfo, flowDelegate: RtkUIFlowCoordinatorDelegate? = nil) {
        self.flowDelegate = flowDelegate
        rtkClient = RealtimeKitiOSClientBuilder().build()
        designLibrary = DesignLibrary.shared
        appTheme = AppTheme(designTokens: designLibrary)
        configurationV2 = meetingInfo
    }

    public func startMeeting(completion: @escaping () -> Void) -> UIViewController {
        Shared.data.initialise()
        Shared.data.notification = notification
        self.completion = completion
        if let viewController = flowDelegate?.showSetUpScreen(completion: completion) {
            viewController.delegate = self
            return viewController
        } else {
            return getSetUpViewController(configuration: configurationV2, completion: completion)
        }
    }
}

extension RealtimeKitClient {
    func getWaitlistCount() -> Int {
        participants.waitlisted.count
    }

    func getWebinarCount() -> Int {
        stage.accessRequests.count
    }

    func getPendingParticipantCount() -> Int {
        getWebinarCount() + getWaitlistCount()
    }
}

extension RealtimeKitUI {
    private func getSetUpViewController(configuration: RtkMeetingInfo, completion: @escaping () -> Void) -> RtkSetupViewController {
        let controller = RtkSetupViewController(meetingInfo: configuration, meeting: rtkClient, completion: completion)
        controller.delegate = self
        return controller
    }

    private func launchMeetingScreen(on viewController: UIViewController, completion: @escaping () -> Void) {
        Shared.data.delegate?.meetingScreenWillShow()
        let meetingViewController = getMeetingScreen(meetingType: rtkClient.meta.meetingType, completion: completion)
        meetingViewController.modalPresentationStyle = .fullScreen
        viewController.present(meetingViewController, animated: true) {
            Shared.data.delegate?.meetingScreenDidShow()
        }
        notificationDelegate?.didReceiveNotification(type: .Joined)
    }

    private func getMeetingScreen(meetingType _: RtkMeetingType, completion: @escaping () -> Void) -> UIViewController {
        if rtkClient.meta.meetingType == RtkMeetingType.groupCall {
            if let viewController = flowDelegate?.showGroupCallMeetingScreen(meeting: rtkClient, completion: completion) {
                return viewController
            }
            return MeetingViewController(meeting: rtkClient, completion: completion)
        } else if rtkClient.meta.meetingType == RtkMeetingType.webinar {
            if let viewController = flowDelegate?.showWebinarMeetingScreen(meeting: rtkClient, completion: completion) {
                return viewController
            }
            return WebinarViewController(meeting: rtkClient, completion: completion)
        }
        fatalError("Unknown Meeting type not supported")
    }
}

extension RealtimeKitUI: SetupViewControllerDelegate {
    public func userJoinedMeetingSuccessfully(sender: UIViewController) {
        launchMeetingScreen(on: sender, completion: completion)
    }
}
