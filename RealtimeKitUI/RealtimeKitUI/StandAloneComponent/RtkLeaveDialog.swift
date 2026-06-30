//
//  RtkLeaveDialog.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public class RtkLeaveDialog {
    public static let onEndMeetingForAllButtonPress: Notification.Name = .init("onEndMeetingForAllButtonPress")
    public enum RtkLeaveDialogAlertButtonType {
        case willLeaveMeeting
        case didLeaveMeeting

        case willEndMeetingForAll
        case didEndMeetingForAll

        case cancel
        case nothing
    }

    private let meeting: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener
    private let onClick: ((RtkLeaveDialogAlertButtonType) -> Void)?

    public init(meeting: RealtimeKitClient, onClick: ((RtkLeaveDialogAlertButtonType) -> Void)? = nil) {
        self.meeting = meeting
        rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        self.onClick = onClick
    }

    deinit {
        self.rtkSelfListener.clean()
    }

    public func show(on viewController: UIViewController) {
        showEndCallAlert(title: "Leave call?", message: "Do you really want to leave this call?", presentingController: viewController)
    }

    private func showEndCallAlert(title: String, message: String, presentingController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // RTK-8220: offer "Go Back to Main Room" when the user is inside a breakout room
        // and has permission to switch back to the parent meeting.
        let connPerms = meeting.localUser.permissions.connectedMeetings
        let isInBreakoutRoom = meeting.connectedMeetings.isActive &&
            meeting.connectedMeetings.meetings.contains { room in
                room.participants.contains { $0.id == self.meeting.localUser.userId }
            }
        if isInBreakoutRoom, connPerms.canSwitchToParentMeeting {
            alert.addAction(UIAlertAction(title: "Go Back to Main Room", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                let sourceMeetingId = meeting.connectedMeetings.meetings
                    .first { room in room.participants.contains { $0.id == self.meeting.localUser.userId } }?.id
                let parentMeetingId = meeting.connectedMeetings.parentMeeting?.id
                if let src = sourceMeetingId, let dest = parentMeetingId {
                    meeting.connectedMeetings.moveParticipants(
                        sourceMeetingId: src,
                        destinationMeetingId: dest,
                        participantIds: [meeting.localUser.userId],
                    ) { [weak presentingController] error in
                        guard let error else { return }
                        DispatchQueue.main.async {
                            let errorAlert = UIAlertController(
                                title: "Error",
                                message: error.message,
                                preferredStyle: .alert,
                            )
                            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            presentingController?.present(errorAlert, animated: true)
                        }
                    }
                }
            }))
        }

        alert.addAction(UIAlertAction(title: "Leave", style: .default, handler: { _ in
            self.onClick?(.willLeaveMeeting)
            self.rtkSelfListener.leaveMeeting(kickAll: false, completion: { _ in
                // We have not used weak self, Because we want Delayed deallocation of UIAlertController in memory
                self.onClick?(.didLeaveMeeting)
            })
        }))

        if meeting.localUser.permissions.host.canKickParticipant {
            alert.addAction(UIAlertAction(title: "End Meeting for all", style: .default, handler: { _ in
                self.onClick?(.willEndMeetingForAll)
                NotificationCenter.default.post(name: Self.onEndMeetingForAllButtonPress, object: nil)

                self.rtkSelfListener.leaveMeeting(kickAll: true, completion: { _ in
                    self.onClick?(.didEndMeetingForAll)
                })
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.onClick?(.cancel)
        }))
        alert.view.accessibilityIdentifier = "Leave_Meeting_Alert"
        presentingController.present(alert, animated: true, completion: nil)
    }
}
