//
//  RtkBreakoutRoomsViewController.swift
//  RealtimeKitUI
//
//  Two-step host admin sheet for breakout rooms.
//  Step 1: Choose room count. Step 2: Assign participants, start/update/close.
//

import RealtimeKit
import UIKit

final class RtkBreakoutRoomsViewController: RtkBaseViewController {
    // MARK: - Dependencies

    private let manager = BreakoutRoomsManager()
    private var connectedMeetingsListener: RtkConnectedMeetingsListener?

    // MARK: - State

    private var roomCount = 2
    private var isLoading = false
    private var debounceTimer: Timer?
    private var cachedRooms: [DraftMeeting] = []

    private var isLive: Bool {
        meeting.connectedMeetings.isActive
    }

    /// True when the local user can switch rooms but cannot administer breakout rooms.
    private var isParticipantView: Bool {
        let perms = meeting.localUser.permissions.connectedMeetings
        return !perms.canAlterConnectedMeetings &&
            (perms.canSwitchConnectedMeetings || perms.canSwitchToParentMeeting)
    }

    /// RTK-8218: True when an admin is physically inside a child breakout room.
    /// In this state the panel shows Join navigation buttons (like participant view)
    /// while still retaining the admin action bar.
    private var isAdminInChildRoom: Bool {
        guard isLive, !isParticipantView else { return false }
        guard meeting.localUser.permissions.connectedMeetings.canAlterConnectedMeetings else { return false }
        let currentId = manager.currentRoomId(forUserId: localUserId)
        return currentId != nil && currentId != manager.parentMeetingId
    }

    private var localUserId: String {
        meeting.localUser.userId
    }

    /// Callback fired just before the local user is moved to a new room (onChangingMeeting).
    /// Used by the More Options sheet (RTK-8210) to dismiss itself when a room switch starts.
    var onRoomSwitchStarted: (() -> Void)?

    /// Rooms shown in the table. For participant view or admin-in-child-room the parent
    /// ("Main Room") is prepended so users can navigate back to the main session.
    private var displayedRooms: [DraftMeeting] {
        let needsNavigation = isParticipantView || isAdminInChildRoom
        guard needsNavigation else { return manager.allConnectedMeetings }

        // Prepend Main Room when the user can switch back to the parent.
        let canSwitchToParent = meeting.localUser.permissions.connectedMeetings.canSwitchToParentMeeting
            || isAdminInChildRoom
        if canSwitchToParent,
           let parentId = manager.parentMeetingId,
           var parentDraft = manager.allMeetingsMap[parentId]
        {
            parentDraft.title = "Main Room"
            return [parentDraft] + manager.allConnectedMeetings
        }
        return manager.allConnectedMeetings
    }

    // MARK: - Step container

    private lazy var stepContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Navigation header

    private lazy var headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("←", for: .normal)
        b.tintColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        b.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Breakout Rooms"
        l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var liveBadge: UILabel = {
        let l = UILabel()
        l.text = "● LIVE"
        l.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        l.textColor = UIColor.systemRed
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
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

    // MARK: - Step 1: Room count config

    private lazy var step1View: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var noOfRoomsLabel: UILabel = {
        let l = UILabel()
        l.text = "No. of Rooms"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var decrementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("−", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        b.tintColor = rtkSharedTokenColor.brand.shade500
        b.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        return b
    }()

    private lazy var roomCountField: UITextField = {
        let f = UITextField()
        f.text = "\(roomCount)"
        f.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        f.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        f.textAlignment = .center
        f.keyboardType = .numberPad
        f.borderStyle = .none
        f.translatesAutoresizingMaskIntoConstraints = false
        // Number-pad has no Return key — add a toolbar with a Done button.
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(commitRoomCountInput))
        toolbar.items = [flex, done]
        f.inputAccessoryView = toolbar
        return f
    }()

    private lazy var incrementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        b.tintColor = rtkSharedTokenColor.brand.shade500
        b.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        return b
    }()

    private lazy var distributionHintLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var createButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.backgroundColor = rtkSharedTokenColor.brand.shade500
        b.tintColor = .white
        b.layer.cornerRadius = 8
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Step 2: Participant config

    private lazy var step2View: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var roomsHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var addRoomButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Add Room", for: .normal)
        b.tintColor = rtkSharedTokenColor.brand.shade500
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(addRoomTapped), for: .touchUpInside)
        return b
    }()

    /// RTK-8216: Appears in the rooms header when at least one room has assigned participants.
    private lazy var unassignAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Unassign All", for: .normal)
        b.tintColor = UIColor.systemRed
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        b.addTarget(self, action: #selector(unassignAllTapped), for: .touchUpInside)
        return b
    }()

    /// Unassigned participants strip
    private lazy var unassignedSection: UIView = {
        let v = UIView()
        v.backgroundColor = DesignLibrary.shared.color.background.shade800
        v.layer.cornerRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var unassignedCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var unassignedFlowView: FlowView = {
        let v = FlowView()
        v.horizontalSpacing = 6
        v.verticalSpacing = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var shuffleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Shuffle", for: .normal)
        b.tintColor = rtkSharedTokenColor.brand.shade500
        b.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(shuffleTapped), for: .touchUpInside)
        return b
    }()

    private lazy var roomsTableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .clear
        t.separatorStyle = .none
        t.showsVerticalScrollIndicator = false
        t.register(BreakoutRoomTableViewCell.self, forCellReuseIdentifier: BreakoutRoomTableViewCell.reuseIdentifier)
        t.delegate = self
        t.dataSource = self
        return t
    }()

    /// Action bar
    private lazy var actionBarView: UIView = {
        let v = UIView()
        v.backgroundColor = DesignLibrary.shared.color.background.shade900
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var primaryActionButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.layer.cornerRadius = 8
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(primaryActionTapped), for: .touchUpInside)
        return b
    }()

    private lazy var secondaryActionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Discard Changes", for: .normal)
        b.tintColor = UIColor.systemRed
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(discardChangesTapped), for: .touchUpInside)
        b.isHidden = true
        return b
    }()

    /// Loading overlay
    private lazy var loadingOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        v.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }()

    // MARK: - Expansion state

    // RTK-8221: Only the first room is expanded by default.
    // roomExpandState stores explicit user-toggled states; rooms absent from the dict
    // follow the default (expanded only for index 0).
    private var roomExpandState: [String: Bool] = [:]

    // MARK: - Layout references for dynamic constraint swapping

    private var roomsHeaderContainer: UIView!
    /// Table top pinned below unassigned section (default for admin with participants).
    private var roomsTableTopConstraint: NSLayoutConstraint!
    /// Table top pinned directly below rooms header (participant view OR no unassigned participants).
    private var roomsTableTopToHeaderConstraint: NSLayoutConstraint!
    /// Table bottom pinned above action bar (default admin view).
    private var roomsTableBottomConstraint: NSLayoutConstraint!
    /// Table bottom pinned to step2View bottom (participant view).
    private var roomsTableBottomToStep2Constraint: NSLayoutConstraint!
    /// Explicit height for the unassigned FlowView — updated before layout so the section
    /// has the correct height on the FIRST Auto Layout pass (avoids the intrinsicContentSize
    /// chicken-and-egg problem where bounds.width is 0 when height is first queried).
    private var unassignedFlowHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    deinit {
        debounceTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignLibrary.shared.color.background.shade900
        setupHeader()
        setupStep1()
        setupStep2()
        setupLoadingOverlay()
        setupConnectedMeetingsListener()
        loadInitialState()
    }

    // MARK: - Setup

    private func setupHeader() {
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(liveBadge)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            liveBadge.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 6),
            liveBadge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
        ])

        let separator = UIView()
        separator.backgroundColor = DesignLibrary.shared.color.background.shade800
        separator.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func setupStep1() {
        view.addSubview(stepContainer)
        stepContainer.addSubview(step1View)

        NSLayoutConstraint.activate([
            stepContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            stepContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stepContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stepContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            step1View.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            step1View.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            step1View.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            step1View.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor),
        ])

        let stepperStack = UIStackView(arrangedSubviews: [decrementButton, roomCountField, incrementButton])
        stepperStack.axis = .horizontal
        stepperStack.spacing = 24
        stepperStack.alignment = .center
        stepperStack.translatesAutoresizingMaskIntoConstraints = false

        step1View.addSubview(noOfRoomsLabel)
        step1View.addSubview(stepperStack)
        step1View.addSubview(distributionHintLabel)
        step1View.addSubview(createButton)

        NSLayoutConstraint.activate([
            noOfRoomsLabel.topAnchor.constraint(equalTo: step1View.topAnchor, constant: 40),
            noOfRoomsLabel.centerXAnchor.constraint(equalTo: step1View.centerXAnchor),

            stepperStack.topAnchor.constraint(equalTo: noOfRoomsLabel.bottomAnchor, constant: 20),
            stepperStack.centerXAnchor.constraint(equalTo: step1View.centerXAnchor),

            roomCountField.widthAnchor.constraint(equalToConstant: 56),

            distributionHintLabel.topAnchor.constraint(equalTo: stepperStack.bottomAnchor, constant: 12),
            distributionHintLabel.leadingAnchor.constraint(equalTo: step1View.leadingAnchor, constant: 24),
            distributionHintLabel.trailingAnchor.constraint(equalTo: step1View.trailingAnchor, constant: -24),

            createButton.bottomAnchor.constraint(equalTo: step1View.bottomAnchor, constant: -32),
            createButton.leadingAnchor.constraint(equalTo: step1View.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: step1View.trailingAnchor, constant: -24),
            createButton.heightAnchor.constraint(equalToConstant: 48),
        ])

        updateDistributionHint()
    }

    private func setupStep2() {
        stepContainer.addSubview(step2View)
        step2View.isHidden = true

        NSLayoutConstraint.activate([
            step2View.topAnchor.constraint(equalTo: stepContainer.topAnchor),
            step2View.leadingAnchor.constraint(equalTo: stepContainer.leadingAnchor),
            step2View.trailingAnchor.constraint(equalTo: stepContainer.trailingAnchor),
            step2View.bottomAnchor.constraint(equalTo: stepContainer.bottomAnchor),
        ])

        // Rooms header bar
        let roomsHeader = UIView()
        roomsHeader.translatesAutoresizingMaskIntoConstraints = false
        step2View.addSubview(roomsHeader)
        roomsHeaderContainer = roomsHeader

        roomsHeader.addSubview(roomsHeaderLabel)
        roomsHeader.addSubview(unassignAllButton)
        roomsHeader.addSubview(addRoomButton)

        NSLayoutConstraint.activate([
            roomsHeader.topAnchor.constraint(equalTo: step2View.topAnchor, constant: 8),
            roomsHeader.leadingAnchor.constraint(equalTo: step2View.leadingAnchor, constant: 12),
            roomsHeader.trailingAnchor.constraint(equalTo: step2View.trailingAnchor, constant: -12),
            roomsHeader.heightAnchor.constraint(equalToConstant: 36),

            roomsHeaderLabel.leadingAnchor.constraint(equalTo: roomsHeader.leadingAnchor),
            roomsHeaderLabel.centerYAnchor.constraint(equalTo: roomsHeader.centerYAnchor),

            // RTK-8216: Unassign All sits between the label and the Add Room button
            unassignAllButton.trailingAnchor.constraint(equalTo: addRoomButton.leadingAnchor, constant: -8),
            unassignAllButton.centerYAnchor.constraint(equalTo: roomsHeader.centerYAnchor),

            addRoomButton.trailingAnchor.constraint(equalTo: roomsHeader.trailingAnchor),
            addRoomButton.centerYAnchor.constraint(equalTo: roomsHeader.centerYAnchor),
        ])

        // Unassigned section — chips now wrap into multiple rows via FlowView
        step2View.addSubview(unassignedSection)
        unassignedSection.addSubview(unassignedCountLabel)
        unassignedSection.addSubview(unassignedFlowView)
        unassignedSection.addSubview(shuffleButton)

        NSLayoutConstraint.activate([
            unassignedSection.topAnchor.constraint(equalTo: roomsHeader.bottomAnchor, constant: 8),
            unassignedSection.leadingAnchor.constraint(equalTo: step2View.leadingAnchor, constant: 12),
            unassignedSection.trailingAnchor.constraint(equalTo: step2View.trailingAnchor, constant: -12),

            unassignedCountLabel.topAnchor.constraint(equalTo: unassignedSection.topAnchor, constant: 8),
            unassignedCountLabel.leadingAnchor.constraint(equalTo: unassignedSection.leadingAnchor, constant: 8),

            shuffleButton.centerYAnchor.constraint(equalTo: unassignedCountLabel.centerYAnchor),
            shuffleButton.trailingAnchor.constraint(equalTo: unassignedSection.trailingAnchor, constant: -8),

            // FlowView: explicit height constraint (updated in refreshRoomList before layout)
            // prevents the section from collapsing on the first Auto Layout pass when
            // intrinsicContentSize can't yet know its width.
            // The bottomAnchor drives the section's own height from that height value.
            unassignedFlowView.topAnchor.constraint(equalTo: unassignedCountLabel.bottomAnchor, constant: 6),
            unassignedFlowView.leadingAnchor.constraint(equalTo: unassignedSection.leadingAnchor, constant: 8),
            unassignedFlowView.trailingAnchor.constraint(equalTo: unassignedSection.trailingAnchor, constant: -8),
            unassignedFlowView.bottomAnchor.constraint(equalTo: unassignedSection.bottomAnchor, constant: -8),
        ])

        unassignedFlowHeightConstraint = unassignedFlowView.heightAnchor.constraint(equalToConstant: 0)
        unassignedFlowHeightConstraint.priority = .defaultHigh // lets intrinsicContentSize win after first layout
        unassignedFlowHeightConstraint.isActive = true

        // Rooms table
        step2View.addSubview(roomsTableView)
        step2View.addSubview(actionBarView)
        actionBarView.addSubview(primaryActionButton)
        actionBarView.addSubview(secondaryActionButton)

        roomsTableTopConstraint = roomsTableView.topAnchor.constraint(equalTo: unassignedSection.bottomAnchor, constant: 8)
        roomsTableTopToHeaderConstraint = roomsTableView.topAnchor.constraint(equalTo: roomsHeaderContainer.bottomAnchor, constant: 8)
        roomsTableTopToHeaderConstraint.isActive = false

        roomsTableBottomConstraint = roomsTableView.bottomAnchor.constraint(equalTo: actionBarView.topAnchor)
        roomsTableBottomToStep2Constraint = roomsTableView.bottomAnchor.constraint(equalTo: step2View.bottomAnchor)
        roomsTableBottomToStep2Constraint.isActive = false

        NSLayoutConstraint.activate([
            roomsTableTopConstraint,
            roomsTableView.leadingAnchor.constraint(equalTo: step2View.leadingAnchor),
            roomsTableView.trailingAnchor.constraint(equalTo: step2View.trailingAnchor),
            roomsTableBottomConstraint,

            actionBarView.leadingAnchor.constraint(equalTo: step2View.leadingAnchor),
            actionBarView.trailingAnchor.constraint(equalTo: step2View.trailingAnchor),
            actionBarView.bottomAnchor.constraint(equalTo: step2View.bottomAnchor),

            primaryActionButton.topAnchor.constraint(equalTo: actionBarView.topAnchor, constant: 12),
            primaryActionButton.leadingAnchor.constraint(equalTo: actionBarView.leadingAnchor, constant: 16),
            primaryActionButton.trailingAnchor.constraint(equalTo: actionBarView.trailingAnchor, constant: -16),
            primaryActionButton.heightAnchor.constraint(equalToConstant: 48),

            secondaryActionButton.topAnchor.constraint(equalTo: primaryActionButton.bottomAnchor, constant: 8),
            secondaryActionButton.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            secondaryActionButton.bottomAnchor.constraint(equalTo: actionBarView.bottomAnchor, constant: -12),
        ])
    }

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupConnectedMeetingsListener() {
        connectedMeetingsListener = RtkConnectedMeetingsListener(rtkClient: meeting)

        connectedMeetingsListener?.onStateUpdate = { [weak self] meetings, parentMeeting in
            guard let self else { return }
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                guard let self else { return }
                manager.updateFromServer(parentMeeting: parentMeeting, meetings: meetings)
                refreshRoomList()
            }
        }

        connectedMeetingsListener?.onChangingMeeting = { [weak self] _ in
            // RTK-8210: notify the More Options sheet so it can dismiss itself before we go away
            self?.onRoomSwitchStarted?()
            // Dismiss this screen when the local participant is being moved to a breakout room
            self?.dismiss(animated: true)
        }
    }

    // MARK: - Initial state load

    private func loadInitialState() {
        if isParticipantView {
            // Participants: skip Step 1 entirely, load the live room list.
            fetchAndInitialize { [weak self] in
                self?.showStep2(animated: false)
            }
        } else {
            // Admin (live OR pre-start): always fetch so the manager is seeded with the
            // parentMeeting participants before the user reaches Step 2 and the assign picker.
            // The SDK returns a parentMeeting with all joined participants even before breakout
            // starts — Android does the same call on open.
            fetchAndInitialize { [weak self] in
                guard let self else { return }
                if isLive {
                    showStep2(animated: false)
                    refreshRoomList()
                } else {
                    showStep1()
                }
            }
        }
    }

    /// Calls `getConnectedMeetings`, seeds the manager on success, and runs `onSuccess`.
    /// Shows a blocking loading overlay during the fetch and handles errors inline.
    private func fetchAndInitialize(onSuccess: @escaping () -> Void) {
        setLoading(true)
        meeting.connectedMeetings.getConnectedMeetings { [weak self] result in
            guard let self else { return }
            setLoading(false)
            // AnyObject bridge: ObjC generic params are erased at runtime so Swift's static
            // "always fails" analysis is wrong — isKindOfClass dispatch handles this correctly.
            if let failure = result as AnyObject as? ResultFailure<ConnectedMeetingsError> {
                let msg = failure.value?.message ?? "Failed to load rooms"
                if isLive || isParticipantView {
                    // Fatal when live / participant: can't show rooms without state.
                    let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.dismiss(animated: true)
                    })
                    present(alert, animated: true)
                } else {
                    // Non-fatal pre-start: show Step 1 anyway; assign will be empty but UI is accessible.
                    showError(msg)
                    showStep1()
                }
                return
            }
            // On success the SDK has refreshed its cached parentMeeting / meetings properties.
            manager.initializeFromServer(
                parentMeeting: meeting.connectedMeetings.parentMeeting,
                meetings: meeting.connectedMeetings.meetings,
            )
            onSuccess()
        }
    }

    // MARK: - Step navigation

    private func showStep1() {
        backButton.isHidden = true
        liveBadge.isHidden = true
        step1View.isHidden = false
        step2View.isHidden = true
        updateDistributionHint()
    }

    private func showStep2(animated _: Bool = true) {
        backButton.isHidden = isLive || isParticipantView
        liveBadge.isHidden = true // RTK-8217: LIVE indicator removed from breakout rooms screen
        step1View.isHidden = true
        step2View.isHidden = false

        if isParticipantView {
            // Participant view: hide admin-only controls, fill table to screen bottom.
            addRoomButton.isHidden = true
            shuffleButton.isHidden = true
            unassignedSection.isHidden = true
            actionBarView.isHidden = true
            roomsTableTopConstraint.isActive = false
            roomsTableBottomConstraint.isActive = false
            roomsTableTopToHeaderConstraint.isActive = true
            roomsTableBottomToStep2Constraint.isActive = true
        } else {
            // Admin view: ensure controls are visible (guard against any prior hidden state).
            addRoomButton.isHidden = false
            shuffleButton.isHidden = false
            actionBarView.isHidden = false
        }

        refreshRoomList()
    }

    // MARK: - Refresh UI

    private func refreshRoomList() {
        cachedRooms = displayedRooms
        let rooms = cachedRooms

        // Show child-room count only (exclude the parent "Main Room" tile for participant view)
        let childCount = rooms.count(where: { !$0.isParent })
        roomsHeaderLabel.text = "Rooms (\(childCount))"

        if isParticipantView {
            // Participant view only: show no management UI.
            unassignedSection.isHidden = true
            unassignAllButton.isHidden = true
            roomsTableTopConstraint.isActive = false
            roomsTableTopToHeaderConstraint.isActive = true
        } else {
            // Admin (including admin-in-child-room): show full management UI so the admin
            // can still assign participants and manage rooms from wherever they are.
            let unassigned = manager.unassignedParticipants
            let hasUnassigned = !unassigned.isEmpty

            // Show/hide the unassigned section AND re-anchor the table so hidden section
            // leaves no dead space above the room list.
            if hasUnassigned {
                unassignedSection.isHidden = false
                roomsTableTopToHeaderConstraint.isActive = false
                roomsTableTopConstraint.isActive = true
            } else {
                unassignedSection.isHidden = true
                roomsTableTopConstraint.isActive = false
                roomsTableTopToHeaderConstraint.isActive = true
            }

            unassignedCountLabel.text = "\(unassigned.count) unassigned"
            unassignedFlowView.subviews.forEach { $0.removeFromSuperview() }
            for participant in unassigned {
                let chip = ParticipantChipView(participant: participant, showRemoveButton: false)
                unassignedFlowView.addSubview(chip)
            }

            // Pre-calculate the flow height so the unassigned section has the correct
            // height on the first Auto Layout pass — before intrinsicContentSize can
            // determine it from bounds (which are 0 until layout resolves the constraints).
            let sectionW = unassignedSection.bounds.width > 0
                ? unassignedSection.bounds.width
                : view.bounds.width > 0 ? view.bounds.width - 24 : UIScreen.main.bounds.width - 24
            let flowW = max(1, sectionW - 16) // 8pt inset each side inside the section
            let flowH = unassignedFlowView.calculateHeight(for: flowW)
            unassignedFlowHeightConstraint.constant = max(flowH, flowH > 0 ? flowH : 32)

            // RTK-8216: show Unassign All when at least one room has assigned participants
            let hasAssigned = manager.allConnectedMeetings
                .contains { !manager.participants(inMeeting: $0.id).isEmpty }
            unassignAllButton.isHidden = !hasAssigned
            addRoomButton.isHidden = false

            updateActionBar()
        }

        roomsTableView.reloadData()
    }

    private func updateActionBar() {
        if isLive, manager.hasLocalChanges {
            // Update mode
            primaryActionButton.setTitle("Update Breakout", for: .normal)
            primaryActionButton.backgroundColor = rtkSharedTokenColor.brand.shade500
            primaryActionButton.tintColor = .white
            secondaryActionButton.isHidden = false
        } else if isLive {
            // Close mode
            primaryActionButton.setTitle("Close Breakout", for: .normal)
            primaryActionButton.backgroundColor = UIColor.systemRed
            primaryActionButton.tintColor = .white
            secondaryActionButton.isHidden = true
        } else {
            // Create mode
            primaryActionButton.setTitle("Start Breakout", for: .normal)
            primaryActionButton.backgroundColor = rtkSharedTokenColor.brand.shade500
            primaryActionButton.tintColor = .white
            secondaryActionButton.isHidden = true
        }
    }

    private func updateDistributionHint() {
        let total = manager.allParticipantsMap.isEmpty
            ? meeting.participants.joined.count
            : manager.allParticipantsMap.count
        let perRoom = roomCount > 0 && total > 0
            ? Int(ceil(Double(total) / Double(roomCount)))
            : 0
        distributionHintLabel.text = perRoom > 0
            ? "Approx. \(perRoom) participants/room when equally divided."
            : ""
        decrementButton.alpha = roomCount <= 1 ? 0.4 : 1.0
        roomCountField.text = "\(roomCount)"
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        loadingOverlay.isHidden = !loading
    }

    // MARK: - Actions

    @objc private func backTapped() {
        if manager.hasLocalChanges {
            showDiscardAlert()
        } else {
            // No assigned participants yet — safe to reset without confirmation
            manager.reset()
            showStep1()
        }
    }

    @objc private func closeTapped() {
        // Participants never have local changes; admin views guard against accidental dismissal.
        if !isParticipantView, manager.hasLocalChanges {
            let alert = UIAlertController(
                title: "Discard changes?",
                message: "Your room setup will be lost.",
                preferredStyle: .alert,
            )
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func decrementTapped() {
        roomCountField.resignFirstResponder()
        if roomCount > 1 { roomCount -= 1 }
        updateDistributionHint()
    }

    @objc private func incrementTapped() {
        roomCountField.resignFirstResponder()
        roomCount += 1
        updateDistributionHint()
    }

    /// Commits a directly-typed room count: clamps to ≥ 1, dismisses the keyboard.
    @objc private func commitRoomCountInput() {
        let entered = Int(roomCountField.text ?? "") ?? roomCount
        roomCount = max(1, entered)
        roomCountField.resignFirstResponder()
        updateDistributionHint()
    }

    @objc private func createTapped() {
        commitRoomCountInput() // flush any in-progress typed value before proceeding
        manager.addNewMeetings(count: roomCount)
        showStep2()
    }

    @objc private func addRoomTapped() {
        manager.addNewMeeting()
        refreshRoomList()
    }

    @objc private func unassignAllTapped() {
        manager.unassignAllParticipants()
        refreshRoomList()
    }

    @objc private func shuffleTapped() {
        manager.assignParticipantsRandomly()
        refreshRoomList()
    }

    @objc private func primaryActionTapped() {
        if isLive, !manager.hasLocalChanges {
            showCloseConfirmation()
        } else {
            showStartConfirmation()
        }
    }

    @objc private func discardChangesTapped() {
        manager.discardChanges()
        meeting.connectedMeetings.getConnectedMeetings { [weak self] result in
            guard let self else { return }
            if let failure = result as AnyObject as? ResultFailure<ConnectedMeetingsError> {
                showError(failure.value?.message ?? "Failed to reload rooms")
                return
            }
            manager.initializeFromServer(
                parentMeeting: meeting.connectedMeetings.parentMeeting,
                meetings: meeting.connectedMeetings.meetings,
            )
            refreshRoomList()
        }
    }

    // MARK: - Confirmations

    private func showStartConfirmation() {
        // RTK-8214: cancel button labelled "Cancel" not "No, go back"
        let title = isLive ? "Update breakout rooms?" : "Start breakout rooms?"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.applyChanges()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showCloseConfirmation() {
        let alert = UIAlertController(title: "Close breakout rooms?", message: "All participants will be returned to the main room.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.closeBreakout()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showDiscardAlert() {
        let alert = UIAlertController(title: "Your room setup will be lost", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go Back", style: .destructive) { [weak self] _ in
            // reset() clears draft rooms entirely — discardChanges() only clears the dirty flag
            // and would leave the rooms in allMeetingsMap, causing duplicates on next Create
            self?.manager.reset()
            self?.showStep1()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Apply / Close

    private func applyChanges() {
        setLoading(true)
        manager.applyChanges(meeting: meeting) { [weak self] (error: ConnectedMeetingsError?) in
            guard let self else { return }
            setLoading(false)
            if error != nil {
                showError("Failed to apply changes. Please try again.")
                return
            }
            meeting.connectedMeetings.getConnectedMeetings { [weak self] result in
                guard let self else { return }
                if let failure = result as AnyObject as? ResultFailure<ConnectedMeetingsError> {
                    showError(failure.value?.message ?? "Failed to reload rooms")
                    return
                }
                manager.initializeFromServer(
                    parentMeeting: meeting.connectedMeetings.parentMeeting,
                    meetings: meeting.connectedMeetings.meetings,
                )
                refreshRoomList()
            }
        }
    }

    private func closeBreakout() {
        setLoading(true)
        manager.closeBreakout(meeting: meeting) { [weak self] (error: ConnectedMeetingsError?) in
            guard let self else { return }
            setLoading(false)
            if error != nil {
                showError("Failed to close breakout rooms.")
            } else {
                dismiss(animated: true)
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Assign picker

    func showAssignPicker(forRoomId roomId: String) {
        let unassigned = manager.unassignedParticipants
        guard !unassigned.isEmpty else { return }

        let selfId = meeting.localUser.userId

        let picker = RtkBreakoutAssignPickerViewController(
            participants: unassigned,
            selfUserId: selfId,
            onAssigned: { [weak self] selectedIdentifiers in
                guard let self else { return }
                manager.assignParticipants(identifiers: selectedIdentifiers, toMeeting: roomId)
                refreshRoomList()
            },
        )
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    /// Moves the local participant into the specified breakout room (or back to the parent).
    private func joinRoom(meetingId: String) {
        let userId = localUserId
        // Resolve the local participant's server peer id (required by moveParticipants).
        guard let localParticipant = manager.allParticipantsMap.values.first(where: {
            $0.id == userId || $0.customParticipantId == userId
        }) else { return }

        // Determine source room: where the user currently is.
        let sourceMeetingId = manager.currentRoomId(forUserId: userId) ?? manager.parentMeetingId ?? meetingId

        setLoading(true)
        meeting.connectedMeetings.moveParticipants(
            sourceMeetingId: sourceMeetingId,
            destinationMeetingId: meetingId,
            participantIds: [localParticipant.id],
        ) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.setLoading(false)
                if let error {
                    self.showError(error.message)
                }
                // UI refresh is handled by the onStateUpdate listener.
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension RtkBreakoutRoomsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        cachedRooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BreakoutRoomTableViewCell.reuseIdentifier,
            for: indexPath,
        ) as? BreakoutRoomTableViewCell else {
            return UITableViewCell()
        }

        let meetings = cachedRooms
        guard indexPath.row < meetings.count else { return cell }
        let room = meetings[indexPath.row]
        let participants = manager.participants(inMeeting: room.id)

        // RTK-8221: first room expanded by default; others collapsed; user toggles override.
        let isExpanded = roomExpandState[room.id] ?? (indexPath.row == 0)

        let participantView = isParticipantView
        let adminInChildRoom = isAdminInChildRoom
        // Navigation mode: participant OR admin physically inside a child room (RTK-8218).
        // Admin-in-child-room gets navigation JOIN buttons to move between rooms.
        let showNavigation = participantView || adminInChildRoom
        let canAlter = meeting.localUser.permissions.connectedMeetings.canAlterConnectedMeetings

        // Admin keeps ALL management controls (assign, delete, remove-chip, title edit)
        // regardless of which room they are physically in. Only participants lose these.
        let canModify = !participantView && canAlter
        // RTK-8218: admins can edit room titles from any room they are in.
        let canEditTitle = !participantView && canAlter
        // Delete: needs 2+ child rooms, and no delete button on the parent "Main Room" tile.
        let canDelete = canModify && !room.isParent && cachedRooms.count(where: { !$0.isParent }) > 1

        // Determine current room for navigation highlighting.
        let localCurrentRoomId = showNavigation ? manager.currentRoomId(forUserId: localUserId) : nil
        let isCurrentRoom: Bool = if room.isParent {
            localCurrentRoomId == nil || localCurrentRoomId == manager.parentMeetingId
        } else {
            localCurrentRoomId == room.id
        }

        // Join button rules — consistent across all tiles:
        // Show Join only when the user has no Assign/management controls (i.e., participants).
        // Admin always has Assign and never gets a Join button, even on the Main Room tile.
        // RTK-8212: for child rooms also gate on canSwitchConnectedMeetings to hide Join from
        //           switch-to-parent-only users who cannot freely move between child rooms.
        let canJoinThisRoom: Bool = if room.isParent {
            showNavigation && !canModify
        } else {
            showNavigation && !canModify &&
                meeting.localUser.permissions.connectedMeetings.canSwitchConnectedMeetings
        }

        cell.configure(
            meeting: room,
            participants: participants,
            isExpanded: isExpanded,
            showAssignButton: canModify && !room.isParent, // never Assign on the Main Room tile
            canModify: canModify,
            canEditTitle: canEditTitle,
            canDelete: canDelete,
            showJoinButton: canJoinThisRoom,
            isCurrentRoom: isCurrentRoom,
            onAssign: { [weak self] in
                self?.showAssignPicker(forRoomId: room.id)
            },
            onRemoveParticipant: { [weak self] identifier in
                self?.manager.unassignParticipants(identifiers: [identifier])
                self?.refreshRoomList()
            },
            onJoin: { [weak self] in
                self?.joinRoom(meetingId: room.id)
            },
            onDelete: canDelete ? { [weak self] in
                self?.manager.deleteMeeting(id: room.id)
                self?.refreshRoomList()
            } : nil,
            onTitleChanged: canEditTitle ? { [weak self] newTitle in
                self?.manager.updateTitle(ofMeeting: room.id, to: newTitle)
            } : nil,
        )
        cell.onToggleExpand = { [weak self] newIsExpanded in
            guard let self else { return }
            roomExpandState[room.id] = newIsExpanded
            // Animate the row height change driven by the zeroed/restored constraints.
            roomsTableView.beginUpdates()
            roomsTableView.endUpdates()
        }
        return cell
    }

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        100
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard meeting.localUser.permissions.connectedMeetings.canAlterConnectedMeetings else { return nil }
        let meetings = cachedRooms
        guard indexPath.row < meetings.count else { return nil }
        let room = meetings[indexPath.row]
        // Mirror the canDelete guard from cellForRowAt: never delete the parent tile and
        // never allow deletion that would leave fewer than one child room.
        guard !room.isParent, meetings.count(where: { !$0.isParent }) > 1 else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.manager.deleteMeeting(id: room.id)
            self?.refreshRoomList()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
