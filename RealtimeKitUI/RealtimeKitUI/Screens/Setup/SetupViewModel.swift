//
//  SetupViewModel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 29/11/22.
//

import RealtimeKit
import UIKit

protocol MeetingDelegate: AnyObject {
    func onMeetingInitFailed(message: String?)
    func onMeetingInitCompleted()
}

public protocol ChatDelegate {
    func refreshMessages()
}

protocol PollDelegate {
    func refreshPolls(pollMessages: [Poll])
}

protocol ParticipantsDelegate {
    func refreshList()
}

final class SetupViewModel {
    let rtkClient: RealtimeKitClient

    private var roomJoined: ((Bool) -> Void)?
    private weak var delegate: MeetingDelegate?

    var participantsDelegate: ParticipantsDelegate?
    var participants = [RtkMeetingParticipant]()
    var screenshares = [RtkMeetingParticipant]()

    let meetingInfo: RtkMeetingInfo
    let rtkSelfListener: RtkEventSelfListener

    init(rtkClient: RealtimeKitClient, delegate: MeetingDelegate?, meetingInfo: RtkMeetingInfo) {
        self.rtkClient = rtkClient
        self.delegate = delegate
        self.meetingInfo = meetingInfo
        rtkSelfListener = RtkEventSelfListener(rtkClient: rtkClient)
        initialise()
    }

    func initialise() {
        let info = meetingInfo
        rtkSelfListener.initMeetingV2(info: info) { [weak self] success, message in
            guard let self else { return }

            if success {
                delegate?.onMeetingInitCompleted()
            } else {
                delegate?.onMeetingInitFailed(message: message)
            }
        }
    }

    func removeListener() {
        rtkSelfListener.clean()
    }

    deinit {
        print("SetupView Model dealloc is calling")
    }
}
