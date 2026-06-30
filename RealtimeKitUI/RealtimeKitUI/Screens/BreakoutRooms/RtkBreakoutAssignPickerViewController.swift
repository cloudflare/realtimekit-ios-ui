//
//  RtkBreakoutAssignPickerViewController.swift
//  RealtimeKitUI
//
//  Participant picker for assigning people to a breakout room.
//  Shows search, select-all checkbox, scrollable list of checkable participant rows.
//

import RealtimeKit
import UIKit

final class RtkBreakoutAssignPickerViewController: UIViewController {
    // MARK: - Dependencies

    private let allParticipants: [RtkConnectedMeetingParticipant]
    private let selfUserId: String
    private let onAssigned: ([String]) -> Void

    // MARK: - State

    private var filteredParticipants: [RtkConnectedMeetingParticipant] = []
    private var selectedIdentifiers = Set<String>()
    private var searchDebounceTimer: Timer?

    // MARK: - Subviews

    private lazy var headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Assign Participants"
        l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("✕", for: .normal)
        b.tintColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        b.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()

    private lazy var searchField: UITextField = {
        let f = UITextField()
        f.placeholder = "Search participants"
        f.borderStyle = .roundedRect
        f.backgroundColor = DesignLibrary.shared.color.background.shade800
        f.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        f.translatesAutoresizingMaskIntoConstraints = false
        f.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        return f
    }()

    private lazy var selectAllRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var selectAllCheckbox: UIView = {
        let v = UIView()
        v.layer.borderWidth = 2
        v.layer.borderColor = rtkSharedTokenColor.brand.shade500.cgColor
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectAllTapped))
        v.addGestureRecognizer(tap)
        v.isUserInteractionEnabled = true
        return v
    }()

    private lazy var selectAllCheckmark: UILabel = {
        let l = UILabel()
        l.text = "✓"
        l.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private lazy var selectAllLabel: UILabel = {
        let l = UILabel()
        l.text = "Select All"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var selectedCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .clear
        t.separatorStyle = .none
        t.register(SelectableParticipantTableViewCell.self, forCellReuseIdentifier: SelectableParticipantTableViewCell.reuseIdentifier)
        t.delegate = self
        t.dataSource = self
        return t
    }()

    private lazy var assignButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Assign", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.backgroundColor = rtkSharedTokenColor.brand.shade500
        b.tintColor = .white
        b.layer.cornerRadius = 8
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(assignTapped), for: .touchUpInside)
        b.isEnabled = false
        b.alpha = 0.5
        return b
    }()

    // MARK: - Init

    init(
        participants: [RtkConnectedMeetingParticipant],
        selfUserId: String,
        onAssigned: @escaping ([String]) -> Void,
    ) {
        allParticipants = participants
        self.selfUserId = selfUserId
        self.onAssigned = onAssigned
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: - Lifecycle

    deinit {
        searchDebounceTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignLibrary.shared.color.background.shade900
        filteredParticipants = allParticipants
        setupUI()
        updateSubtitle()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(closeButton)

        // RTK-8215: title/subtitle are truly centered between leading edge and close button.
        // Using greaterThanOrEqual on leading mirrors the close-button margin so long titles
        // never overlap the close button.
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 52),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -4),

            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 52),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -4),
        ])

        view.addSubview(searchField)
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 40),
        ])

        // Select all row
        selectAllCheckbox.addSubview(selectAllCheckmark)
        selectAllRow.addSubview(selectAllCheckbox)
        selectAllRow.addSubview(selectAllLabel)
        selectAllRow.addSubview(selectedCountLabel)
        view.addSubview(selectAllRow)

        NSLayoutConstraint.activate([
            selectAllRow.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            selectAllRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectAllRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            selectAllRow.heightAnchor.constraint(equalToConstant: 44),

            selectAllCheckbox.leadingAnchor.constraint(equalTo: selectAllRow.leadingAnchor),
            selectAllCheckbox.centerYAnchor.constraint(equalTo: selectAllRow.centerYAnchor),
            selectAllCheckbox.widthAnchor.constraint(equalToConstant: 20),
            selectAllCheckbox.heightAnchor.constraint(equalToConstant: 20),

            selectAllCheckmark.centerXAnchor.constraint(equalTo: selectAllCheckbox.centerXAnchor),
            selectAllCheckmark.centerYAnchor.constraint(equalTo: selectAllCheckbox.centerYAnchor),

            selectAllLabel.leadingAnchor.constraint(equalTo: selectAllCheckbox.trailingAnchor, constant: 12),
            selectAllLabel.centerYAnchor.constraint(equalTo: selectAllRow.centerYAnchor),

            selectedCountLabel.trailingAnchor.constraint(equalTo: selectAllRow.trailingAnchor),
            selectedCountLabel.centerYAnchor.constraint(equalTo: selectAllRow.centerYAnchor),
        ])

        // Table + assign button
        view.addSubview(tableView)
        view.addSubview(assignButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: selectAllRow.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: assignButton.topAnchor, constant: -8),

            assignButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            assignButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            assignButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            assignButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    // MARK: - Update

    private func updateSubtitle() {
        let total = allParticipants.count
        subtitleLabel.text = "\(total) unassigned"
    }

    private func updateSelectedCountLabel() {
        let count = selectedIdentifiers.count
        selectedCountLabel.text = count > 0 ? "\(count) selected" : ""
        assignButton.isEnabled = count > 0
        assignButton.alpha = count > 0 ? 1.0 : 0.5

        // Update select-all state
        let allSelected = !filteredParticipants.isEmpty &&
            filteredParticipants.allSatisfy { selectedIdentifiers.contains($0.identifier) }
        updateSelectAllCheckbox(isSelected: allSelected)
    }

    private func updateSelectAllCheckbox(isSelected: Bool) {
        selectAllCheckbox.backgroundColor = isSelected ? rtkSharedTokenColor.brand.shade500 : .clear
        selectAllCheckmark.isHidden = !isSelected
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func assignTapped() {
        let identifiers = Array(selectedIdentifiers)
        dismiss(animated: true) { [weak self] in
            self?.onAssigned(identifiers)
        }
    }

    @objc private func selectAllTapped() {
        let allSelected = !filteredParticipants.isEmpty &&
            filteredParticipants.allSatisfy { selectedIdentifiers.contains($0.identifier) }
        if allSelected {
            filteredParticipants.forEach { selectedIdentifiers.remove($0.identifier) }
        } else {
            filteredParticipants.forEach { selectedIdentifiers.insert($0.identifier) }
        }
        tableView.reloadData()
        updateSelectedCountLabel()
    }

    @objc private func searchChanged() {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self else { return }
            let query = searchField.text?.lowercased() ?? ""
            filteredParticipants = query.isEmpty
                ? allParticipants
                : allParticipants.filter { $0.displayName.lowercased().contains(query) }
            tableView.reloadData()
            updateSelectedCountLabel()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension RtkBreakoutAssignPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        filteredParticipants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SelectableParticipantTableViewCell.reuseIdentifier,
            for: indexPath,
        ) as? SelectableParticipantTableViewCell else {
            return UITableViewCell()
        }
        let participant = filteredParticipants[indexPath.row]
        let isSelf = participant.id == selfUserId || participant.customParticipantId == selfUserId
        cell.configure(
            participant: participant,
            isChecked: selectedIdentifiers.contains(participant.identifier),
            isSelf: isSelf,
        )
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let participant = filteredParticipants[indexPath.row]
        if selectedIdentifiers.contains(participant.identifier) {
            selectedIdentifiers.remove(participant.identifier)
        } else {
            selectedIdentifiers.insert(participant.identifier)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateSelectedCountLabel()
    }
}
