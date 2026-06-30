//
//  RtkParticipantCountView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public class RtkParticipantCountView: RtkLabel {
    private let meeting: RealtimeKitClient

    public init(meeting: RealtimeKitClient, appearance: RtkTextAppearance = AppTheme.shared.participantCountAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        text = ""
        self.meeting.addParticipantsEventListener(participantsEventListener: self)
        self.meeting.addMeetingRoomEventListener(meetingRoomEventListener: self)
        update()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.meeting.removeParticipantsEventListener(participantsEventListener: self)
    }

    private func update() {
        let participantCount = meeting.participants.totalCount
        if participantCount <= 1 {
            text = "Only you"
        } else {
            text = "\(participantCount) participants"
        }
    }
}

extension RtkParticipantCountView: RtkMeetingRoomEventListener {
    public func onActiveTabUpdate(meeting _: RealtimeKitClient, activeTab _: ActiveTab) {}

    public func onMeetingEnded() {}

    public func onMeetingInitCompleted(meeting _: RealtimeKitClient) {}

    public func onMeetingInitFailed(error _: MeetingError) {}

    public func onMeetingInitStarted() {}

    public func onMeetingRoomJoinCompleted(meeting _: RealtimeKitClient) {}

    public func onMeetingRoomJoinFailed(error _: MeetingError) {}

    public func onMeetingRoomJoinStarted() {}

    public func onMeetingRoomLeaveCompleted() {}

    public func onMeetingRoomLeaveStarted() {}

    public func onMediaConnectionUpdate(update _: MediaConnectionUpdate) {}

    public func onSocketConnectionUpdate(newState: SocketConnectionState) {
        if newState.socketState == SocketState.connected {
            update()
        }
    }
}

extension RtkParticipantCountView: RtkParticipantsEventListener {
    public func onAllParticipantsUpdated(allParticipants _: [RtkParticipant]) {}

    public func onUpdate(participants _: RtkParticipants) {}

    public func onParticipantJoin(participant _: RtkRemoteParticipant) {
        update()
    }

    public func onParticipantLeave(participant _: RtkRemoteParticipant) {
        update()
    }

    public func onActiveParticipantsChanged(active _: [RtkRemoteParticipant]) {}

    public func onActiveSpeakerChanged(participant _: RtkRemoteParticipant?) {}

    public func onAudioUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onNewBroadcastMessage(type _: String, payload _: [String: Any]) {}

    public func onParticipantPinned(participant _: RtkRemoteParticipant) {}

    public func onParticipantUnpinned(participant _: RtkRemoteParticipant) {}

    public func onScreenShareUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onVideoUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}
}
