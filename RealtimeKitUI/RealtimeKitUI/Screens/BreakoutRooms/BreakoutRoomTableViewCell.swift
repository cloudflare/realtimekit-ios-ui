//
//  BreakoutRoomTableViewCell.swift
//  RealtimeKitUI
//

import RealtimeKit
import UIKit

private let kMinRoomTitleLength = 3

// MARK: - ParticipantChipView

/// A single participant chip: circular avatar initial + name + optional remove button.
final class ParticipantChipView: UIView {
    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let removeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("✕", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        b.tintColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    var onRemove: (() -> Void)?
    private let showRemoveButton: Bool

    init(participant: RtkConnectedMeetingParticipant, showRemoveButton: Bool = true) {
        self.showRemoveButton = showRemoveButton
        super.init(frame: .zero)
        configure(participant: participant)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func configure(participant: RtkConnectedMeetingParticipant) {
        backgroundColor = DesignLibrary.shared.color.background.shade800
        layer.cornerRadius = 14
        layer.masksToBounds = true

        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.backgroundColor = rtkSharedTokenColor.brand.shade500
        avatarContainer.layer.cornerRadius = 12
        avatarContainer.layer.masksToBounds = true

        avatarContainer.addSubview(avatarLabel)
        addSubview(avatarContainer)
        addSubview(nameLabel)

        let initial = participant.displayName.prefix(1).uppercased()
        avatarLabel.text = initial.isEmpty ? "?" : initial
        nameLabel.text = participant.displayName

        NSLayoutConstraint.activate([
            avatarContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            avatarContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 24),
            avatarContainer.heightAnchor.constraint(equalToConstant: 24),
            avatarContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            avatarContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 6),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        if showRemoveButton {
            addSubview(removeButton)
            NSLayoutConstraint.activate([
                removeButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
                removeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                removeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                removeButton.widthAnchor.constraint(equalToConstant: 16),
            ])
            removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        } else {
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        }
    }

    @objc private func removeTapped() {
        onRemove?()
    }
}

// MARK: - BreakoutRoomTableViewCell

final class BreakoutRoomTableViewCell: UITableViewCell {
    static let reuseIdentifier = "BreakoutRoomTableViewCell"

    // MARK: Subviews

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = DesignLibrary.shared.color.background.shade800
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let headerStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let expandArrow: UILabel = {
        let l = UILabel()
        l.text = "▼"
        l.font = UIFont.systemFont(ofSize: 10)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        return l
    }()

    /// RTK-8219: pencil icon shown beside the title when the room is editable.
    private let editHintIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "pencil"))
        iv.tintColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        iv.alpha = 0.5
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        iv.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 14).isActive = true
        return iv
    }()

    /// Displays the room title. Acts as a read-only label by default; becomes editable on tap when
    /// `canEditTitle` is true. Minimum valid title length is `kMinRoomTitleLength` characters.
    private let roomTitleField: UITextField = {
        let f = UITextField()
        f.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        f.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        f.borderStyle = .none
        f.returnKeyType = .done
        f.isUserInteractionEnabled = false // enabled only when canModify and tapped
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    private let participantCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        return l
    }()

    private let assignButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Assign", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        b.tintColor = rtkSharedTokenColor.brand.shade500
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let joinButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Join", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        b.tintColor = rtkSharedTokenColor.brand.shade500
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    /// Admin-only delete button shown in the cell header so deletion is discoverable without swipe.
    private let deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("✕", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        b.tintColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    private let chipsFlowView: FlowView = {
        let v = FlowView()
        v.horizontalSpacing = 6
        v.verticalSpacing = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No participants assigned yet"
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private var chipsHeightConstraint: NSLayoutConstraint!
    private var emptyLabelHeightConstraint: NSLayoutConstraint!
    /// Top spacing between the header stack and the chips scroll view.
    /// Zeroed when collapsed so the hidden content area contributes no height.
    private var chipsTopSpacingConstraint: NSLayoutConstraint!

    // MARK: Callbacks

    var onAssign: (() -> Void)?
    var onRemoveParticipant: ((_ identifier: String) -> Void)?
    var onJoin: (() -> Void)?
    var onDelete: (() -> Void)?
    var onTitleChanged: ((String) -> Void)?
    /// Called after the header tap toggles expansion. `isExpanded` is the new state.
    var onToggleExpand: ((_ isExpanded: Bool) -> Void)?

    // MARK: State

    private var isExpanded = true
    private var showAssignButton = true
    private var showJoinButton = false
    private var canModify = true
    private var canEditTitle = true
    private var originalTitle = ""

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(headerStack)
        containerView.addSubview(chipsFlowView)
        containerView.addSubview(emptyLabel)

        roomTitleField.delegate = self

        headerStack.addArrangedSubview(expandArrow)
        headerStack.addArrangedSubview(roomTitleField)
        headerStack.addArrangedSubview(editHintIcon) // RTK-8219: pencil hint
        headerStack.addArrangedSubview(participantCountLabel)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(spacer)
        headerStack.addArrangedSubview(assignButton)
        headerStack.addArrangedSubview(joinButton)
        headerStack.addArrangedSubview(deleteButton)

        // Collapsed-state override: forces FlowView to 0 height.
        // NOT activated by default — expanded rows size themselves via FlowView.intrinsicContentSize.
        chipsHeightConstraint = chipsFlowView.heightAnchor.constraint(equalToConstant: 0)
        emptyLabelHeightConstraint = emptyLabel.heightAnchor.constraint(equalToConstant: 0)
        chipsTopSpacingConstraint = chipsFlowView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            headerStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            chipsTopSpacingConstraint,
            chipsFlowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            chipsFlowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            emptyLabel.topAnchor.constraint(equalTo: chipsFlowView.bottomAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            emptyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            emptyLabelHeightConstraint,
            emptyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
        ])

        assignButton.addTarget(self, action: #selector(assignTapped), for: .touchUpInside)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped(_:)))
        headerStack.addGestureRecognizer(tapGesture)
        headerStack.isUserInteractionEnabled = true
    }

    // MARK: Configure

    func configure(
        meeting: DraftMeeting,
        participants: [RtkConnectedMeetingParticipant],
        isExpanded: Bool,
        showAssignButton: Bool,
        canModify: Bool = true,
        canEditTitle: Bool = true,
        canDelete: Bool = false,
        showJoinButton: Bool = false,
        isCurrentRoom: Bool = false,
        onAssign: @escaping () -> Void,
        onRemoveParticipant: @escaping (_ identifier: String) -> Void,
        onJoin: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTitleChanged: ((String) -> Void)? = nil,
    ) {
        self.isExpanded = isExpanded
        self.showAssignButton = showAssignButton
        self.showJoinButton = showJoinButton
        self.canModify = canModify
        self.canEditTitle = canEditTitle
        self.onAssign = onAssign
        self.onRemoveParticipant = onRemoveParticipant
        self.onJoin = onJoin
        self.onDelete = onDelete
        self.onTitleChanged = onTitleChanged

        originalTitle = meeting.title
        roomTitleField.text = meeting.title
        roomTitleField.isUserInteractionEnabled = false // reset; editing starts on tap
        participantCountLabel.text = "(\(participants.count))"

        // RTK-8219: pencil hint shows only when the title is editable
        editHintIcon.isHidden = !canEditTitle

        // Join button: always visible in header for participant view, dimmed when already in this room
        joinButton.isHidden = !showJoinButton
        joinButton.alpha = isCurrentRoom ? 0.4 : 1.0
        joinButton.isEnabled = !isCurrentRoom

        // Delete button: visible for admin when deletion is permitted
        deleteButton.isHidden = !canDelete

        // Assign lives in the header — always visible regardless of expand/collapse state
        assignButton.isHidden = !showAssignButton

        updateChips(participants: participants, showRemoveButton: showAssignButton)
        updateExpandedState(animated: false)
    }

    private func updateChips(participants: [RtkConnectedMeetingParticipant], showRemoveButton: Bool) {
        chipsFlowView.subviews.forEach { $0.removeFromSuperview() }

        for participant in participants {
            let chip = ParticipantChipView(participant: participant, showRemoveButton: showRemoveButton)
            chip.onRemove = { [weak self] in
                self?.onRemoveParticipant?(participant.identifier)
            }
            chipsFlowView.addSubview(chip)
        }

        // FlowView.intrinsicContentSize (backed by its flow() engine) sizes the chip area.
        // No explicit height constraint is set here; chipsHeightConstraint is only activated
        // when the card collapses (see updateExpandedState).
        let hasParticipants = !participants.isEmpty
        emptyLabelHeightConstraint.constant = hasParticipants ? 0 : 32
        chipsFlowView.isHidden = !hasParticipants
        emptyLabel.isHidden = hasParticipants
    }

    private func updateExpandedState(animated _: Bool) {
        let arrow = isExpanded ? "▼" : "▶"
        expandArrow.text = arrow

        let hasParticipants = !chipsFlowView.subviews.isEmpty
        if isExpanded {
            // Expanded: deactivate the height override so FlowView.intrinsicContentSize
            // drives the height — it wraps chips into as many rows as needed.
            chipsHeightConstraint.isActive = false
            chipsTopSpacingConstraint.constant = 8
            emptyLabelHeightConstraint.constant = hasParticipants ? 0 : 32
            chipsFlowView.isHidden = !hasParticipants
            emptyLabel.isHidden = hasParticipants
        } else {
            // Collapsed: activate the 0-height constraint so the card shrinks to header-only.
            chipsHeightConstraint.constant = 0
            chipsHeightConstraint.isActive = true
            chipsTopSpacingConstraint.constant = 0
            emptyLabelHeightConstraint.constant = 0
            chipsFlowView.isHidden = true
            emptyLabel.isHidden = true
        }

        // Assign lives in the header — always visible regardless of expand/collapse state
        assignButton.isHidden = !showAssignButton
        // Other header-only controls also stay visible regardless of expand/collapse
        editHintIcon.isHidden = !canEditTitle
        joinButton.isHidden = !showJoinButton
        deleteButton.isHidden = onDelete == nil
    }

    // MARK: Actions

    @objc private func assignTapped() {
        onAssign?()
    }

    @objc private func joinTapped() {
        onJoin?()
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    @objc private func headerTapped(_ gesture: UITapGestureRecognizer) {
        // If the tap lands on the title field and the cell is editable, start inline editing
        // instead of toggling expand/collapse.
        let location = gesture.location(in: headerStack)
        // RTK-8218: admins can edit titles from any room — use canEditTitle, not canModify
        if canEditTitle, roomTitleField.frame.contains(location) {
            roomTitleField.isUserInteractionEnabled = true
            roomTitleField.becomeFirstResponder()
            return
        }
        isExpanded.toggle()
        updateExpandedState(animated: true)
        onToggleExpand?(isExpanded)
    }
}

// MARK: - UITextFieldDelegate

extension BreakoutRoomTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        commitTitleEdit(textField)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        commitTitleEdit(textField)
    }

    private func commitTitleEdit(_ textField: UITextField) {
        let trimmed = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if trimmed.count >= kMinRoomTitleLength {
            originalTitle = trimmed
            textField.text = trimmed
            onTitleChanged?(trimmed)
        } else {
            // Revert to the last valid title without triggering a callback.
            textField.text = originalTitle
        }
        textField.isUserInteractionEnabled = false
        textField.resignFirstResponder()
    }
}
