//
//  SearchViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/02/23.
//

import RealtimeKit
import UIKit

class SearchViewControllerModel {
    init(sections: [BaseConfiguratorSection<CollectionTableSearchConfigurator>]) {
        dataSourceTableView = DataSourceSearchStandard(sections: sections)
    }

    var dataSourceTableView: DataSourceSearchStandard<BaseConfiguratorSection<CollectionTableSearchConfigurator>>!

    func search(text: String, completion: () -> Void) {
        if text.isEmpty == true {
            dataSourceTableView.set(sections: dataSourceTableView.originalSections)
        } else {
            var sections = [BaseConfiguratorSection<CollectionTableSearchConfigurator>]()
            for section in dataSourceTableView.originalSections {
                let filterSection = BaseConfiguratorSection<CollectionTableSearchConfigurator>()
                for item in section.items {
                    if item.search(text: text) == true {
                        filterSection.insert(item)
                    }
                }
                if filterSection.items.count > 0 {
                    sections.append(filterSection)
                }
            }
            dataSourceTableView.set(sections: sections)
        }
        completion()
    }
}

public class SearchViewController: UIViewController, KeyboardObservable {
    let tableView = UITableView()
    let viewModel: SearchViewControllerModel
    var keyboardObserver: KeyboardObserver?

    let searchBar = {
        let searchBar = UISearchBar()
        searchBar.changeText(color: rtkSharedTokenColor.textColor.onBackground.shade700)
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        return searchBar
    }()

    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    let waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    let meeting: RealtimeKitClient
    let completion: () -> Void
    init(meeting: RealtimeKitClient, originalItems: [BaseConfiguratorSection<CollectionTableSearchConfigurator>], completion: @escaping (() -> Void)) {
        viewModel = SearchViewControllerModel(sections: originalItems)
        self.meeting = meeting
        self.completion = completion
        waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: meeting)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        setupKeyboard()
        searchBar.becomeFirstResponder()
        addObserver()
    }

    private func addObserver() {
        waitlistEventListener.participantJoinedCompletion = { [weak self] _ in
            guard let self else { return }
            reloadScreen()
        }
        waitlistEventListener.participantRemovedCompletion = { [weak self] _ in
            guard let self else { return }
            reloadScreen()
        }
        waitlistEventListener.participantRequestAcceptedCompletion = { [weak self] _ in
            guard let self else { return }
            reloadScreen()
        }
        waitlistEventListener.participantRequestRejectCompletion = { [weak self] _ in
            guard let self else { return }
            reloadScreen()
        }
    }

    func setUpView() {
        searchBar.delegate = self
        view.backgroundColor = rtkSharedTokenColor.background.shade1000
        view.addSubview(searchBar)
        searchBar.set(.top(view),
                      .sameLeadingTrailing(view))
        setUpTableView()
    }

    func setUpTableView() {
        view.addSubview(tableView)
        tableView.backgroundColor = rtkSharedTokenColor.background.shade1000
        tableView.set(.sameLeadingTrailing(view),
                      .below(searchBar),
                      .bottom(view))
        registerCells(tableView: tableView)
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    func registerCells(tableView: UITableView) {
        tableView.register(ParticipantWaitingTableViewCell.self)
        tableView.register(OnStageWaitingRequestTableViewCell.self)
        tableView.register(ParticipantInCallTableViewCell.self)
        tableView.register(WebinarViewersTableViewCell.self)
    }

    private func setupKeyboard() {
        startKeyboardObserving { keyboardFrame in
            self.tableView.get(.bottom)?.constant = -keyboardFrame.height
            // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {
            self.tableView.get(.bottom)?.constant = 0
            // self.view.frame.origin.y = 0 // Move view to original position
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    public func searchBar(_: UISearchBar, textDidChange searchText: String) {
        viewModel.search(text: searchText) {
            self.tableView.reloadData()
        }
    }

    public func searchBarCancelButtonClicked(_: UISearchBar) {
        view.removeFromSuperview()
        waitlistEventListener.clean()
        completion()
    }
}

extension SearchViewController: UITableViewDataSource {
    public func numberOfSections(in _: UITableView) -> Int {
        viewModel.dataSourceTableView.numberOfSections()
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.dataSourceTableView.numberOfRows(section: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = viewModel.dataSourceTableView.configureCell(tableView: tableView, indexPath: indexPath)
        cell.backgroundColor = tableView.backgroundColor
        if let cell = cell as? ParticipantInCallTableViewCell {
            cell.buttonMoreClick = { [weak self] _ in
                guard let self else { return }
                searchBar.resignFirstResponder()

                if createMoreMenu(participantListener: cell.model.participantUpdateEventListener, indexPath: indexPath) {
                    if isDebugModeOn {
                        print("Debug RtkUIKit | Critical UIBug Please check why we are showing this button")
                    }
                }
            }
            cell.setPinView(isHidden: !cell.model.participantUpdateEventListener.participant.isPinned)
        } else if let cell = cell as? ParticipantWaitingTableViewCell {
            cell.buttonCrossClick = { [weak self] button in
                guard let self else { return }
                button.showActivityIndicator()
                waitlistEventListener.rejectWaitingRequest(participant: cell.model.participant)
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self else { return }
                button.showActivityIndicator()
                waitlistEventListener.acceptWaitingRequest(participant: cell.model.participant)
            }
            cell.setPinView(isHidden: true)
        } else if let cell = cell as? WebinarViewersTableViewCell {
            cell.buttonMoreClick = { [weak self] _ in
                guard let self else { return }
                searchBar.resignFirstResponder()
                if createMoreMenuForViewers(participantListener: cell.model.participantUpdateEventListener, indexPath: indexPath) {
                    if isDebugModeOn {
                        print("Debug RtkUIKit | Critical UIBug Please check why we are showing this button")
                    }
                }
            }
            cell.setPinView(isHidden: !cell.model.participantUpdateEventListener.participant.isPinned)
        } else if let cell = cell as? OnStageWaitingRequestTableViewCell {
            cell.buttonCrossClick = { [weak self] button in
                guard let self else { return }
                button.showActivityIndicator()
                meeting.stage.denyAccess(userIds: [cell.model.participant.userId])
                button.hideActivityIndicator()
                reloadScreen()
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self else { return }
                button.showActivityIndicator()
                meeting.stage.grantAccess(userIds: [cell.model.participant.userId])
                button.hideActivityIndicator()
                reloadScreen()
            }
            cell.setPinView(isHidden: !cell.model.participant.isPinned)
        }
        return cell
    }

    func reloadScreen() {
        tableView.reloadData()
    }

    private func createMoreMenuForViewers(participantListener: RtkParticipantUpdateEventListener, indexPath _: IndexPath) -> Bool {
        var menus = [MenuType]()
        let participant = participantListener.participant
        let hostPermission = meeting.localUser.permissions.host

        // TODO: Add below code inside condition of whether I had already allowed or not.
        menus.append(.allowToJoinStage)

        if hostPermission.canKickParticipant, participant != meeting.localUser {
            menus.append(.kick)
        }

        if menus.count < 1 {
            return false
        }
        menus.append(contentsOf: [.cancel])

        let moreMenu = RtkMoreMenu(title: participant.name, features: menus, onSelect: { [weak self] menuType in
            guard let self else { return }
            switch menuType {
            case .allowToJoinStage:
                meeting.stage.grantAccess(userIds: [participant.userId])

            case .denyToJoinStage:
                print("Don't know ")

            case .kick:
                if let remoteParticipant = participant as? RtkRemoteParticipant {
                    remoteParticipant.kick()
                }

            case .cancel:
                print("Not Supported for now")

            default:
                print("No need to handle others for now")
            }
        })
        moreMenu.show(on: view)
        return true
    }

    private func createMoreMenu(participantListener: RtkParticipantUpdateEventListener, indexPath _: IndexPath) -> Bool {
        var menus = [MenuType]()
        let participant = participantListener.participant
        let hostPermission = meeting.localUser.permissions.host

        menus.append(.removeFromStage)
        if hostPermission.canPinParticipant {
            if participant.isPinned == false {
                menus.append(.pin)
            } else {
                menus.append(.unPin)
            }
        }

        if hostPermission.canMuteAudio, participant.audioEnabled == true {
            menus.append(.muteAudio)
        }

        if hostPermission.canMuteVideo, participant.videoEnabled == true {
            menus.append(.muteVideo)
        }

        if hostPermission.canKickParticipant, participant != meeting.localUser {
            menus.append(.kick)
        }

        if menus.count < 1 {
            return false
        }
        menus.append(contentsOf: [.cancel])

        let moreMenu = RtkMoreMenu(title: participant.name, features: menus, onSelect: { [weak self] menuType in
            guard let self else { return }
            switch menuType {
            case .pin:
                participant.pin()
            case .unPin:
                participant.unpin()
            case .muteAudio:
                if let remoteParticipant = participant as? RtkRemoteParticipant {
                    remoteParticipant.disableAudio()
                }
            case .muteVideo:
                if let remoteParticipant = participant as? RtkRemoteParticipant {
                    remoteParticipant.disableVideo()
                }
            case .removeFromStage:
                meeting.stage.kick(userIds: [participant.id])
            case .kick:
                if let remoteParticipant = participant as? RtkRemoteParticipant {
                    remoteParticipant.kick()
                }
            case .cancel:
                print("Not Supported for now")
            default:
                print("No need to handle others for now")
            }
        })
        moreMenu.show(on: view)
        return true
    }
}
