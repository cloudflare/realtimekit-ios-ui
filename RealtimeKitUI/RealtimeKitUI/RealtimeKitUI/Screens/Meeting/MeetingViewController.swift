//
//  MeetingViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 21/12/22.
//

import AVFAudio
import AVKit
import RealtimeKit
import UIKit

public enum Animations {
    public static let gridViewAnimationDuration = 0.3
}

public protocol MeetingViewControllerDataSource {
    func getTopbar(viewController: MeetingViewController) -> RtkMeetingHeaderView?
    func getMiddleView(viewController: MeetingViewController) -> UIView?
    func getBottomTabbar(viewController: MeetingViewController) -> RtkMeetingControlBar?
}

open class RtkBaseMeetingViewController: RtkBaseViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        initialisePrivateChatNotificationLookup()
    }

    private func initialisePrivateChatNotificationLookup() {
        Shared.data.privateChatReadLookup[RtkChatViewController.keyEveryOne] = false
        for participant in meeting.participants.joined {
            if participant.userId != meeting.localUser.userId {
                if meeting.chat.getPrivateChatMessages(participant: participant).count > 0 {
                    Shared.data.privateChatReadLookup[participant.userId] = true
                } else {
                    Shared.data.privateChatReadLookup[participant.userId] = false
                }
            }
        }
    }
}

public class MeetingViewController: RtkBaseMeetingViewController {
    private var gridView: GridView<RtkParticipantTileContainerView>!
    let pluginScreenShareView: RtkPluginsView
    let pinnedView = RtkParticipantTileContainerView()
    var pipController: RtkPipController?
    let gridBaseView = UIView()
    private let pluginPinnedScreenShareBaseView = UIView()
    private var fullScreenView: FullScreenView!

    let baseContentView = UIView()

    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    public var dataSource: MeetingViewControllerDataSource?

    let fullScreenButton: RtkControlBarButton = {
        let button = RtkControlBarButton(image: RtkImage(image: ImageProvider.image(named: "icon_show_fullscreen")))
        button.setSelected(image: RtkImage(image: ImageProvider.image(named: "icon_hide_fullscreen")))
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        return button
    }()

    let viewModel: MeetingViewModel

    private var topBar: RtkMeetingHeaderView!
    private var bottomBar: RtkControlBar!

    let onFinishedMeeting: () -> Void
    private var viewWillAppear = false

    var moreButtonBottomBar: RtkControlBarButton?
    private var layoutConstraintPluginBaseZeroHeight: NSLayoutConstraint!
    private var layoutPortraitConstraintPluginBaseVariableHeight: NSLayoutConstraint!
    private var layoutLandscapeConstraintPluginBaseVariableWidth: NSLayoutConstraint!
    private var layoutConstraintPluginBaseZeroWidth: NSLayoutConstraint!

    private var waitingRoomView: WaitingRoomView?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid

    public init(meeting: RealtimeKitClient, completion: @escaping () -> Void) {
        // TODO: Check the local user passed now
        pluginScreenShareView = RtkPluginsView(videoPeerViewModel: VideoPeerViewModel(meeting: meeting, participant: meeting.localUser, showSelfPreviewVideo: false, showScreenShareVideoView: true))
        onFinishedMeeting = completion
        viewModel = MeetingViewModel(rtkClient: meeting)
        super.init(meeting: meeting)
        notificationDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.containerView.get(.top)?.constant = view.safeAreaInsets.top
        if UIScreen.isLandscape() {
            bottomBar.setWidth()
        } else {
            bottomBar.setHeight()
        }
        setLeftPaddingConstraintForBaseContentView()
    }

    private func setLeftPaddingConstraintForBaseContentView() {
        if UIScreen.deviceOrientation == .landscapeLeft {
            baseContentView.get(.bottom)?.constant = -view.safeAreaInsets.bottom
            baseContentView.get(.leading)?.constant = view.safeAreaInsets.bottom
        } else if UIScreen.deviceOrientation == .landscapeRight {
            baseContentView.get(.bottom)?.constant = -view.safeAreaInsets.bottom
            baseContentView.get(.leading)?.constant = view.safeAreaInsets.right
        }
    }

    private func shouldShowNotificationBubble() -> Bool {
        let totalPollsAndChatCount = Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: meeting.chat.messages.count, totalsPolls: meeting.polls.items.count)
        return meeting.getPendingParticipantCount() > 0 || totalPollsAndChatCount > 0
    }

    public func updateMoreButtonNotificationBubble() {
        if shouldShowNotificationBubble() {
            moreButtonBottomBar?.notificationBadge.isHidden = false
        } else {
            moreButtonBottomBar?.notificationBadge.isHidden = true
        }
    }

    private func setUpBackgroundNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(appdidMoveTobackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc
    func appdidMoveTobackground() {
        requestBackgroundTime()
    }

    @objc
    func appWillMoveToForeground() {
        endBackgroundTask()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        view.accessibilityIdentifier = "Meeting_Base_View"
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        createTopbar()
        createBottomBar()
        createSubView()
        applyConstraintAsPerOrientation()
        setInitialsConfiguration()
        setupNotifications()
        viewModel.delegate = self

        viewModel.selfEventListener.observeSelfMeetingEndForAll { [weak self] _ in
            guard let self else { return }

            func showWaitingRoom(status: ParticipantMeetingStatus, time _: TimeInterval, onComplete: @escaping () -> Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            // self.dismiss(animated: true)
            showWaitingRoom(status: .meetingEnded, time: 2) { [weak self] in
                guard let self else { return }
                viewModel.clean()
                onFinishedMeeting()
            }
        }

        viewModel.selfEventListener.observeSelfRemoved { [weak self] _ in
            guard let self else { return }

            func showWaitingRoom(status: ParticipantMeetingStatus, time _: TimeInterval, onComplete: @escaping () -> Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            // self.dismiss(animated: true)
            showWaitingRoom(status: .kicked, time: 2) { [weak self] in
                guard let self else { return }
                viewModel.clean()
                onFinishedMeeting()
            }
        }
        viewModel.selfEventListener.observePluginScreenShareTabSync(update: { id in
            self.selectPluginOrScreenShare(id: id)
        })

        if meeting.localUser.permissions.host.canAcceptRequests {
            viewModel.waitlistEventListener.participantJoinedCompletion = { [weak self] participant in
                guard let self else { return }
                view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0, uiBlocker: false)
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }

            viewModel.waitlistEventListener.participantRequestRejectCompletion = { [weak self] _ in
                guard let self else { return }
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
            viewModel.waitlistEventListener.participantRequestAcceptedCompletion = { [weak self] _ in
                guard let self else { return }
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
            viewModel.waitlistEventListener.participantRemovedCompletion = { [weak self] _ in
                guard let self else { return }
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
        }
        addWaitingRoom { [weak self] in
            guard let self else { return }
            viewModel.clean()
            onFinishedMeeting()
        }
        setUpReconnection { [weak self] in
            guard let self else { return }
            viewModel.clean()
            onFinishedMeeting()
        } success: { [weak self] in
            guard let self else { return }
            refreshMeetingGrid()
            refreshPluginsScreenShareView()
        }
        // pipController = RtkPipController(renderingView: self.gridBaseView, localUser: meeting.localUser)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewWillAppear == false {
            viewWillAppear = true
            viewModel.refreshActiveParticipants()
            viewModel.trackOnGoingState()

            if shouldShowNotificationBubble() {
                moreButtonBottomBar?.notificationBadge.isHidden = false
            } else {
                moreButtonBottomBar?.notificationBadge.isHidden = true
            }
        }
    }

    private func refreshPipViewWhenChangedInActiveParticipant() {
        if meeting.participants.active.count <= 1 {
            pipController?.setSecondaryUser(otherParticipant: nil)
        } else {
            if pipController?.otherUser != nil {
                // It must be part of activeParticipant, Participant shouldn't leave the meeting
                if meeting.participants.active.contains(pipController!.otherUser!) == false {
                    if meeting.participants.active.count > 1 {
                        for participant in meeting.participants.active {
                            if participant.userId != meeting.localUser.userId {
                                pipController?.setSecondaryUser(otherParticipant: participant)
                                break
                            }
                        }
                    }
                }
            } else {
                if meeting.participants.active.count > 1 {
                    for participant in meeting.participants.active {
                        if participant.userId != meeting.localUser.userId {
                            pipController?.setSecondaryUser(otherParticipant: participant)
                            break
                        }
                    }
                }
            }
        }
    }

    public func refreshMeetingGrid(forRotation: Bool = false) {
        refreshPipViewWhenChangedInActiveParticipant()
        if isDebugModeOn {
            print("Debug RtkUIKit | refreshMeetingGrid")
        }

        meetingGridPageBecomeVisible()

        let arrModels = viewModel.arrGridParticipants

        if isDebugModeOn {
            print("Debug RtkUIKIt | refreshing Finished")
        }

        func prepareGridViewsForReuse() {
            gridView.prepareForReuse { peerView in
                peerView.prepareForReuse()
            }
        }

        func loadGridAndPluginView(showPluginPinnedView: Bool, animation: Bool) {
            showHidePluginPinnedAndScreenShareView()
            loadGrid(fullScreen: !showPluginPinnedView, animation: !animation, completion: {
                if forRotation == false {
                    prepareGridViewsForReuse()
                    populateGridChildViews(models: arrModels)
                }
            })
        }

        if viewModel.pinOrPluginScreenShareModeIsActive() {
            loadGridAndPluginView(showPluginPinnedView: true, animation: false)
        } else {
            loadGridAndPluginView(showPluginPinnedView: false, animation: false)
        }

        if viewModel.pinOrPluginScreenShareModeIsActive() {
            refreshPluginsScreenShareView()
        }

        func populateGridChildViews(models: [GridCellViewModel]) {
            for i in 0 ..< models.count {
                if let peerContainerView = gridView.childView(index: i) {
                    let isSelf = models[i].participant.id == meeting.localUser.id
                    if isSelf {
                        if let selfParticipant = models[i].participant as? RtkSelfParticipant {
                            peerContainerView.setParticipant(meeting: meeting, participant: selfParticipant)
                        }
                    } else if let participant = models[i].participant as? RtkRemoteParticipant {
                        peerContainerView.setParticipant(meeting: meeting, participant: participant)
                    }
                }
            }
            if isDebugModeOn {
                print("Debug RtkUIKit | Iterating for Items \(arrModels.count)")
                for i in 0 ..< models.count {
                    if let peerContainerView = gridView.childView(index: i), let tileView = peerContainerView.tileView {
                        print("Debug RtkUIKit | Tile View Exists \(tileView) \nSuperView \(String(describing: tileView.superview))")
                    }
                }
            }
        }
    }

    func getBottomBar() -> RtkControlBar {
        let controlBar = RtkMeetingControlBar(meeting: meeting, delegate: nil, presentingViewController: self) {
            [weak self] in
            guard let self else { return }
            refreshMeetingGridTile(participant: meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self else { return }
            viewModel.clean()
            onFinishedMeeting()
        }
        controlBar.accessibilityIdentifier = "Meeting_ControlBottomBar"
        return controlBar
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("NotificationAllChatsRead"), object: nil)
        if isDebugModeOn {
            print("RtkUIKit | MeetingViewController Deinit is calling ")
        }

        UIApplication.shared.isIdleTimerDisabled = false
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        presentedViewController?.dismiss(animated: false)
        bottomBar.moreButton.hideBottomSheet()
        if UIScreen.isLandscape() {
            bottomBar.moreButton.superview?.isHidden = true
        } else {
            bottomBar.moreButton.superview?.isHidden = false
        }

        applyConstraintAsPerOrientation { [weak self] in
            guard let self else { return }
            fullScreenButton.isHidden = true
            closefullscreen()
        } onLandscape: { [weak self] in
            guard let self else { return }
            fullScreenButton.isSelected = false
            fullScreenButton.isHidden = false
        }

        showPinnedPluginViewAsPerOrientation(show: false)
        setLeftPaddingConstraintForBaseContentView()
        DispatchQueue.main.async {
            self.refreshMeetingGrid(forRotation: true)
        }
    }
}

// MARK: Background extended time

extension MeetingViewController {
    private func requestBackgroundTime() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "WebRTCBackgroundTask") { [weak self] in
            print("*****Background task time remaining for Finish \(UIApplication.shared.backgroundTimeRemaining)")

            self?.requestBackgroundTime()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}

extension MeetingViewController: AVPictureInPictureControllerDelegate {}

// Bottom bar related Methods
extension MeetingViewController {
    private func createBottomBar() {
        bottomBar = dataSource?.getBottomTabbar(viewController: self) ?? getBottomBar()
        moreButtonBottomBar = bottomBar.moreButton
        view.addSubview(bottomBar)
        addBottomBarConstraint()
    }

    private func addBottomBarConstraint() {
        addPortraitConstraintBottombar()
        addLandscapeConstraintBottombar()
        if UIScreen.isLandscape() {
            moreButtonBottomBar?.superview?.isHidden = true
        }
    }

    private func addPortraitConstraintBottombar() {
        bottomBar.set(.sameLeadingTrailing(view),
                      .bottom(view))
        portraitConstraints.append(contentsOf: [bottomBar.get(.leading)!,
                                                bottomBar.get(.trailing)!,
                                                bottomBar.get(.bottom)!])
        setPortraitConstraintAsInactive()
    }

    private func addLandscapeConstraintBottombar() {
        bottomBar.set(.trailing(view),
                      .sameTopBottom(view))
        landscapeConstraints.append(contentsOf: [bottomBar.get(.trailing)!,
                                                 bottomBar.get(.top)!,
                                                 bottomBar.get(.bottom)!])
        setLandscapeConstraintAsInactive()
    }
}

private extension MeetingViewController {
    private func setInitialsConfiguration() {
        // self.topBar.setInitialConfiguration()
    }

    private func createSubView() {
        view.addSubview(baseContentView)
        baseContentView.addSubview(pluginPinnedScreenShareBaseView)
        baseContentView.addSubview(gridBaseView)
        pluginPinnedScreenShareBaseView.accessibilityIdentifier = "Grid_Plugin_View"

        gridView = GridView(showingCurrently: 9, getChildView: {
            RtkParticipantTileContainerView()
        })

        gridBaseView.addSubview(gridView)
        pluginPinnedScreenShareBaseView.addSubview(pluginScreenShareView)
        pluginPinnedScreenShareBaseView.addSubview(pinnedView)

        pluginScreenShareView.addSubview(fullScreenButton)

        fullScreenButton.set(.trailing(pluginScreenShareView, rtkSharedTokenSpace.space1),
                             .bottom(pluginScreenShareView, rtkSharedTokenSpace.space1))

        fullScreenButton.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        fullScreenButton.isHidden = !UIScreen.isLandscape()
        fullScreenButton.isSelected = false
        addPortraitConstraintForSubviews()
        addLandscapeConstraintForSubviews()
        showPinnedPluginViewAsPerOrientation(show: false)
    }

    @objc func buttonClick(button: RtkButton) {
        if UIScreen.isLandscape() {
            if button.isSelected == false {
                pluginScreenShareView.removeFromSuperview()
                addFullScreenView(contentView: pluginScreenShareView)
            } else {
                closefullscreen()
            }
            button.isSelected = !button.isSelected
        }
    }

    private func closefullscreen() {
        if fullScreenView?.isVisible == true {
            pluginPinnedScreenShareBaseView.addSubview(pluginScreenShareView)
            pluginScreenShareView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
            removeFullScreenView()
        }
    }

    private func showPinnedPluginViewAsPerOrientation(show: Bool) {
        layoutPortraitConstraintPluginBaseVariableHeight.isActive = false
        layoutConstraintPluginBaseZeroHeight.isActive = false
        layoutLandscapeConstraintPluginBaseVariableWidth.isActive = false
        layoutConstraintPluginBaseZeroWidth.isActive = false

        if UIScreen.isLandscape() {
            layoutLandscapeConstraintPluginBaseVariableWidth.isActive = show
            layoutConstraintPluginBaseZeroWidth.isActive = !show
        } else {
            layoutPortraitConstraintPluginBaseVariableHeight.isActive = show
            layoutConstraintPluginBaseZeroHeight.isActive = !show
        }
    }

    private func addPortraitConstraintForSubviews() {
        baseContentView.set(.sameLeadingTrailing(view),
                            .below(topBar),
                            .above(bottomBar))
        portraitConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                baseContentView.get(.trailing)!,
                                                baseContentView.get(.top)!,
                                                baseContentView.get(.bottom)!])

        pluginPinnedScreenShareBaseView.set(.sameLeadingTrailing(baseContentView),
                                            .top(baseContentView))
        portraitConstraints.append(contentsOf: [pluginPinnedScreenShareBaseView.get(.leading)!,
                                                pluginPinnedScreenShareBaseView.get(.trailing)!,
                                                pluginPinnedScreenShareBaseView.get(.top)!])

        layoutPortraitConstraintPluginBaseVariableHeight = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.7, constant: 0)
        layoutPortraitConstraintPluginBaseVariableHeight.isActive = false

        layoutConstraintPluginBaseZeroHeight = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.0, constant: 0)

        layoutConstraintPluginBaseZeroHeight.isActive = false

        gridBaseView.set(.sameLeadingTrailing(baseContentView),
                         .below(pluginPinnedScreenShareBaseView),
                         .bottom(baseContentView))

        portraitConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                gridBaseView.get(.trailing)!,
                                                gridBaseView.get(.top)!,
                                                gridBaseView.get(.bottom)!])

        gridView.set(.fillSuperView(gridBaseView))
        portraitConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                gridView.get(.trailing)!,
                                                gridView.get(.top)!,
                                                gridView.get(.bottom)!])
        pluginScreenShareView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        portraitConstraints.append(contentsOf: [pluginScreenShareView.get(.leading)!,
                                                pluginScreenShareView.get(.trailing)!,
                                                pluginScreenShareView.get(.top)!,
                                                pluginScreenShareView.get(.bottom)!])

        pinnedView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        portraitConstraints.append(contentsOf: [pinnedView.get(.leading)!,
                                                pinnedView.get(.trailing)!,
                                                pinnedView.get(.top)!,
                                                pinnedView.get(.bottom)!])
        setPortraitConstraintAsInactive()
    }

    private func addLandscapeConstraintForSubviews() {
        baseContentView.set(.leading(view),
                            .below(topBar),
                            .bottom(view),
                            .before(bottomBar))

        landscapeConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                 baseContentView.get(.trailing)!,
                                                 baseContentView.get(.top)!,
                                                 baseContentView.get(.bottom)!])

        pluginPinnedScreenShareBaseView.set(.leading(baseContentView),
                                            .sameTopBottom(baseContentView))
        landscapeConstraints.append(contentsOf: [pluginPinnedScreenShareBaseView.get(.leading)!,
                                                 pluginPinnedScreenShareBaseView.get(.bottom)!,
                                                 pluginPinnedScreenShareBaseView.get(.top)!])

        layoutLandscapeConstraintPluginBaseVariableWidth = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.75, constant: 0)
        layoutLandscapeConstraintPluginBaseVariableWidth.isActive = false

        layoutConstraintPluginBaseZeroWidth = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.0, constant: 0)

        layoutConstraintPluginBaseZeroWidth.isActive = false

        gridBaseView.set(.sameTopBottom(baseContentView),
                         .after(pluginPinnedScreenShareBaseView),
                         .trailing(baseContentView))

        landscapeConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                 gridBaseView.get(.trailing)!,
                                                 gridBaseView.get(.top)!,
                                                 gridBaseView.get(.bottom)!])

        gridView.set(.fillSuperView(gridBaseView))
        landscapeConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                 gridView.get(.trailing)!,
                                                 gridView.get(.top)!,
                                                 gridView.get(.bottom)!])
        pluginScreenShareView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        landscapeConstraints.append(contentsOf: [pluginScreenShareView.get(.leading)!,
                                                 pluginScreenShareView.get(.trailing)!,
                                                 pluginScreenShareView.get(.top)!,
                                                 pluginScreenShareView.get(.bottom)!])

        pinnedView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        landscapeConstraints.append(contentsOf: [pinnedView.get(.leading)!,
                                                 pinnedView.get(.trailing)!,
                                                 pinnedView.get(.top)!,
                                                 pinnedView.get(.bottom)!])

        setLandscapeConstraintAsInactive()
    }
}

// TopBar related Methods
extension MeetingViewController {
    private func createTopbar() {
        let topbar = RtkMeetingHeaderView(meeting: meeting)
        view.addSubview(topbar)
        topbar.accessibilityIdentifier = "Meeting_ControlTopBar"
        topBar = topbar
        addPortraitConstraintTopbar()
        addLandscapeConstraintTopbar()
    }

    private func addPortraitConstraintTopbar() {
        topBar.set(.sameLeadingTrailing(view), .top(view))
        portraitConstraints.append(contentsOf: [topBar.get(.leading)!,
                                                topBar.get(.trailing)!,
                                                topBar.get(.top)!])
        setPortraitConstraintAsInactive()
    }

    private func addLandscapeConstraintTopbar() {
        topBar.set(.sameLeadingTrailing(view), .top(view))

        topBar.set(.height(0))
        landscapeConstraints.append(contentsOf: [topBar.get(.leading)!,
                                                 topBar.get(.trailing)!,
                                                 topBar.get(.top)!,
                                                 topBar.get(.height)!])
        setLandscapeConstraintAsInactive()
    }
}

extension MeetingViewController: MeetingViewModelDelegate {
    func newPollAdded(createdBy: String) {
        if Shared.data.notification.newPollArrived.showToast {
            view.showToast(toastMessage: "New poll created by \(createdBy)", duration: 2.0, uiBlocker: false)
        }
    }

    func participantJoined(participant: RtkMeetingParticipant) {
        topBar.refreshNextPreviousButtonState()
        if Shared.data.notification.participantJoined.showToast {
            view.showToast(toastMessage: "\(participant.name) just joined", duration: 2.0, uiBlocker: false)
        }
    }

    func participantLeft(participant: RtkMeetingParticipant) {
        topBar.refreshNextPreviousButtonState()
        if Shared.data.notification.participantLeft.showToast {
            view.showToast(toastMessage: "\(participant.name) left", duration: 2.0, uiBlocker: false)
        }
    }

    func activeSpeakerChanged(participant: RtkMeetingParticipant) {
        // For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        // showAndHideActiveSpeaker()
        if let participant = participant as? RtkRemoteParticipant {
            if participant.userId != meeting.localUser.userId {
                pipController?.setSecondaryUser(otherParticipant: participant)
            }
        }
    }

    func pinnedChanged(participant: RtkMeetingParticipant) {
        if !viewModel.pinOrPluginScreenShareModeIsActive() {
            // move to page 0 forcefully as we need to show pin view
            // large pin view functionality only exists on page 0
            meeting.participants.setPage(pageNumber: 0)
        } else {
            if viewModel.pluginScreenShareModeIsActive() == false {
                pinnedView.setParticipant(meeting: meeting, participant: participant)
            }
        }
    }

    func activeSpeakerRemoved() {
        // For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        // showAndHideActiveSpeaker()
    }

    private func showAndHideActiveSpeaker() {
        if let pinned = meeting.participants.pinned {
            pluginScreenShareView.showPinnedView(participant: pinned)
        } else {
            pluginScreenShareView.hideActiveSpeaker()
        }
    }

    private func getScreenShareTabButton(participants: [ParticipantsShareControl]) -> [RtkPluginScreenShareTabButton] {
        var arrButtons = [RtkPluginScreenShareTabButton]()
        for participant in participants {
            var image: RtkImage?
            if let _ = participant as? ScreenShareModel {
                // For
                image = RtkImage(image: ImageProvider.image(named: "icon_screen_share"))
            } else {
                if let strUrl = participant.image, let imageUrl = URL(string: strUrl) {
                    image = RtkImage(url: imageUrl)
                }
            }

            let button = RtkPluginScreenShareTabButton(image: image, title: participant.name, id: participant.id)
            // TODO: Below hardcoding is not needed, We also need to scale down the image as well.
            button.btnImageView?.set(.height(20),
                                     .width(20))
            arrButtons.append(button)
        }
        return arrButtons
    }

    private func handleClicksOnPluginsTab(model: PluginButtonModel, at index: Int) {
        if let pluginView = model.plugin.getPluginView() {
            pluginScreenShareView.show(pluginView: pluginView)
        }
        viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }

    private func handleClicksOnScreenShareTab(model: ScreenShareModel, index: Int) {
        pluginScreenShareView.showVideoView(participant: model.participant)
        pluginScreenShareView.pluginVideoView.viewModel.refreshNameTag()
        viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }

    public func selectPluginOrScreenShare(id: String) {
        var index: Int = -1
        for button in pluginScreenShareView.activeListView.buttons {
            index = index + 1
            if button.id == id {
                pluginScreenShareView.selectForAutoSync(button: button)
                break
            }
        }
    }

    func refreshPluginsButtonTab(pluginsButtonsModels: [ParticipantsShareControl], arrButtons: [RtkPluginScreenShareTabButton]) {
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            pluginScreenShareView.setButtons(buttons: arrButtons, selectedIndex: selectedIndex) { [weak self] button, isUserClick in
                guard let self else { return }
                if let plugin = pluginsButtonsModels[button.index] as? PluginButtonModel {
                    if pluginScreenShareView.syncButton?.isSelected == false, isUserClick {
                        // This is send only when Syncbutton is on and Visible
                        meeting.meta.syncTab(id: plugin.id, tabType: .plugin)
                    }
                    handleClicksOnPluginsTab(model: plugin, at: button.index)

                } else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
                    if pluginScreenShareView.syncButton?.isSelected == false, isUserClick {
                        // This is send only when Syncbutton is on and Visible
                        meeting.meta.syncTab(id: screenShare.id, tabType: .screenshare)
                    }
                    handleClicksOnScreenShareTab(model: screenShare, index: button.index)
                }
                for (index, element) in arrButtons.enumerated() {
                    element.isSelected = index == button.index ? true : false
                }
            }

            pluginScreenShareView.observeSyncButtonClick { syncButton in
                if syncButton.isSelected == false {
                    if let selectedIndex = self.viewModel.screenShareViewModel.selectedIndex {
                        let model = self.viewModel.screenShareViewModel.arrScreenShareParticipants[Int(selectedIndex.0)]
                        if let model = model as? ScreenSharePluginsProtocol {
                            self.meeting.meta.syncTab(id: model.id, tabType: .screenshare)
                        } else if let model = model as? PluginsButtonModelProtocol {
                            self.meeting.meta.syncTab(id: model.id, tabType: .plugin)
                        }
                    }
                }
            }
        }
    }

    private func showHidePluginPinnedAndScreenShareView() {
        if viewModel.pinOrPluginScreenShareModeIsActive() {
            showPinnedPluginView(show: true, animation: true)
            if viewModel.pluginScreenShareModeIsActive() {
                showPluginView(show: true)
            } else if viewModel.pinModeIsActive {
                showPinnedView(show: true)
            }
        } else {
            showPinnedPluginView(show: false, animation: true)
        }
    }

    func refreshPluginsScreenShareView() {
        showHidePluginPinnedAndScreenShareView()
        if viewModel.pluginScreenShareModeIsActive() {
            let participants = viewModel.screenShareViewModel.arrScreenShareParticipants
            let arrButtons = getScreenShareTabButton(participants: participants)
            refreshPluginsButtonTab(pluginsButtonsModels: participants, arrButtons: arrButtons)
            if arrButtons.count >= 1 {
                var selectedIndex: Int?
                if let index = viewModel.screenShareViewModel.selectedIndex?.0 {
                    selectedIndex = Int(index)
                }
                if let index = selectedIndex {
                    if let pluginModel = participants[index] as? PluginButtonModel, let pluginModelView = pluginModel.plugin.getPluginView() {
                        pluginScreenShareView.show(pluginView: pluginModelView)
                    } else if let screenShare = participants[index] as? ScreenShareModel {
                        pluginScreenShareView.showVideoView(participant: screenShare.participant)
                    }
                    loadGrid(fullScreen: false, animation: false, completion: {})
                }
            }
        } else {
            closefullscreen()
            if UIScreen.isLandscape() == false {
                fullScreenButton.isHidden = true
            }

            if viewModel.pinModeIsActive {
                pluginScreenShareView.setButtons(buttons: [RtkPluginScreenShareTabButton](), selectedIndex: nil) { _, _ in }
                let pinnedParticipant: RtkMeetingParticipant = meeting.participants.pinned == nil ? meeting.localUser : meeting.participants.pinned! as RtkMeetingParticipant
                pinnedView.setParticipant(meeting: meeting, participant: pinnedParticipant)
                loadGrid(fullScreen: false, animation: false, completion: {})
            } else {
                loadGrid(fullScreen: true, animation: false, completion: {})
            }
        }

        meetingGridPageBecomeVisible()
    }

    private func showPluginView(show: Bool) {
        pluginScreenShareView.isHidden = !show
        pinnedView.isHidden = true
    }

    private func showPinnedView(show: Bool) {
        pinnedView.isHidden = !show
        pluginScreenShareView.isHidden = true
    }

    private func showPinnedPluginView(show: Bool, animation: Bool) {
        showPinnedPluginViewAsPerOrientation(show: show)
        pluginPinnedScreenShareBaseView.isHidden = !show
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    private func loadGrid(fullScreen: Bool, animation: Bool, completion: @escaping () -> Void) {
        let arrModels = viewModel.arrGridParticipants
        if fullScreen == false {
            if UIScreen.isLandscape() {
                gridView.settingFramesForPluginsActiveInLandscapeMode(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            } else {
                gridView.settingFramesForPluginsActiveInPortraitMode(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            }

        } else {
            if UIScreen.isLandscape() {
                gridView.settingFramesForLandScape(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            } else {
                gridView.settingFrames(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            }
        }
    }

    func refreshMeetingGridTile(participant: RtkMeetingParticipant) {
        let arrModels = viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerContainerView = gridView.childView(index: index) {
                    let isSelf = arrModels[index].participant.id == meeting.localUser.id
                    if isSelf {
                        if let selfParticipant = arrModels[index].participant as? RtkSelfParticipant {
                            peerContainerView.setParticipant(meeting: meeting, participant: selfParticipant)
                        }
                    } else {
                        if let remoteParticipant = arrModels[index].participant as? RtkRemoteParticipant {
                            peerContainerView.setParticipant(meeting: meeting, participant: remoteParticipant)
                        }
                    }
                }
            }
        }
    }

    private func meetingGridPageBecomeVisible() {
        if let participant = meeting.participants.pinned {
            refreshMeetingGridTile(participant: participant)
        }
        topBar.refreshNextPreviousButtonState()
    }
}

extension MeetingViewController: RtkNotificationDelegate {
    public func didReceiveNotification(type: RtkNotificationType) {
        switch type {
        case let .Chat(message):
            if Shared.data.notification.newChatArrived.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: type)
            }
            if Shared.data.notification.newChatArrived.showToast, message.isEmpty == false {
                view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false, showInBottom: true, bottomSpace: bottomBar.bounds.height)
            }
            NotificationCenter.default.post(name: Notification.Name("Notify_NewChatArrived"), object: nil, userInfo: nil)
            moreButtonBottomBar?.notificationBadge.isHidden = false

            let totalMessage = meeting.chat.messages.count
            moreButtonBottomBar?.notificationBadge.setBadgeCount(Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: totalMessage, totalsPolls: meeting.polls.items.count))

        case .Poll:
            NotificationCenter.default.post(name: Notification.Name("Notify_NewPollArrived"), object: nil, userInfo: nil)
            if Shared.data.notification.newPollArrived.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: .Poll)
            }
            moreButtonBottomBar?.notificationBadge.isHidden = false
            moreButtonBottomBar?.notificationBadge.setBadgeCount(Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: meeting.chat.messages.count, totalsPolls: meeting.polls.items.count))

        case .Joined:
            if Shared.data.notification.participantJoined.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: .Joined)
            }

        case .Leave:
            if Shared.data.notification.participantLeft.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: .Leave)
            }
        }
    }

    @objc
    public func clearChatNotification() {
        moreButtonBottomBar?.notificationBadge.isHidden = true
    }
}

extension MeetingViewController: RtkLivestreamEventListener {
    public func onLivestreamError(message _: String) {}

    public func onLivestreamStateChanged(oldState _: RealtimeKit.LivestreamState, newState _: RealtimeKit.LivestreamState) {}

    public func onLivestreamUpdate(data _: RtkLivestreamData) {}

    public func onStageCountUpdated(count _: Int32) {
        if meeting.stage.stageStatus == StageStatus.offStage {
//            let controller = LivestreamViewController(rtkClient: meeting, completion: self.onFinishedMeeting)
//            controller.view.backgroundColor = self.view.backgroundColor
//            controller.modalPresentationStyle = .fullScreen
//            self.present(controller, animated: true)
//            notificationDelegate?.didReceiveNotification(type: .Joined)
        }
    }

    public func onViewerCountUpdated(count _: Int32) {}
}

extension MeetingViewController: RtkChatEventListener {
    public func onMessageRateLimitReset() {}

    public func onChatUpdates(messages _: [ChatMessage]) {}

    public func onNewChatMessage(message: ChatMessage) {
        if message.userId != meeting.localUser.userId {
            var chat = ""
            if let textMessage = message as? TextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            } else {
                if message.type == ChatMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == ChatMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message: chat))
        }

        if let targetUserIds = message.targetUserIds {
            if !targetUserIds.isEmpty {
                let localUserId = meeting.localUser.userId
                targetUserIds
                    .filter { $0 != localUserId }
                    .forEach {
                        Shared.data.privateChatReadLookup[$0] = true
                    }
            }
        }
    }
}

// Notification Related Methods
extension MeetingViewController {
    func setupNotifications() {
        meeting.addChatEventListener(chatEventListener: self)
        NotificationCenter.default.addObserver(self, selector: #selector(clearChatNotification), name: Notification.Name("NotificationAllChatsRead"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEndMeetingForAllButtonPressed), name: RtkLeaveDialog.onEndMeetingForAllButtonPress, object: nil)
    }

    // MARK: Notification Setup Functionality

    @objc private func onEndMeetingForAllButtonPressed(notification _: Notification) {
        viewModel.selfEventListener.observeSelfRemoved(update: nil)
    }
}

extension MeetingViewController {
    func addFullScreenView(contentView: UIView) {
        if fullScreenView == nil {
            fullScreenView = FullScreenView()
            view.addSubview(fullScreenView)
            fullScreenView.set(.fillSuperView(view))
        }
        fullScreenView.backgroundColor = view.backgroundColor
        fullScreenView.isUserInteractionEnabled = true
        fullScreenView.set(contentView: contentView)
    }

    func removeFullScreenView() {
        fullScreenView.backgroundColor = .clear
        fullScreenView.isUserInteractionEnabled = false
        fullScreenView.removeContentView()
    }
}

class FullScreenView: UIView {
    let containerView = UIView()
    var isVisible: Bool = false
    init() {
        super.init(frame: CGRect.zero)
        addSubview(containerView)
        containerView.set(.fillSuperView(self))
        setEdgeConstants()
    }

    func set(contentView: UIView) {
        isVisible = true
        containerView.addSubview(contentView)
        contentView.set(.fillSuperView(containerView))
    }

    func removeContentView() {
        isVisible = true
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setEdgeConstants()
    }

    private func setEdgeConstants() {
        containerView.get(.leading)?.constant = safeAreaInsets.left
        containerView.get(.trailing)?.constant = -safeAreaInsets.right
        containerView.get(.top)?.constant = safeAreaInsets.top
        containerView.get(.bottom)?.constant = -safeAreaInsets.bottom
    }
}
