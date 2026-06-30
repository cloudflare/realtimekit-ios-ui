//
//  WebinarViewModel.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 07/03/24.
//

import Foundation
import RealtimeKit

protocol RtkStageDelegate: AnyObject {
    func onPresentRequestAdded(participant: RtkRemoteParticipant)
    func onPresentRequestWithdrawn(participant: RtkRemoteParticipant)
}

class WebinarViewModel {
    var stageDelegate: RtkStageDelegate?
    private let rtkClient: RealtimeKitClient

    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        rtkClient.addStageEventListener(stageEventListener: self)
    }
}

extension WebinarViewModel: RtkStageEventListener {
    func onNewStageAccessRequest(participant _: RtkRemoteParticipant) {}

    func onPeerStageStatusUpdated(participant _: RtkRemoteParticipant, oldStatus _: RealtimeKit.StageStatus, newStatus _: RealtimeKit.StageStatus) {}

    func onRemovedFromStage() {}

    func onStageAccessRequestAccepted() {}

    func onStageAccessRequestRejected() {}

    func onStageAccessRequestsUpdated(accessRequests _: [RtkRemoteParticipant]) {}

    func onStageStatusUpdated(oldStatus _: RealtimeKit.StageStatus, newStatus _: RealtimeKit.StageStatus) {}

    func onPresentRequestWithdrawn(participant: RtkRemoteParticipant) {
        stageDelegate?.onPresentRequestWithdrawn(participant: participant)
    }

    func onPresentRequestAdded(participant: RtkRemoteParticipant) {
        stageDelegate?.onPresentRequestAdded(participant: participant)
    }
}
