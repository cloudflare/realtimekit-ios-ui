//
//  RtkVideoPeerViewModel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 06/01/23.
//

import RealtimeKit

public class VideoPeerViewModel {
    public var audioUpdate: (() -> Void)?
    public var videoUpdate: (() -> Void)?
    public var loadNewParticipant: ((RtkMeetingParticipant) -> Void)?

    public var nameInitialsUpdate: (() -> Void)?
    public var nameUpdate: (() -> Void)?

    let showSelfPreviewVideo: Bool
    var participant: RtkMeetingParticipant!
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    let rtkClient: RealtimeKitClient
    let showScreenShareVideoView: Bool
    private var participantUpdateListener: RtkParticipantUpdateEventListener?

    public init(meeting: RealtimeKitClient, participant: RtkMeetingParticipant, showSelfPreviewVideo: Bool, showScreenShareVideoView: Bool = false) {
        self.showSelfPreviewVideo = showSelfPreviewVideo
        self.showScreenShareVideoView = showScreenShareVideoView
        rtkClient = meeting
        self.participant = participant
        update()
    }

    public func set(participant: RtkMeetingParticipant) {
        self.participant = participant
        loadNewParticipant?(participant)
        update()
    }

    public func refreshInitialName() {
        nameInitialsUpdate?()
    }

    public func refreshNameTag() {
        nameUpdate?()
    }

    private func addUpdatesListener() {
        participantUpdateListener?.observeAudioState(update: { [weak self] _, _ in
            guard let self else { return }
            audioUpdate?()
        })
        participantUpdateListener?.observeVideoState(update: { [weak self] _, _ in
            guard let self else { return }
            videoUpdate?()
        })
    }

    private func update() {
        refreshNameTag()
        refreshInitialName()
        participantUpdateListener?.clean()
        participantUpdateListener = RtkParticipantUpdateEventListener(participant: participant)
        addUpdatesListener()
    }
}
