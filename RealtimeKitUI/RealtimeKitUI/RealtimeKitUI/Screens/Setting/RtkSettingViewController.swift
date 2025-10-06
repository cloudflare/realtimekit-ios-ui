//
//  RtkSettingViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 07/12/22.
//

import AVFAudio
import RealtimeKit
import UIKit

public class RtkSettingViewController: RtkBaseViewController, SetTopbar {
    public var shouldShowTopBar: Bool = true
    public var topBar: RtkNavigationBar = .init(title: "Settings")
    private let baseView: BaseView = .init()
    private let selfPeerView: RtkParticipantTileView

    private let spaceToken = DesignLibrary.shared.space
    private let borderRadius = DesignLibrary.shared.borderRadius

    private let nameTagTitle: String

    private var cameraDropDown: RtkDropdown<CameraPickerCellModel>!
    private var speakerDropDown: RtkDropdown<RtkAudioPickerCellModel>!
    private var audioSelectionView: RtkCustomPickerView<RtkPickerModel<RtkAudioPickerCellModel>>?

    private let backgroundColor = DesignLibrary.shared.color.background.shade1000
    private let completion: (() -> Void)?

    public init(nameTag: String, meeting: RealtimeKitClient, completion: (() -> Void)? = nil) {
        nameTagTitle = nameTag
        self.completion = completion
        selfPeerView = RtkParticipantTileView(viewModel: VideoPeerViewModel(meeting: meeting, participant: meeting.localUser, showSelfPreviewVideo: true))
        super.init(meeting: meeting)
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.get(.top)?.constant = view.safeAreaInsets.top
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        addTopBar(dismissAnimation: true) { [weak self] in
            guard let self else { return }
            completion?()
        }
        createSubviews()
        applyConstraintAsPerOrientation()
        setTag(name: nameTagTitle)

        loadSelfVideoView()
        view.backgroundColor = backgroundColor
        meeting.addSelfEventListener(selfEventListener: self)
    }

    deinit {
        print("Debug RtkUIKit | SettingViewController deinit is calling")
    }
}

extension RtkSettingViewController: RtkSelfEventListener {
    public func onAudioDeviceChanged(audioDevice _: AudioDevice) {}

    public func onAudioUpdate(isEnabled _: Bool) {}

    public func onMeetingRoomJoinedWithoutCameraPermission() {}

    public func onMeetingRoomJoinedWithoutMicPermission() {}

    public func onPermissionsUpdated(permission _: SelfPermissions) {}

    public func onPinned() {}

    public func onRemovedFromMeeting() {}

    public func onScreenShareStartFailed(reason _: String) {}

    public func onScreenShareUpdate(isEnabled _: Bool) {}

    public func onUnpinned() {}

    public func onUpdate(participant _: RtkSelfParticipant) {}

    public func onVideoDeviceChanged(videoDevice _: VideoDevice) {}

    public func onVideoUpdate(isEnabled _: Bool) {}

    public func onWaitListStatusUpdate(waitListStatus _: RealtimeKit.WaitListStatus) {}

    private func setTag(name _: String) {
        selfPeerView.viewModel.refreshNameTag()
        selfPeerView.viewModel.refreshInitialName()
    }

    private func createSubviews() {
        view.addSubview(baseView)
        baseView.accessibilityIdentifier = "ContainerView"

        func addPortraitConstraintToBaseView() {
            baseView.set(.leading(view, spaceToken.space2, .greaterThanOrEqual),
                         .centerView(view),
                         .below(topBar, spaceToken.space4, .greaterThanOrEqual))

            portraitConstraints.append(contentsOf: [baseView.get(.top)!,
                                                    baseView.get(.centerX)!,
                                                    baseView.get(.leading)!,
                                                    baseView.get(.centerY)!])
            setPortraitConstraintAsInactive()
        }

        func addLandscapeConstraintToBaseView() {
            baseView.set(.sameLeadingTrailing(view, spaceToken.space8),
                         .below(topBar),
                         .bottom(view))
            landscapeConstraints.append(contentsOf: [baseView.get(.top)!,
                                                     baseView.get(.bottom)!,
                                                     baseView.get(.leading)!,
                                                     baseView.get(.trailing)!])

            setLandscapeConstraintAsInactive()
        }

        addPortraitConstraintToBaseView()
        addLandscapeConstraintToBaseView()

        baseView.addSubview(selfPeerView)

        selfPeerView.clipsToBounds = true
        selfPeerView.accessibilityIdentifier = "SelfPeerView"

        func addPortraitConstraintToPeerView() {
            let equalWidthConstraintPeerView = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: view, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: selfPeerView)
            let equalHeightConstraintPeerView = ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: view, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.5).getConstraint(for: selfPeerView)

            selfPeerView.set(.top(baseView),
                             .sameLeadingTrailing(baseView, spaceToken.space6))

            portraitConstraints.append(contentsOf: [equalWidthConstraintPeerView,
                                                    equalHeightConstraintPeerView,
                                                    selfPeerView.get(.top)!,
                                                    selfPeerView.get(.leading)!,
                                                    selfPeerView.get(.trailing)!])
            setPortraitConstraintAsInactive()
        }

        func addLandscapeConstraintToPeerView() {
            let equalWidthConstraintPeerViewLandscape = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.5).getConstraint(for: selfPeerView)
            landscapeConstraints.append(equalWidthConstraintPeerViewLandscape)
            let equalHeightConstraintPeerViewLandscape = ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: selfPeerView)
            landscapeConstraints.append(equalHeightConstraintPeerViewLandscape)

            selfPeerView.set(.top(baseView, spaceToken.space6, .greaterThanOrEqual),
                             .leading(baseView, spaceToken.space6),
                             .centerY(baseView))

            landscapeConstraints.append(contentsOf: [selfPeerView.get(.top)!,
                                                     selfPeerView.get(.leading)!,
                                                     selfPeerView.get(.centerY)!])
            setLandscapeConstraintAsInactive()
        }
        addPortraitConstraintToPeerView()
        addLandscapeConstraintToPeerView()

        let btnStackView = createDropdownStackView()
        let wrapperView = btnStackView.wrapperView()
        wrapperView.addSubview(btnStackView)
        btnStackView.accessibilityIdentifier = "btnStackView"
        wrapperView.accessibilityIdentifier = "wrapperView_btnStackView"

        baseView.addSubview(wrapperView)

        func addPortraitConstraintToBtnStackView() {
            let equalHeightConstraintBtnStackViewPortrait = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: selfPeerView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: btnStackView)
            portraitConstraints.append(equalHeightConstraintBtnStackViewPortrait)
            wrapperView.set(.below(selfPeerView, spaceToken.space4),
                            .sameLeadingTrailing(baseView),
                            .bottom(baseView))
            portraitConstraints.append(contentsOf: [wrapperView.get(.top)!,
                                                    wrapperView.get(.bottom)!,
                                                    wrapperView.get(.leading)!,
                                                    wrapperView.get(.trailing)!])

            btnStackView.set(.top(wrapperView, 0, .greaterThanOrEqual),
                             .leading(wrapperView, 0, .greaterThanOrEqual),
                             .centerView(wrapperView))

            portraitConstraints.append(contentsOf: [
                btnStackView.get(.top)!,
                btnStackView.get(.centerX)!,
                btnStackView.get(.leading)!,
                btnStackView.get(.centerY)!,
            ])
            setPortraitConstraintAsInactive()
        }

        func addLandscapeConstraintToBtnStackView() {
            let equalHeightConstraintBtnStackViewPortrait = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: selfPeerView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: btnStackView)
            landscapeConstraints.append(equalHeightConstraintBtnStackViewPortrait)

            btnStackView.set(.centerX(wrapperView),
                             .centerY(wrapperView),
                             .top(wrapperView, 0, .greaterThanOrEqual),
                             .leading(wrapperView, 0, .greaterThanOrEqual))

            landscapeConstraints.append(contentsOf: [btnStackView.get(.top)!,
                                                     btnStackView.get(.centerX)!,
                                                     btnStackView.get(.centerY)!,
                                                     btnStackView.get(.leading)!])

            wrapperView.set(.top(baseView, spaceToken.space4),
                            .bottom(baseView, spaceToken.space4),
                            .after(selfPeerView, spaceToken.space4),
                            .trailing(baseView, spaceToken.space4))

            landscapeConstraints.append(contentsOf: [wrapperView.get(.top)!,
                                                     wrapperView.get(.bottom)!,
                                                     wrapperView.get(.trailing)!,
                                                     wrapperView.get(.leading)!])
            setLandscapeConstraintAsInactive()
        }

        addPortraitConstraintToBtnStackView()
        addLandscapeConstraintToBtnStackView()
    }

    private func createDropdownStackView() -> BaseStackView {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space4)

        if meeting.localUser.videoEnabled {
            cameraDropDown = createCameraDropDown()
            stackView.addArrangedSubviews(cameraDropDown)
        }
        speakerDropDown = createAudioDropDown()
        stackView.addArrangedSubviews(speakerDropDown)
        return stackView
    }

    private func createCameraDropDown() -> RtkDropdown<CameraPickerCellModel> {
        let currentCameraSelectedDevice: VideoDeviceType? = meeting.localUser.getSelectedVideoDevice()?.type

        let cameraDropDown = RtkDropdown(rightImage: RtkImage(image: ImageProvider.image(named: "icon_angle_arrow_down")), heading: "Camera", options: [CameraPickerCellModel(name: "Front camera", deviceType: .front), CameraPickerCellModel(name: "Back camera", deviceType: .rear)], selectedIndex: currentCameraSelectedDevice == .front ? 0 : 1) { [weak self] dropDown in
            guard let self else { return }
            let currentSelectedDevice: VideoDeviceType? = meeting.localUser.getSelectedVideoDevice()?.type

            let picker = RtkCustomPickerView.show(model: RtkPickerModel(title: dropDown.heading, selectedIndex: currentSelectedDevice == .front ? 0 : 1, cells: dropDown.options), on: view)
            picker.onSelectRow = { [weak self] picker, index in
                guard let self else { return }
                let currentSelectedDevice = picker.options[index]
                toggleCamera(rtkClient: meeting, selectDevice: currentSelectedDevice.deviceType)
                dropDown.selectOption(index: currentSelectedDevice.deviceType == .front ? 0 : 1)
            }
            picker.onCancelButtonClick = { [weak self] _ in
                guard let self else { return }
                toggleCamera(rtkClient: meeting, selectDevice: currentSelectedDevice)
                dropDown.selectOption(index: currentSelectedDevice == .front ? 0 : 1)
            }
        }
        return cameraDropDown
    }

    public func onAudioDevicesUpdated(devices: [AudioDevice]) {
        let metaData = getSpeakerDropDownData(audioDevices: devices)
        speakerDropDown.refresh(selectedIndex: UInt(metaData.selectedIndex), options: metaData.devicesModel)
        if speakerDropDown.selectedState {
            audioSelectionView?.refresh(list: metaData.devicesModel, selectedIndex: UInt(metaData.selectedIndex))
        }
    }

    private func getSpeakerDropDownData(audioDevices: [AudioDevice]) -> (devicesModel: [RtkAudioPickerCellModel], selectedIndex: Int) {
        let deviceModels = audioDevices.map { RtkAudioPickerCellModel(name: $0.type.displayName, deviceType: $0.type) }
        let currentAudioSelectedDevice: AudioDeviceType? = meeting.localUser.getSelectedAudioDevice()?.type
        return (deviceModels, deviceModels.firstIndex(where: { $0.deviceType == currentAudioSelectedDevice }) ?? (deviceModels.count - 1))
    }

    private func createAudioDropDown() -> RtkDropdown<RtkAudioPickerCellModel> {
        let audioDevices = meeting.localUser.getAudioDevices()
        let metaData = getSpeakerDropDownData(audioDevices: audioDevices)
        let speakerDropDown = RtkDropdown(rightImage: RtkImage(image: ImageProvider.image(named: "icon_angle_arrow_down")), heading: "Speaker (output)", options: metaData.devicesModel, selectedIndex: UInt(metaData.selectedIndex)) { [weak self] dropDown in
            guard let self else { return }
            let metaData = getSpeakerDropDownData(audioDevices: audioDevices)

            let picker = RtkCustomPickerView.show(model: RtkPickerModel(title: dropDown.heading, selectedIndex: UInt(metaData.selectedIndex), cells: dropDown.options), on: view)
            picker.onSelectRow = { [weak self] picker, index in
                guard let self else { return }
                let currentSelectedDevice = picker.options[index]
                for device in audioDevices {
                    if currentSelectedDevice.deviceType == device.type {
                        meeting.localUser.setAudioDevice(rtkAudioDevice: device)
                        dropDown.selectOption(index: UInt(index))
                    }
                }
            }
            picker.onDoneButtonClick = { [weak dropDown] _ in
                dropDown?.selectedState = false
            }
            picker.onCancelButtonClick = { [weak dropDown] _ in
                dropDown?.selectedState = false
            }
            audioSelectionView = picker
        }
        return speakerDropDown
    }

    private func toggleCamera(rtkClient: RealtimeKitClient, selectDevice: VideoDeviceType?) {
        let videoDevices = rtkClient.localUser.getVideoDevices()
        let currentSelectedDevice: VideoDeviceType? = rtkClient.localUser.getSelectedVideoDevice()?.type

        if currentSelectedDevice == .front, selectDevice == .rear {
            if let device = getVideoDevice(type: .rear) {
                rtkClient.localUser.setVideoDevice(rtkVideoDevice: device)
            }
        } else if currentSelectedDevice == .rear, selectDevice == .front {
            if let device = getVideoDevice(type: .front) {
                rtkClient.localUser.setVideoDevice(rtkVideoDevice: device)
            }
        }

        func getVideoDevice(type: VideoDeviceType) -> VideoDevice? {
            for device in videoDevices {
                if device.type == type {
                    return device
                }
            }
            return nil
        }
    }

    private func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
}
