//
//  WebinarParticipantViewControllerModel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 15/02/23.
//

import Foundation
import RealtimeKit

public class WebinarParticipantViewControllerModel {
    let rtkClient: RealtimeKitClient
    let waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    let rtkSelfListener: RtkEventSelfListener
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private let searchControllerMinimumParticipant = 5

    required init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: rtkClient)
        rtkSelfListener = RtkEventSelfListener(rtkClient: rtkClient)

        rtkClient.addParticipantsEventListener(participantsEventListener: self)
        rtkClient.addStageEventListener(stageEventListener: self)
        addObserver()
    }

    private func addObserver() {
        waitlistEventListener.participantJoinedCompletion = { [weak self] _ in
            guard let self, let completion else { return }
            refresh(completion: completion)
        }
        waitlistEventListener.participantRemovedCompletion = { [weak self] _ in
            guard let self, let completion else { return }
            refresh(completion: completion)
        }
        waitlistEventListener.participantRequestAcceptedCompletion = { [weak self] _ in
            guard let self, let completion else { return }
            refresh(completion: completion)
        }
        waitlistEventListener.participantRequestRejectCompletion = { [weak self] _ in
            guard let self, let completion else { return }
            refresh(completion: completion)
        }
    }

    func acceptAll() {
        let userId = rtkClient.stage.accessRequests.map(\.userId)
        rtkClient.stage.grantAccess(userIds: userId)
    }

    func acceptAllWaitingRoomRequest() {
        rtkClient.participants.acceptAllWaitingRoomRequests()
    }

    func rejectAll() {
        let userId = rtkClient.stage.accessRequests.map(\.userId)
        rtkClient.stage.denyAccess(userIds: userId)
    }

    private func revokeInvitationToJoinStage(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    private func participantInviteToJoinStage(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()

    private var completion: ((Bool) -> Void)?

    public func load(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        refresh(completion: completion)
    }

    private func refresh(completion: @escaping (Bool) -> Void) {
        dataSourceTableView.sections.removeAll()
        let minimumParticipantCountToShowSearchBar = searchControllerMinimumParticipant

        let sectionZero = getWaitlistSection()
        let sectionOne = getJoinStageRequestSection()
        let sectionTwo = getOnStageSection(minimumParticipantCountToShowSearchBar: minimumParticipantCountToShowSearchBar)
        let sectionThree = getInCallViewers(minimumParticipantCountToShowSearchBar: minimumParticipantCountToShowSearchBar)

        dataSourceTableView.sections.append(sectionZero)
        dataSourceTableView.sections.append(sectionOne)
        dataSourceTableView.sections.append(sectionTwo)
        dataSourceTableView.sections.append(sectionThree)
        completion(true)
    }

    func clean() {
        rtkClient.removeParticipantsEventListener(participantsEventListener: self)
        rtkClient.removeStageEventListener(stageEventListener: self)
        waitlistEventListener.clean()
    }

    deinit {}
}

extension WebinarParticipantViewControllerModel {
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = rtkClient.participants.waitlisted
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "Waiting\(participantCount)")))

            for (index, participant) in waitListedParticipants.enumerated() {
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                sectionOne.insert(TableItemConfigurator<ParticipantWaitingTableViewCell, ParticipantWaitingTableViewCellModel>(model: ParticipantWaitingTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }

            if waitListedParticipants.count > 1 {
                sectionOne.insert(TableItemConfigurator<AcceptButtonWaitingTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }

        return sectionOne
    }

    private func getJoinStageRequestSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = rtkClient.stage.accessRequests
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "Join stage requests\(participantCount)")))

            for (index, participant) in waitListedParticipants.enumerated() {
                let image: RtkImage? = nil
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }

                sectionOne.insert(TableItemConfigurator<OnStageWaitingRequestTableViewCell, OnStageParticipantWaitingRequestTableViewCellModel>(model: OnStageParticipantWaitingRequestTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }

            if waitListedParticipants.count > 1 {
                sectionOne.insert(TableItemConfigurator<AcceptButtonJoinStageRequestTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Accept All")))
                sectionOne.insert(TableItemConfigurator<RejectButtonJoinStageRequestTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Reject All")))
            }
        }
        return sectionOne
    }

    private func getOnStageSection(minimumParticipantCountToShowSearchBar: Int) -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let arrJoinedParticipants = rtkClient.participants.joined
        let selfIsOnStage = rtkClient.localUser.stageStatus == StageStatus.onStage

        var onStageRemoteParticipants = [RtkRemoteParticipant]()

        for participant in arrJoinedParticipants {
            if participant.stageStatus == StageStatus.onStage {
                onStageRemoteParticipants.append(participant)
            }
        }
        let sectionTwo = BaseConfiguratorSection<CollectionTableConfigurator>()

        var onStageParticipants = [RtkMeetingParticipant]()
        if selfIsOnStage {
            onStageParticipants.append(rtkClient.localUser)
        }

        onStageRemoteParticipants.forEach { onStageParticipants.append($0) }

        if onStageParticipants.count > 0 {
            var participantCount = ""
            if onStageParticipants.count > 1 {
                participantCount = " (\(onStageParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "On stage\(participantCount)")))

            if onStageParticipants.count > minimumParticipantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell, SearchTableViewCellModel>(model: SearchTableViewCellModel(placeHolder: "Search Participant")))
            }

            for (index, participant) in onStageParticipants.enumerated() {
                var showBottomSeparator = true
                if index == onStageParticipants.count - 1 {
                    showBottomSeparator = false
                }
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = rtkClient.localUser.permissions.host

                    if hostPermission.canPinParticipant, participant.isPinned == false {
                        canShow = true
                    }

                    if hostPermission.canMuteAudio, participant.audioEnabled == true {
                        canShow = true
                    }

                    if hostPermission.canMuteVideo, participant.videoEnabled == true {
                        canShow = true
                    }

                    if hostPermission.canKickParticipant {
                        canShow = true
                    }

                    return canShow
                }

                var name = participant.name
                if participant.userId == rtkClient.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }

                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel>(model: ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        return sectionTwo
    }

    private func getInCallViewers(minimumParticipantCountToShowSearchBar: Int) -> BaseConfiguratorSection<CollectionTableConfigurator> {
        var viewerRemoteParticipants = [RtkRemoteParticipant]()
        viewerRemoteParticipants.append(contentsOf: rtkClient.stage.viewers)
        let shouldShowSelfInViewers = rtkClient.localUser.stageStatus != StageStatus.onStage
        let sectionTwo = BaseConfiguratorSection<CollectionTableConfigurator>()

        var allViewerParticipants = [RtkMeetingParticipant]()
        if shouldShowSelfInViewers {
            allViewerParticipants.append(rtkClient.localUser)
        }

        viewerRemoteParticipants.forEach { allViewerParticipants.append($0) }

        if allViewerParticipants.count > 0 {
            var participantCount = ""
            if allViewerParticipants.count > 1 {
                participantCount = " (\(allViewerParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "Viewers\(participantCount)")))

            if allViewerParticipants.count > minimumParticipantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell, SearchTableViewCellModel>(model: SearchTableViewCellModel(placeHolder: "Search Viewers")))
            }

            for (index, participant) in allViewerParticipants.enumerated() {
                var showBottomSeparator = true
                if index == allViewerParticipants.count - 1 {
                    showBottomSeparator = false
                }

                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = rtkClient.localUser.permissions.host

                    if rtkClient.localUser.canDoParticipantHostControls() || hostPermission.canAcceptRequests == true {
                        canShow = true
                    }
                    return canShow
                }

                var name = participant.name
                if participant.userId == rtkClient.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }
                sectionTwo.insert(TableItemSearchableConfigurator<WebinarViewersTableViewCell, WebinarViewersTableViewCellModel>(model: WebinarViewersTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        return sectionTwo
    }
}

extension WebinarParticipantViewControllerModel: RtkParticipantsEventListener {
    public func onActiveParticipantsChanged(active _: [RtkRemoteParticipant]) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onParticipantJoin(participant _: RtkRemoteParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onParticipantLeave(participant _: RtkRemoteParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onActiveSpeakerChanged(participant _: RtkRemoteParticipant?) {}

    public func onAllParticipantsUpdated(allParticipants _: [RtkParticipant]) {}

    public func onAudioUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onNewBroadcastMessage(type _: String, payload _: [String: Any]) {}

    public func onParticipantPinned(participant _: RtkRemoteParticipant) {}

    public func onParticipantUnpinned(participant _: RtkRemoteParticipant) {}

    public func onScreenShareUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onUpdate(participants _: RtkParticipants) {}

    public func onVideoUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}
}

extension WebinarParticipantViewControllerModel: RtkStageEventListener {
    public func onNewStageAccessRequest(participant _: RtkRemoteParticipant) {}

    public func onPeerStageStatusUpdated(participant _: RtkRemoteParticipant, oldStatus _: RealtimeKit.StageStatus, newStatus _: RealtimeKit.StageStatus) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onStageAccessRequestRejected() {}

    public func onStageAccessRequestsUpdated(accessRequests _: [RtkRemoteParticipant]) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onStageStatusUpdated(oldStatus _: RealtimeKit.StageStatus, newStatus _: RealtimeKit.StageStatus) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onStageAccessRequestAccepted() {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onRemovedFromStage() {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onStageRequestsUpdated(accessRequests _: [RtkRemoteParticipant]) {
        if let completion {
            refresh(completion: completion)
        }
    }
}
