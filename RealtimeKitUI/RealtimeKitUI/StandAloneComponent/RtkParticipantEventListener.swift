//
//  RtkParticipantEventListener.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/02/23.
//

import RealtimeKit
import UIKit

class RtkParticipantUpdateEventListener {
    private var participantAudioStateCompletion: ((Bool) -> Void)?
    private var participantVideoStateCompletion: ((Bool) -> Void)?

    private var participantObserveAudioStateCompletion: ((Bool, RtkParticipantUpdateEventListener) -> Void)?
    private var participantObserveVideoStateCompletion: ((Bool, RtkParticipantUpdateEventListener) -> Void)?
    private var participantPinStateCompletion: ((Bool) -> Void)?
    private var participantUnPinStateCompletion: ((Bool) -> Void)?
    private var participantObservePinStateCompletion: ((Bool, RtkParticipantUpdateEventListener) -> Void)?
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn

    let participant: RtkMeetingParticipant

    init(participant: RtkMeetingParticipant) {
        self.participant = participant
        participant.addParticipantUpdateListener(participantUpdateListener: self)
    }

    func observeAudioState(update: @escaping (_ isEnabled: Bool, _ observer: RtkParticipantUpdateEventListener) -> Void) {
        participantObserveAudioStateCompletion = update
    }

    func observePinState(update: @escaping (_ isPinned: Bool, _ observer: RtkParticipantUpdateEventListener) -> Void) {
        participantObservePinStateCompletion = update
    }

    func observeVideoState(update: @escaping (_ isEnabled: Bool, _ observer: RtkParticipantUpdateEventListener) -> Void) {
        participantObserveVideoStateCompletion = update
    }

    func muteAudio(completion: @escaping (_ isEnabled: Bool) -> Void) {
        participantAudioStateCompletion = completion
        if let remoteParticipant = participant as? RtkRemoteParticipant {
            remoteParticipant.disableAudio()
        }
    }

    func muteVideo(completion: @escaping (_ isEnabled: Bool) -> Void) {
        participantVideoStateCompletion = completion
        if let remoteParticipant = participant as? RtkRemoteParticipant {
            remoteParticipant.disableVideo()
        }
    }

    func pin(completion: @escaping (Bool) -> Void) {
        participantPinStateCompletion = completion
        participant.pin()
    }

    func unPin(completion: @escaping (Bool) -> Void) {
        participantUnPinStateCompletion = completion
        participant.unpin()
    }

    func clean() {
        participant.removeParticipantUpdateListener(participantUpdateListener: self)
    }
}

extension RtkParticipantUpdateEventListener: RtkParticipantUpdateListener {
    func onAudioUpdate(participant _: RtkMeetingParticipant, isEnabled: Bool) {
        participantObserveAudioStateCompletion?(isEnabled, self)
        participantAudioStateCompletion?(isEnabled)
        participantAudioStateCompletion = nil
    }

    func onPinned(participant _: RtkMeetingParticipant) {
        participantPinStateCompletion?(true)
        participantPinStateCompletion = nil
        participantObservePinStateCompletion?(true, self)
    }

    func onUnpinned(participant _: RtkMeetingParticipant) {
        participantUnPinStateCompletion?(true)
        participantUnPinStateCompletion = nil
        participantObservePinStateCompletion?(false, self)
    }

    func onUpdate(participant _: RtkMeetingParticipant) {}

    func onScreenShareUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    func onVideoUpdate(participant _: RtkMeetingParticipant, isEnabled: Bool) {
        participantObserveVideoStateCompletion?(isEnabled, self)
        participantVideoStateCompletion?(isEnabled)
        participantVideoStateCompletion = nil
    }
}

public class RtkWaitListParticipantUpdateEventListener {
    public var participantJoinedCompletion: ((RtkMeetingParticipant) -> Void)?
    public var participantRemovedCompletion: ((RtkMeetingParticipant) -> Void)?
    public var participantRequestAcceptedCompletion: ((RtkMeetingParticipant) -> Void)?
    public var participantRequestRejectCompletion: ((RtkMeetingParticipant) -> Void)?

    let rtkClient: RealtimeKitClient

    public init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.rtkClient.addWaitlistEventListener(waitlistEventListener: self)
    }

    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn

    public func clean() {
        removeRegisterListener()
    }

    public func acceptWaitingRequest(participant: RtkRemoteParticipant) {
        rtkClient.participants.acceptWaitingRoomRequest(id: participant.id)
    }

    public func rejectWaitingRequest(participant: RtkRemoteParticipant) {
        rtkClient.participants.rejectWaitingRoomRequest(id: participant.id)
    }

    private func removeRegisterListener() {
        rtkClient.removeWaitlistEventListener(waitlistEventListener: self)
    }

    deinit {
        print("RtkParticipantEventListener deallocing")
    }
}

extension RtkWaitListParticipantUpdateEventListener: RtkWaitlistEventListener {
    public func onWaitListParticipantAccepted(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantAccepted \(participant.name)")
        }
        DispatchQueue.main.async {
            self.participantRequestAcceptedCompletion?(participant)
        }
    }

    public func onWaitListParticipantRejected(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantRejected \(participant.name) \(participant.id) self \(participant.id)")
        }
        DispatchQueue.main.async {
            self.participantRequestRejectCompletion?(participant)
        }
    }

    public func onWaitListParticipantClosed(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantClosed \(participant.name)")
        }
        DispatchQueue.main.async {
            self.participantRemovedCompletion?(participant)
        }
    }

    public func onWaitListParticipantJoined(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantJoined \(participant.name)")
        }
        DispatchQueue.main.async {
            self.participantJoinedCompletion?(participant)
        }
    }
}
