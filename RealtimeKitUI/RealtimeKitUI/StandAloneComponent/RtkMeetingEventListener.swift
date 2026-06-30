//
//  RtkMeetingEventListener.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/02/23.
//

import RealtimeKit

class RtkMeetingEventListener {
    private var selfAudioStateCompletion: ((Bool) -> Void)?
    private var recordMeetingStartCompletion: ((Bool) -> Void)?
    private var recordMeetingStopCompletion: ((Bool) -> Void)?
    private var selfJoinedStateCompletion: ((Bool) -> Void)?
    private var selfLeaveStateCompletion: ((Bool) -> Void)?
    private var participantLeaveStateCompletion: ((RtkMeetingParticipant) -> Void)?
    private var participantJoinStateCompletion: ((RtkMeetingParticipant) -> Void)?
    private var participantPinnedStateCompletion: ((RtkMeetingParticipant) -> Void)?
    private var participantUnPinnedStateCompletion: ((RtkMeetingParticipant) -> Void)?

    var rtkClient: RealtimeKitClient

    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.rtkClient.addRecordingEventListener(recordingEventListener: self)
        self.rtkClient.addParticipantsEventListener(participantsEventListener: self)
    }

    func clean() {
        rtkClient.removeParticipantsEventListener(participantsEventListener: self)
        rtkClient.removeRecordingEventListener(recordingEventListener: self)
    }

    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn

    func startRecordMeeting(completion: @escaping (_ success: Bool) -> Void) {
        recordMeetingStartCompletion = completion
        rtkClient.recording.start { _ in }
    }

    func stopRecordMeeting(completion: @escaping (_ success: Bool) -> Void) {
        recordMeetingStopCompletion = completion
        rtkClient.recording.stop { _ in }
    }

    func joinMeeting(completion: @escaping (_ success: Bool) -> Void) {
        selfJoinedStateCompletion = completion
        rtkClient.joinRoom(onSuccess: {}, onFailure: { _ in })
    }

    func leaveMeeting(completion: @escaping (_ success: Bool) -> Void) {
        selfLeaveStateCompletion = completion
        rtkClient.leaveRoom(onSuccess: {}, onFailure: { _ in })
    }

    func observeParticipantJoin(update: @escaping (_ participant: RtkMeetingParticipant) -> Void) {
        participantJoinStateCompletion = update
    }

    func observeParticipantLeave(update: @escaping (_ participant: RtkMeetingParticipant) -> Void) {
        participantLeaveStateCompletion = update
    }

    func observeParticipantPinned(update: @escaping (_ participant: RtkMeetingParticipant) -> Void) {
        participantPinnedStateCompletion = update
    }

    func observeParticipantUnPinned(update: @escaping (_ participant: RtkMeetingParticipant) -> Void) {
        participantUnPinnedStateCompletion = update
    }

    deinit {
        print("RtkMeetingEventListener deallocing")
    }
}

extension RtkMeetingEventListener: RtkRecordingEventListener {
    func onRecordingStateChanged(oldState: RecordingState, newState: RecordingState) {
        if oldState != newState {
            switch newState {
            case .idle: if oldState == .stopping {
                    onMeetingRecordingEnded()
                }
            case .recording: if oldState == .starting {
                    onMeetingRecordingStarted()
                }
            default:
                break
            }
        }
    }

    func onMeetingRecordingEnded() {
        recordMeetingStopCompletion?(true)
        recordMeetingStopCompletion = nil
    }

    func onMeetingRecordingStarted() {
        recordMeetingStartCompletion?(true)
        recordMeetingStartCompletion = nil
    }
}

extension RtkMeetingEventListener: RtkParticipantsEventListener {
    func onActiveParticipantsChanged(active _: [RtkRemoteParticipant]) {}

    func onActiveSpeakerChanged(participant _: RtkRemoteParticipant?) {}

    func onAllParticipantsUpdated(allParticipants _: [RtkParticipant]) {}

    func onAudioUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    func onNewBroadcastMessage(type _: String, payload _: [String: Any]) {}

    func onScreenShareUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    func onUpdate(participants _: RtkParticipants) {}

    func onVideoUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    func onParticipantPinned(participant: RtkRemoteParticipant) {
        participantPinnedStateCompletion?(participant)
    }

    func onParticipantUnpinned(participant: RtkRemoteParticipant) {
        participantUnPinnedStateCompletion?(participant)
    }

    func onParticipantJoin(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onParticipantJoin \(participant.audioEnabled) \(participant.name) totalCount \(rtkClient.participants.joined) participants")
        }
        participantJoinStateCompletion?(participant)
    }

    func onParticipantLeave(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onParticipantLeave \(rtkClient.participants.active.count)")
        }
        participantLeaveStateCompletion?(participant)
    }
}
