import RealtimeKit
import UIKit

protocol ChatParticipantSelectionDelegate: AnyObject {
    func didSelectChat(withParticipant participant: RtkRemoteParticipant?)
}

class ChatParticipantSelectionViewController: UIViewController, SetTopbar {
    var shouldShowTopBar: Bool = true
    var topBar: RtkNavigationBar = .init(title: "Chat with...")
    weak var delegate: ChatParticipantSelectionDelegate?
    private var participants = [RtkRemoteParticipant]()
    private var filteredParticipants = [RtkRemoteParticipant]()
    var selectedParticipant: RtkRemoteParticipant?

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search participants"
        searchBar.delegate = self
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = DesignLibrary.shared.color.background.shade1000
        return tableView
    }()

    func setParticipants(participants: [RtkRemoteParticipant]) {
        self.participants = participants
        filteredParticipants = participants
    }

    func newChatReceived(message _: ChatMessage) {
        tableView.reloadData()
    }

    func onRemove(userId: String) {
        Shared.data.privateChatReadLookup.removeValue(forKey: userId)
        tableView.reloadData()
    }

    func onParticipantJoin(userId: String) {
        Shared.data.privateChatReadLookup[userId] = false
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        filteredParticipants = participants
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.get(.top)?.constant = view.safeAreaInsets.top
    }

    private func setupViews() {
        addTopBar(dismissAnimation: true)
        topBar.backgroundColor = tableView.backgroundColor
        topBar.leftButton.backgroundColor = tableView.backgroundColor
        tableView.register(ParticipantInCallTableViewCell.self, forCellReuseIdentifier: "ParticipantInCallTableViewCell")
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension ChatParticipantSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            1
        } else {
            filteredParticipants.count
        }
    }

    private func setNotificationBadge(show: Bool, cell: ParticipantInCallTableViewCell) {
        if cell.notificationBadge == nil {
            let notificationBadge = RtkNotificationBadgeView()
            cell.addSubview(notificationBadge)
            let notificationBadgeHeight = rtkSharedTokenSpace.space4
            notificationBadge.set(.centerY(cell.moreButton),
                                  .before(cell.moreButton, notificationBadgeHeight),
                                  .height(notificationBadgeHeight),
                                  .width(notificationBadgeHeight * 2.5, .lessThanOrEqual))

            notificationBadge.layer.cornerRadius = notificationBadgeHeight / 2.0
            notificationBadge.layer.masksToBounds = true
            notificationBadge.backgroundColor = rtkSharedTokenColor.brand.shade500
            cell.notificationBadge = notificationBadge
        }
        cell.notificationBadge!.isHidden = !show
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantInCallTableViewCell", for: indexPath) as! ParticipantInCallTableViewCell
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            cell.audioButton.isHidden = true
            cell.videoButton.isHidden = true

            cell.backgroundColor = selectedParticipant == nil ? DesignLibrary.shared.color.background.shade900 : tableView.backgroundColor
            cell.moreButton.setImage(ImageProvider.image(named: "icon_right_arrow"), for: .normal)
            cell.moreButton.backgroundColor = cell.backgroundColor
            cell.setPinView(isHidden: true)
            cell.contentView.backgroundColor = cell.backgroundColor
            cell.nameLabel.text = "Everyone in meeting"
            cell.profileAvatarView.backgroundColor = .clear
            cell.profileAvatarView.profileImageView.setImage(image: RtkImage(image: ImageProvider.image(named: "icon_participants")))
            setNotificationBadge(show: Shared.data.privateChatReadLookup["everyone"] ?? false, cell: cell)
        } else {
            cell.backgroundColor = filteredParticipants[indexPath.row].userId == selectedParticipant?.userId ? DesignLibrary.shared.color.background.shade900 : tableView.backgroundColor

            let participant = filteredParticipants[indexPath.row]
            cell.profileAvatarView.set(participant: participant)
            cell.moreButton.backgroundColor = cell.backgroundColor
            cell.audioButton.isHidden = true
            cell.videoButton.isHidden = true
            cell.contentView.backgroundColor = cell.backgroundColor
            cell.moreButton.setImage(ImageProvider.image(named: "icon_right_arrow"), for: .normal)
            cell.nameLabel.text = participant.name
            cell.cellSeparatorBottom.isHidden = true
            cell.cellSeparatorTop.isHidden = true
            cell.profileAvatarView.backgroundColor = rtkSharedTokenColor.brand.shade500
            cell.setPinView(isHidden: true)
            if let show = Shared.data.privateChatReadLookup[participant.userId] {
                setNotificationBadge(show: show, cell: cell)
            }
        }

        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            delegate?.didSelectChat(withParticipant: nil)
        } else {
            delegate?.didSelectChat(withParticipant: filteredParticipants[indexPath.row])
        }
    }
}

extension ChatParticipantSelectionViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchText.isEmpty {
            filteredParticipants = participants
        } else {
            filteredParticipants = participants.filter { participant in
                participant.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
}
