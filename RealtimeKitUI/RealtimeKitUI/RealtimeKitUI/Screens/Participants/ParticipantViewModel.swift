//
//  ParticipantViewModel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 15/02/23.
//

import Foundation
import RealtimeKit

struct ParticipantWaitingTableViewCellModel: BaseModel {
    func clean() {}

    var title: String
    var image: RtkImage?
    var showBottomSeparator = false
    var showTopSeparator = false
    var participant: RtkRemoteParticipant
}

struct OnStageParticipantWaitingRequestTableViewCellModel: BaseModel {
    var title: String
    var image: RtkImage?
    var showBottomSeparator = false
    var showTopSeparator = false
    var participant: RtkRemoteParticipant
    func clean() {}
}

struct ParticipantInCallTableViewCellModel: Searchable, BaseModel {
    func search(text: String) -> Bool {
        let parentText = title.lowercased()
        if parentText.hasPrefix(text) {
            return true
        }
        return false
    }

    var image: RtkImage?
    var title: String
    var showBottomSeparator = false
    var showTopSeparator = false
    var participantUpdateEventListener: RtkParticipantUpdateEventListener
    var showMoreButton: Bool
    func clean() {
        participantUpdateEventListener.clean()
    }
}

struct WebinarViewersTableViewCellModel: Searchable, BaseModel {
    func search(text: String) -> Bool {
        let parentText = title.lowercased()
        if parentText.hasPrefix(text) {
            return true
        }
        return false
    }

    var image: RtkImage?
    var title: String
    var showBottomSeparator = false
    var showTopSeparator = false
    var participantUpdateEventListener: RtkParticipantUpdateEventListener
    var showMoreButton: Bool
    func clean() {
        participantUpdateEventListener.clean()
    }
}

protocol ParticipantViewControllerModelProtocol {
    var meeting: RealtimeKitClient { get }
    var waitlistEventListener: RtkWaitListParticipantUpdateEventListener { get }
    var meetingEventListener: RtkMeetingEventListener { get }
    var rtkSelfListener: RtkEventSelfListener { get }
    var dataSourceTableView: DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>> { get }
    init(meeting: RealtimeKitClient)
    func load(completion: @escaping (Bool) -> Void)
    func acceptAll()
    func rejectAll()
}

extension ParticipantViewControllerModelProtocol {
    func moveLocalUserAtTop(section: BaseConfiguratorSection<CollectionTableConfigurator>) {
        if let indexYouParticipant = section.items.firstIndex(where: { configurator in
            if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel> {
                if configurator.model.participantUpdateEventListener.participant.userId == meeting.localUser.userId {
                    return true
                }
            }
            return false
        }) {
            if let indexFirstParticipantCell = section.items.firstIndex(where: { configurator in
                if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel> {
                    return true
                }
                return false
            }) {
                section.items.swapAt(indexYouParticipant, indexFirstParticipantCell)
            }
        }
    }
}

public class ParticipantViewControllerModel: ParticipantViewControllerModelProtocol {
    var rtkSelfListener: RtkEventSelfListener
    public var meeting: RealtimeKitClient
    public var waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    var meetingEventListener: RtkMeetingEventListener
    private let showAcceptAllButton = true
    private let searchControllerMinimumParticipant = 5

    required init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        meetingEventListener = RtkMeetingEventListener(rtkClient: meeting)
        waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: meeting)
        meetingEventListener.observeParticipantLeave { [weak self] participant in
            guard let self else { return }
            participantLeave(participant: participant)
        }

        meetingEventListener.observeParticipantJoin { [weak self] participant in
            guard let self else { return }
            participantJoin(participant: participant)
        }

        meetingEventListener.observeParticipantPinned { [weak self] _ in
            guard let self else { return }
            if let completion {
                refresh(completion: completion)
            }
        }

        meetingEventListener.observeParticipantUnPinned { [weak self] _ in
            guard let self else { return }
            if let completion {
                refresh(completion: completion)
            }
        }
    }

    func acceptAll() {
        meeting.participants.acceptAllWaitingRoomRequests()
    }

    func rejectAll() {}

    private func participantLeave(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    private func participantJoin(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()

    private var completion: ((Bool) -> Void)?

    public func load(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        refresh(completion: completion)
        addObserver()
    }

    private func refresh(completion: @escaping (Bool) -> Void) {
        dataSourceTableView.sections.removeAll()
        let minimumParticipantCountToShowSearchBar = searchControllerMinimumParticipant
        let sectionOne = getWaitlistSection()
        let sectionTwo = getInCallSection(minimumParticipantCountToShowSearchBar: minimumParticipantCountToShowSearchBar)
        dataSourceTableView.sections.append(sectionOne)
        dataSourceTableView.sections.append(sectionTwo)
        completion(true)
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

    deinit {
        meetingEventListener.clean()
        waitlistEventListener.clean()
    }
}

extension ParticipantViewControllerModel {
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = meeting.participants.waitlisted
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

            if waitListedParticipants.count > 1, showAcceptAllButton {
                sectionOne.insert(TableItemConfigurator<AcceptButtonTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }
        return sectionOne
    }

    private func getInCallSection(minimumParticipantCountToShowSearchBar: Int) -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let isSelfJoined = meeting.localUser.stageStatus == StageStatus.onStage
        let sectionTwo = BaseConfiguratorSection<CollectionTableConfigurator>()

        let joinedParticipants: [RtkMeetingParticipant] = isSelfJoined
            ? [meeting.localUser] + meeting.participants.joined
            : meeting.participants.joined

        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "In Call\(participantCount)")))

            if joinedParticipants.count > minimumParticipantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell, SearchTableViewCellModel>(model: SearchTableViewCellModel(placeHolder: "Search Participant")))
            }

            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
                    showBottomSeparator = false
                }

                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = meeting.localUser.permissions.host

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
                if participant.userId == meeting.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }
                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel>(model: ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        moveLocalUserAtTop(section: sectionTwo)

        return sectionTwo
    }
}

public class LiveParticipantViewControllerModel: ParticipantViewControllerModelProtocol, RtkLivestreamEventListener {
    var rtkSelfListener: RtkEventSelfListener

    public func onLivestreamStateChanged(oldState: LivestreamState, newState: LivestreamState) {
        if oldState != newState {
            switch newState {
            case .starting:
                onLivestreamStarting()
            case .stopping:
                onLivestreamEnding()
            case .streaming:
                onLivestreamStarted()
            case .idle:
                if oldState == LivestreamState.stopping {
                    onLivestreamEnded()
                }
            }
        }
    }

    public func onLivestreamError(message _: String) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onLivestreamUpdate(data _: RtkLivestreamData) {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onLivestreamEnded() {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onLivestreamEnding() {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onLivestreamStarted() {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onLivestreamStarting() {
        if let completion {
            refresh(completion: completion)
        }
    }

    public func onViewerCountUpdated(count _: Int32) {
        if let completion {
            refresh(completion: completion)
        }
    }

    let meeting: RealtimeKitClient
    let waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    let meetingEventListener: RtkMeetingEventListener
    private let showAcceptAllButton = true // TODO: when enable then please test the functionality, for now call backs are not working

    required init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        meetingEventListener = RtkMeetingEventListener(rtkClient: meeting)
        waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: meeting)
        meetingEventListener.observeParticipantLeave { [weak self] participant in
            guard let self else { return }
            participantLeave(participant: participant)
        }

        meetingEventListener.observeParticipantJoin { [weak self] participant in
            guard let self else { return }
            participantJoin(participant: participant)
        }
        meeting.addLivestreamEventListener(livestreamEventListener: self)
    }

    func acceptAll() {
        let userId = meeting.stage.accessRequests.map(\.userId)

        meeting.stage.grantAccess(userIds: userId)
    }

    func rejectAll() {
        let userId = meeting.stage.accessRequests.map(\.userId)
        meeting.stage.denyAccess(userIds: userId)
    }

    private func participantLeave(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    private func participantJoin(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()

    private var completion: ((Bool) -> Void)?

    public func load(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        refresh(completion: completion)
        addObserver()
    }

    private func refresh(completion: @escaping (Bool) -> Void) {
        dataSourceTableView.sections.removeAll()
        let minimumParticipantCountToShowSearchBar = 5
        let sectionOne = getWaitlistSection()
        let sectionTwo = getInCallSection(minimumParticipantCountToShowSearchBar: minimumParticipantCountToShowSearchBar)
        dataSourceTableView.sections.append(sectionOne)
        dataSourceTableView.sections.append(sectionTwo)
        completion(true)
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

    deinit {
        meetingEventListener.clean()
        waitlistEventListener.clean()
    }
}

extension LiveParticipantViewControllerModel {
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = meeting.stage.accessRequests
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "Waiting\(participantCount)")))

            for (index, participant) in waitListedParticipants.enumerated() {
                let image: RtkImage? = nil
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }

                sectionOne.insert(TableItemConfigurator<OnStageWaitingRequestTableViewCell, OnStageParticipantWaitingRequestTableViewCellModel>(model: OnStageParticipantWaitingRequestTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }

            if waitListedParticipants.count > 1, showAcceptAllButton {
                sectionOne.insert(TableItemConfigurator<AcceptButtonTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Accept All")))
                sectionOne.insert(TableItemConfigurator<RejectButtonTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Reject All")))
            }
        }
        return sectionOne
    }

    private func getInCallSection(minimumParticipantCountToShowSearchBar: Int) -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionTwo = BaseConfiguratorSection<CollectionTableConfigurator>()

        let remoteParticipants = meeting.participants.joined
        let isSelfJoined = meeting.localUser.stageStatus == .onStage
        let joinedParticipants: [RtkMeetingParticipant] = isSelfJoined
            ? [meeting.localUser] + remoteParticipants
            : remoteParticipants

        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "In Call\(participantCount)")))

            if joinedParticipants.count > minimumParticipantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell, SearchTableViewCellModel>(model: SearchTableViewCellModel(placeHolder: "Search Participant")))
            }

            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
                    showBottomSeparator = false
                }

                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = meeting.localUser.permissions.host

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
                if participant.userId == meeting.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }

                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel>(model: ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        moveLocalUserAtTop(section: sectionTwo)
        return sectionTwo
    }
}

public class ParticipantWebinarViewControllerModel {
    let rtkClient: RealtimeKitClient
    let waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    let meetingEventListener: RtkMeetingEventListener
    private let showAcceptAllButton = false // TODO: when enable then please test the functionality, for now call backs are not working

    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        meetingEventListener = RtkMeetingEventListener(rtkClient: rtkClient)
        waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: rtkClient)
        meetingEventListener.observeParticipantLeave { [weak self] participant in
            guard let self else { return }
            participantLeave(participant: participant)
        }

        meetingEventListener.observeParticipantJoin { [weak self] participant in
            guard let self else { return }
            participantJoin(participant: participant)
        }
    }

    private func participantLeave(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    private func participantJoin(participant _: RtkMeetingParticipant) {
        if let completion {
            refresh(completion: completion)
        }
    }

    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()

    private var completion: ((Bool) -> Void)?

    public func load(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        refresh(completion: completion)
        addObserver()
    }

    private func refresh(completion: @escaping (Bool) -> Void) {
        dataSourceTableView.sections.removeAll()
        let minimumParticipantCountToShowSearchBar = 5
        let sectionOne = getWaitlistSection()
        let sectionTwo = getInCallSection(minimumParticipantCountToShowSearchBar: minimumParticipantCountToShowSearchBar)
        dataSourceTableView.sections.append(sectionOne)
        dataSourceTableView.sections.append(sectionTwo)
        completion(true)
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

    deinit {
        meetingEventListener.clean()
        waitlistEventListener.clean()
    }
}

extension ParticipantWebinarViewControllerModel {
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
            if waitListedParticipants.count > 1, showAcceptAllButton {
                sectionOne.insert(TableItemConfigurator<AcceptButtonTableViewCell, ButtonTableViewCellModel>(model: ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }
        return sectionOne
    }

    private func getInCallSection(minimumParticipantCountToShowSearchBar: Int) -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let joinedParticipants = rtkClient.participants.joined
        let sectionTwo = BaseConfiguratorSection<CollectionTableConfigurator>()

        if joinedParticipants.count > 0 {
            var participantCount = ""
            if joinedParticipants.count > 1 {
                participantCount = " (\(joinedParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell, TitleTableViewCellModel>(model: TitleTableViewCellModel(title: "InCall\(participantCount)")))

            if joinedParticipants.count > minimumParticipantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell, SearchTableViewCellModel>(model: SearchTableViewCellModel(placeHolder: "Search Participant")))
            }

            for (index, participant) in joinedParticipants.enumerated() {
                var showBottomSeparator = true
                if index == joinedParticipants.count - 1 {
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

                sectionTwo.insert(TableItemConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel>(model: ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        moveLocalUserAtTop(section: sectionTwo)

        return sectionTwo
    }

    private func moveLocalUserAtTop(section: BaseConfiguratorSection<CollectionTableConfigurator>) {
        if let indexYouParticipant = section.items.firstIndex(where: { configurator in
            if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel> {
                if configurator.model.participantUpdateEventListener.participant.userId == rtkClient.localUser.userId {
                    return true
                }
            }
            return false
        }) {
            if let indexFirstParticipantCell = section.items.firstIndex(where: { configurator in
                if let configurator = configurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell, ParticipantInCallTableViewCellModel> {
                    return true
                }
                return false
            }) {
                section.items.swapAt(indexYouParticipant, indexFirstParticipantCell)
            }
        }
    }
}
