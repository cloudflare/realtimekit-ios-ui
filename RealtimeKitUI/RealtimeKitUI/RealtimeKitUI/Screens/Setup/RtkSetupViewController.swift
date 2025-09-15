//
//  RtkSetupViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/11/22.
//

import AVFoundation
import RealtimeKit
import UIKit

public class MicToggleButton: RtkButton {
    lazy var rtkSelfListener: RtkEventSelfListener = .init(rtkClient: self.meeting)

    let completion: ((MicToggleButton) -> Void)?

    private let meeting: RealtimeKitClient
    private weak var alertController: UIViewController!

    init(meeting: RealtimeKitClient, alertController: UIViewController, onClick: ((MicToggleButton) -> Void)? = nil, appearance _: RtkButtonAppearance = AppTheme.shared.buttonAppearance) {
        self.meeting = meeting
        self.alertController = alertController
        completion = onClick
        super.init(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled"))), rtkButtonState: .active)
        normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        selectedStateTintColor = DesignLibrary.shared.color.status.danger
        accessibilityIdentifier = "Mic_Toggle_Button"

        setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        addTarget(self, action: #selector(clickMic(button:)), for: .touchUpInside)
        setState()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setState() {
        let mediaPermission = meeting.localUser.permissions.media
        isEnabled = mediaPermission.canPublishAudio
        if getPermission() == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.isSelected = true
            }
        }
    }

    private func getPermission() -> Bool {
        let state = AVCaptureDevice.authorizationStatus(for: .audio)
        if state == .denied {
            return false
        }
        return true
    }

    @objc func clickMic(button: RtkButton) {
        if rtkSelfListener.isMicrophonePermissionGranted() {
            showActivityIndicator()
            rtkSelfListener.toggleLocalAudio(completion: { [weak self] isEnabled in
                guard let self else { return }
                button.hideActivityIndicator()
                button.isSelected = !isEnabled
                completion?(self)
            })
        }
    }

    public func clean() {
        rtkSelfListener.clean()
    }

    deinit {
        clean()
    }
}

public class VideoToggleButton: RtkButton {
    lazy var rtkSelfListener: RtkEventSelfListener = .init(rtkClient: self.meeting)

    let completion: ((VideoToggleButton) -> Void)?

    private let meeting: RealtimeKitClient
    private weak var alertController: UIViewController!

    init(meeting: RealtimeKitClient, alertController: UIViewController, onClick: ((VideoToggleButton) -> Void)? = nil, appearance _: RtkButtonAppearance = AppTheme.shared.buttonAppearance) {
        self.meeting = meeting
        self.alertController = alertController
        completion = onClick
        super.init(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_video_enabled"))), rtkButtonState: .active)
        normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        selectedStateTintColor = DesignLibrary.shared.color.status.danger
        accessibilityIdentifier = "Video_Toggle_Button"
        setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        addTarget(self, action: #selector(clickVideo(button:)), for: .touchUpInside)
        setState()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setState() {
        let mediaPermission = meeting.localUser.permissions.media
        isEnabled = mediaPermission.canPublishVideo
        if getPermission() == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.isSelected = true
            }
        }
    }

    private func getPermission() -> Bool {
        let state = AVCaptureDevice.authorizationStatus(for: .video)
        if state == .denied {
            return false
        }
        return true
    }

    @objc func clickVideo(button: RtkButton) {
        if rtkSelfListener.isCameraPermissionGranted() {
            showActivityIndicator()
            rtkSelfListener.toggleLocalVideo(completion: { [weak self] isEnabled in
                guard let self else { return }
                button.hideActivityIndicator()
                button.isSelected = !isEnabled
                completion?(self)
            })
        }
    }

    public func clean() {
        rtkSelfListener.clean()
    }

    deinit {
        clean()
    }
}

public protocol SetupViewControllerDataSource: UIViewController {
    var delegate: SetupViewControllerDelegate? { get set }
}

public protocol SetupViewControllerDelegate: AnyObject {
    func userJoinedMeetingSuccessfully(sender: UIViewController)
}

public class RtkSetupViewController: RtkBaseViewController, KeyboardObservable, SetupViewControllerDataSource {
    var keyboardObserver: KeyboardObserver?
    let baseView: BaseView = .init()
    private var selfPeerView: RtkParticipantTileView!
    let borderRadius = DesignLibrary.shared.borderRadius
    public weak var delegate: SetupViewControllerDelegate?
    let btnsStackView: BaseStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: DesignLibrary.shared.space.space6)

    lazy var btnMic: MicToggleButton = {
        let button = MicToggleButton(meeting: self.rtkClient, alertController: self) { [weak self] _ in
            guard let self else { return }
            selfPeerView.nameTag.refresh()
        }
        return button
    }()

    lazy var btnVideo: VideoToggleButton = {
        let button = VideoToggleButton(meeting: self.rtkClient, alertController: self) { [weak self] _ in
            guard let self else { return }
            loadSelfVideoView()
        }
        return button
    }()

    let btnSetting: RtkButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_setting"))), rtkButtonState: .active)
        return button
    }()

    let lblJoinAs: RtkLabel = RtkUIUtility.createLabel(text: "Join in as")

    let textFieldBottom: RtkTextField = {
        let textField = RtkTextField()
        textField.setPlaceHolder(text: "Insert your name")
        return textField
    }()

    var btnBottom: RtkJoinButton!

    let lblBottom: RtkLabel = RtkUIUtility.createLabel(text: "24 people Present")

    let spaceToken = DesignLibrary.shared.space

    let backgroundColor = DesignLibrary.shared.color.background.shade1000

    private let completion: () -> Void

    private let meetingInfo: RtkMeetingInfo?
    private let rtkClient: RealtimeKitClient
    private var waitingRoomView: WaitingRoomView?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let peerViewBaseView = UIView()

    public init(meetingInfo: RtkMeetingInfo, meeting: RealtimeKitClient, completion: @escaping () -> Void) {
        rtkClient = meeting
        self.meetingInfo = meetingInfo
        self.completion = completion
        super.init(meeting: meeting)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        view.backgroundColor = backgroundColor
    }

    private var viewModel: SetupViewModel!
    private var btnStackView: UIStackView!
    private var bottomStackView: UIStackView!

    private func rtkClientInit() {
        if let info = meetingInfo {
            viewModel = SetupViewModel(rtkClient: rtkClient, delegate: self, meetingInfo: info)
        }
    }

    deinit {
        print("RtkUIKit | SetupViewController deinit is calling")
    }
}

// MARK: Public methods

extension RtkSetupViewController {
    func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }

    func setTag(name _: String) {
        selfPeerView.viewModel.refreshNameTag()
        selfPeerView.viewModel.refreshInitialName()
    }
}

extension RtkSetupViewController: MeetingDelegate {
    func onMeetingInitCompleted() {
        setupUIAfterMeetingInit()
        let mediaPermission = rtkClient.localUser.permissions.media
        if mediaPermission.canPublishAudio == false {
            btnMic.isHidden = true
        }

        if mediaPermission.canPublishVideo == false {
            btnVideo.isHidden = true
        }

        loadSelfVideoView()
    }

    func onMeetingInitFailed(message: String?) {
        showInitFailedAlert(title: message ?? "", retry: { [weak self] in
            guard let self else { return }
            rtkClientInit()
        })
    }

    private func showInitFailedAlert(title: String, retry: @escaping () -> Void) {
        let alert = UIAlertController(title: "Error", message: title, preferredStyle: .alert)
        // Add "OK" Button to alert, pressing it will bring you to the settings app
        alert.addAction(UIAlertAction(title: "retry", style: .default, handler: { _ in
            retry()
        }))
        alert.addAction(UIAlertAction(title: "exit", style: .default, handler: { _ in
            self.completion()
        }))
        // Show the alert with animation
        present(alert, animated: true)
    }
}

extension RtkSetupViewController {
    func setupView() {
        createSubviews()
        rtkClientInit()
    }

    private func setCallBacksForViewModel() {
        viewModel.rtkSelfListener.waitListStatusUpdate = { [weak self] status in
            guard let self else { return }
            showWaitingRoom(status: status)
        }
    }

    private func setupKeyboard() {
        startKeyboardObserving { [weak self] keyboardFrame in
            guard let self else { return }
            let frame = baseView.convert(bottomStackView.frame, to: view.coordinateSpace)
            view.frame.origin.y = keyboardFrame.origin.y - frame.maxY
        } onHide: { [weak self] in
            guard let self else { return }
            view.frame.origin.y = 0 // Move view to original position
        }
    }

    private func createSubviews() {
        view.addSubview(baseView)
        setUpActivityIndicator(baseView: baseView)
        addConstraintForBaseView()
        applyConstraintAsPerOrientation()
    }

    private func addConstraintForBaseView() {
        addPortraitConstraintsForBaseView()
        setPortraitConstraintAsInactive()
        addLandscapeConstraintForBaseView()
        setLandscapeConstraintAsInactive()
    }

    private func addPortraitConstraintsForBaseView() {
        baseView.set(.sameLeadingTrailing(view, spaceToken.space8),
                     .centerY(view),
                     .top(view, spaceToken.space8, .greaterThanOrEqual))
        portraitConstraints.append(contentsOf: [baseView.get(.leading)!,
                                                baseView.get(.trailing)!,
                                                baseView.get(.top)!,
                                                baseView.get(.centerY)!])
    }

    private func addLandscapeConstraintForBaseView() {
        baseView.set(.leading(view, spaceToken.space8, .greaterThanOrEqual),
                     .centerX(view),
                     .bottom(view, spaceToken.space8),
                     .top(view, spaceToken.space8))
        landscapeConstraints.append(contentsOf: [baseView.get(.top)!,
                                                 baseView.get(.bottom)!,
                                                 baseView.get(.leading)!,
                                                 baseView.get(.centerX)!])
    }

    private func setUpActivityIndicator(baseView: UIView) {
        baseView.addSubview(activityIndicator)
        activityIndicator.set(.centerView(baseView))
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
    }

    private func setupUIAfterMeetingInit() {
        createMeetingSetupUI()
        setupKeyboard()
        setupButtonActions()
        if viewModel.rtkClient.localUser.permissions.miscellaneous.canEditDisplayName {
            textFieldBottom.addTarget(self, action: #selector(textFieldEditingDidChange), for: .editingChanged)
            textFieldBottom.delegate = self
        }
        textFieldBottom.text = viewModel.rtkClient.localUser.name
        setTag(name: "")

        setCallBacksForViewModel()
    }

    private func createMeetingSetupUI() {
        activityIndicator.stopAnimating()
        baseView.addSubview(peerViewBaseView)

        selfPeerView = RtkParticipantTileView(viewModel: VideoPeerViewModel(meeting: rtkClient, participant: rtkClient.localUser, showSelfPreviewVideo: true))

        peerViewBaseView.addSubview(selfPeerView)

        selfPeerView.clipsToBounds = true

        let btnStackView = createBtnView()
        peerViewBaseView.addSubview(btnStackView)
        self.btnStackView = btnStackView

        let bottomStackView = createBottomButtonStackView()
        baseView.addSubview(bottomStackView)
        self.bottomStackView = bottomStackView

        lblBottom.isHidden = true
        addConstraintForCreatingMeetingSetUpUI()
        applyConstraintAsPerOrientation()
    }

    private func addConstraintForCreatingMeetingSetUpUI() {
        addPortraintConstraintForCreateMeetingSetupUI()
        setPortraitConstraintAsInactive()
        addLandscapeConstraintForCreateMeetingSetupUI()
        setLandscapeConstraintAsInactive()
    }

    private func addPortraintConstraintForCreateMeetingSetupUI() {
        peerViewBaseView.set(.top(baseView),
                             .sameLeadingTrailing(baseView))

        portraitConstraints.append(contentsOf: [peerViewBaseView.get(.top)!,
                                                peerViewBaseView.get(.leading)!,
                                                peerViewBaseView.get(.trailing)!])

        selfPeerView.set(.top(peerViewBaseView),
                         .leading(peerViewBaseView, spaceToken.space6, .greaterThanOrEqual),
                         .centerX(peerViewBaseView))

        portraitConstraints.append(contentsOf: [selfPeerView.get(.top)!,
                                                selfPeerView.get(.leading)!,
                                                selfPeerView.get(.centerX)!])

        let portraitPeerViewWidth = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewWidth)
        let portraitPeerViewHeight = ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.85).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewHeight)

        btnStackView.set(.below(selfPeerView, spaceToken.space4),
                         .leading(peerViewBaseView, 0.0, .greaterThanOrEqual),
                         .centerX(peerViewBaseView),
                         .bottom(peerViewBaseView))
        portraitConstraints.append(contentsOf: [btnStackView.get(.top)!,
                                                btnStackView.get(.centerX)!,
                                                btnStackView.get(.leading)!,
                                                btnStackView.get(.bottom)!])

        bottomStackView.set(.below(peerViewBaseView, spaceToken.space6),
                            .sameLeadingTrailing(baseView),
                            .bottom(baseView))
        portraitConstraints.append(contentsOf: [bottomStackView.get(.top)!,
                                                bottomStackView.get(.bottom)!,
                                                bottomStackView.get(.leading)!,
                                                bottomStackView.get(.trailing)!])
    }

    private func addLandscapeConstraintForCreateMeetingSetupUI() {
        let equalWidthConstraintPeerView = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.8).getConstraint(for: selfPeerView)
        landscapeConstraints.append(equalWidthConstraintPeerView)

        let equalHeightConstraintPeerView = ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.6).getConstraint(for: selfPeerView)
        landscapeConstraints.append(equalHeightConstraintPeerView)

        peerViewBaseView.set(.top(baseView, 0, .greaterThanOrEqual),
                             .leading(baseView),
                             .centerY(baseView))

        landscapeConstraints.append(contentsOf: [peerViewBaseView.get(.top)!,
                                                 peerViewBaseView.get(.leading)!,
                                                 peerViewBaseView.get(.centerY)!])

        selfPeerView.set(.top(peerViewBaseView),
                         .sameLeadingTrailing(peerViewBaseView))

        landscapeConstraints.append(contentsOf: [selfPeerView.get(.top)!,
                                                 selfPeerView.get(.leading)!,
                                                 selfPeerView.get(.trailing)!])

        btnStackView.set(.below(selfPeerView, spaceToken.space4),
                         .centerX(selfPeerView),
                         .bottom(peerViewBaseView, spaceToken.space8))

        landscapeConstraints.append(contentsOf: [btnStackView.get(.top)!,
                                                 btnStackView.get(.centerX)!,
                                                 btnStackView.get(.bottom)!])

        // Right part
        bottomStackView.set(.after(peerViewBaseView, spaceToken.space6),
                            .centerY(baseView),
                            .trailing(baseView, spaceToken.space6))
        let equalWidthBottomStackView = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: selfPeerView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 1.0).getConstraint(for: bottomStackView)
        equalWidthBottomStackView.priority = .defaultHigh
        landscapeConstraints.append(equalWidthBottomStackView)
        landscapeConstraints.append(contentsOf: [bottomStackView.get(.leading)!,
                                                 bottomStackView.get(.centerY)!,
                                                 bottomStackView.get(.trailing)!])
    }

    private func setupButtonActions() {
        btnSetting.addTarget(self, action: #selector(clickSetting(button:)), for: .touchUpInside)
    }

    @objc func textFieldEditingDidChange(_: Any) {
        if !((textFieldBottom.text?.trimmingCharacters(in: .whitespaces).isEmpty) ?? false) {
            if let text = textFieldBottom.text {
                viewModel?.rtkClient.localUser.name = text
                setTag(name: text)
            }
        }
    }

    private func createBtnView() -> BaseStackView {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: DesignLibrary.shared.space.space6)

        if let info = meetingInfo {
            btnMic.isSelected = !info.enableAudio
            btnVideo.isSelected = !info.enableVideo
        }
        stackView.addArrangedSubviews(btnMic, btnVideo, btnSetting)
        return stackView
    }

    private func createBottomButtonStackView() -> BaseStackView {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space2)
        stackView.addArrangedSubviews(lblJoinAs, createBottomJoinButton(), lblBottom)
        return stackView
    }

    private func createBottomJoinButton() -> BaseView {
        let view = BaseView()
        view.addSubview(textFieldBottom)
        textFieldBottom.set(.sameLeadingTrailing(view), .top(view))
        btnBottom = addJoinButton(on: view)
        btnBottom.accessibilityIdentifier = "Join Button"
        return view
    }

    private func addJoinButton(on view: UIView) -> RtkJoinButton {
        let joinButton = RtkJoinButton(meeting: rtkClient) { [weak self] _, success in
            guard let self else { return }
            if success {
                delegate?.userJoinedMeetingSuccessfully(sender: self)
            }
        }

        view.addSubview(joinButton)
        joinButton.set(.sameLeadingTrailing(view), .bottom(view), .below(textFieldBottom, spaceToken.space6))
        return joinButton
    }

    private func showWaitingRoom(status: WaitListStatus) {
        waitingRoomView?.removeFromSuperview()
        if status != .none {
            let waitingView = WaitingRoomView(automaticClose: false, onCompletion: { [weak self] in
                guard let self else { return }
                completion()
                meeting.leaveRoom(onSuccess: {}, onFailure: { _ in })
            })
            waitingView.accessibilityIdentifier = "WaitingRoom_View"
            waitingView.backgroundColor = view.backgroundColor
            view.addSubview(waitingView)
            waitingView.set(.fillSuperView(view))
            view.endEditing(true)
            waitingRoomView = waitingView
            waitingView.show(status: ParticipantMeetingStatus.getStatus(status: status))
        }
    }
}

extension RtkSetupViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension RtkSetupViewController {
    @objc func clickSetting(button _: RtkButton) {
        if !rtkClient.localUser.videoEnabled, !rtkClient.localUser.audioEnabled {
            view.showToast(toastMessage: "Microphone/Camera needs to be enabled to access settings", duration: 1)
            return
        }

        if let rtkClient = viewModel?.rtkClient {
            rtkClient.localUser.setDisplayName(name: textFieldBottom.text ?? "")
            let controller = RtkSettingViewController(nameTag: textFieldBottom.text ?? "", meeting: rtkClient)
            controller.view.backgroundColor = view.backgroundColor
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true)
        }
    }
}
