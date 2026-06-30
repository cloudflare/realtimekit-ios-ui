//
//  RtkConnectedMeetingsListener.swift
//  RealtimeKitUI
//

import RealtimeKit
import UIKit

/// Bridges RtkConnectedMeetingsEventListener SDK callbacks to closure-based UI updates.
/// Follows the same pattern as RtkEventSelfListener / RtkMeetingEventListener.
final class RtkConnectedMeetingsListener: NSObject, RtkConnectedMeetingsEventListener {
    private let rtkClient: RealtimeKitClient

    // MARK: Callbacks

    /// Fired when breakout state changes (rooms created, deleted, participants moved).
    var onStateUpdate: ((_ meetings: [RtkConnectedMeeting], _ parentMeeting: RtkConnectedMeeting?) -> Void)?

    /// Fired before the local participant is switched to a new room.
    /// UI should show a loading/transition overlay.
    var onChangingMeeting: ((_ meetingId: String) -> Void)?

    /// Fired after the SDK has completed switching rooms.
    /// - nil error = success, re-register feature listeners and show meeting UI.
    /// - non-nil error = failure, show error or setup screen.
    var onMeetingChanged: ((_ error: MeetingError?) -> Void)?

    // MARK: Init

    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        super.init()
        rtkClient.addConnectedMeetingsEventListener(connectedMeetingsEventListener: self)
    }

    deinit {
        rtkClient.removeConnectedMeetingsEventListener(connectedMeetingsEventListener: self)
    }

    // MARK: RtkConnectedMeetingsEventListener

    func onStateUpdate(meetings: [RtkConnectedMeeting], parentMeeting: RtkConnectedMeeting?) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateUpdate?(meetings, parentMeeting)
        }
    }

    func onChangingMeeting(meetingId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onChangingMeeting?(meetingId)
        }
    }

    func onMeetingChanged(error: MeetingError?) {
        DispatchQueue.main.async { [weak self] in
            self?.onMeetingChanged?(error)
        }
    }
}
