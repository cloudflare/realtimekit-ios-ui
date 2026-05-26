//
//  WebinarAlert.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 17/04/23.
//

import RealtimeKit
import UIKit

public class RtkWebinarAlertView: UIView, ConfigureWebinerAlertView, @preconcurrency AdaptableUI {
    private let btnMic: RtkButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        return button
    }()

    private let lblBottom: RtkLabel = {
        let lbl = RtkUIUtility.createLabel(text: "Upon joining the stage, your video & audio as shown above will be visible to all participants.", alignment: .left)
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        return lbl
    }()

    private let baseView = UIView()
    private let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePeerView ?? .rounded
    private lazy var rtkSelfListener: RtkEventSelfListener = .init(rtkClient: self.meeting)

    private let lblTop: RtkLabel = {
        let lbl = RtkUIUtility.createLabel(text: "Joining webinar stage", alignment: .left)
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16)
        return lbl
    }()

    private let btnVideo: RtkButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_video_enabled"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        return button
    }()

    private let selfPeerView: RtkParticipantTileView
    private var meeting: RealtimeKitClient
    private var previousOrientationIsLandscape = UIScreen.isLandscape()

    public var portraitConstraints = [NSLayoutConstraint]()
    public var landscapeConstraints = [NSLayoutConstraint]()

    public let confirmAndJoinButton: RtkButton = RtkUIUtility.createButton(text: "Confirm & join stage")

    public let cancelButton: RtkButton = {
        let button = RtkUIUtility.createButton(text: "Cancel")
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        return button
    }()

    public required init(meeting: RealtimeKitClient, participant: RtkMeetingParticipant) {
        self.meeting = meeting
        selfPeerView = RtkParticipantTileView(viewModel: VideoPeerViewModel(meeting: meeting, participant: participant, showSelfPreviewVideo: true))
        super.init(frame: .zero)
        setupSubview()
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show(on view: UIView) {
        layer.zPosition = 1.0
        view.addSubview(self)
        set(.fillSuperView(view))
    }
}

extension RtkWebinarAlertView {
    private func onRotationChange() {
        setUpConstraintAsPerOrientation()
    }

    private func setUpConstraintAsPerOrientation() {
        applyConstraintAsPerOrientation()
    }

    private func setupSubview() {
        createSubview()
        setUpConstraintAsPerOrientation()
        btnMic.isSelected = !meeting.localUser.audioEnabled
        btnVideo.isSelected = !meeting.localUser.videoEnabled
        btnMic.addTarget(self, action: #selector(clickMic(button:)), for: .touchUpInside)
        btnVideo.addTarget(self, action: #selector(clickVideo(button:)), for: .touchUpInside)
    }

    @objc private func onOrientationChange() {
        let currentOrientationIsLandscape = UIScreen.isLandscape()
        if previousOrientationIsLandscape != currentOrientationIsLandscape {
            previousOrientationIsLandscape = currentOrientationIsLandscape
            onRotationChange()
        }
    }

    private func createSubview() {
        baseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .two, radius: borderRadiusType)
        baseView.layer.masksToBounds = true

        addSubview(baseView)
        let alertContentBaseView = UIView()
        baseView.addSubview(alertContentBaseView)
        createSubView(baseView: alertContentBaseView)
        baseView.backgroundColor = rtkSharedTokenColor.background.shade900
        backgroundColor = rtkSharedTokenColor.background.shade1000.withAlphaComponent(0.9)
        baseView.set(.centerX(self),
                     .centerY(self))
        let portraitPeerViewWidth = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: baseView)
        portraitConstraints.append(portraitPeerViewWidth)

        let landscapePeerViewWidth = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: baseView)
        landscapeConstraints.append(landscapePeerViewWidth)
        alertContentBaseView.set(.fillSuperView(baseView, rtkSharedTokenSpace.space4))
    }

    private func createSubView(baseView: UIView) {
        let topView = UIView()
        let bottomView = UIView()
        baseView.addSubViews(topView, bottomView)

        func addTopViewPortraitConstraint() {
            topView.set(.top(baseView), .sameLeadingTrailing(baseView))

            portraitConstraints.append(contentsOf: [topView.get(.top)!,
                                                    topView.get(.leading)!,
                                                    topView.get(.trailing)!])
        }

        func addTopViewLandscapeConstraint() {
            topView.set(.top(baseView, rtkSharedTokenSpace.space6), .leading(baseView),
                        .bottom(baseView, rtkSharedTokenSpace.space6))
            landscapeConstraints.append(contentsOf: [topView.get(.top)!,
                                                     topView.get(.leading)!,
                                                     topView.get(.bottom)!])
        }

        addTopViewPortraitConstraint()
        addTopViewLandscapeConstraint()

        func addBottomViewPortraitConstraint() {
            bottomView.set(.below(topView),
                           .sameLeadingTrailing(baseView),
                           .bottom(baseView))
            portraitConstraints.append(contentsOf: [bottomView.get(.top)!,
                                                    bottomView.get(.leading)!,
                                                    bottomView.get(.trailing)!,
                                                    bottomView.get(.bottom)!])
        }

        func addBottomViewLandscapeConstraint() {
            bottomView.set(.top(baseView),
                           .trailing(baseView),
                           .after(topView),
                           .bottom(baseView))
            landscapeConstraints.append(contentsOf: [bottomView.get(.top)!,
                                                     bottomView.get(.leading)!,
                                                     bottomView.get(.trailing)!,
                                                     bottomView.get(.bottom)!])
        }
        addBottomViewPortraitConstraint()
        addBottomViewLandscapeConstraint()

        createTopView(topView: topView)
        createSubViewForAlertContent(baseView: bottomView)
    }

    private func createTopView(topView: UIView) {
        let peerContentView = UIView()
        topView.addSubViews(lblTop, peerContentView)
        peerContentView.addSubview(selfPeerView)

        lblTop.set(.sameLeadingTrailing(topView),
                   .top(topView))

        selfPeerView.clipsToBounds = true
        peerContentView.set(.below(lblTop, rtkSharedTokenSpace.space6),
                            .bottom(topView),
                            .sameLeadingTrailing(topView))

        selfPeerView.set(.top(peerContentView, 0, .greaterThanOrEqual),
                         .centerY(peerContentView),
                         .centerX(peerContentView),
                         .leading(peerContentView, rtkSharedTokenSpace.space4, .greaterThanOrEqual))

        let portraitPeerViewWidth = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewWidth)
        let portraitPeerViewHeight = ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.95).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewHeight)

        let landscapePeerViewWidth = ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: selfPeerView)
        landscapeConstraints.append(landscapePeerViewWidth)

        let landscapePeerViewHeight = ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: peerContentView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.75).getConstraint(for: selfPeerView)
        landscapeConstraints.append(landscapePeerViewHeight)
    }

    private func createSubViewForAlertContent(baseView: UIView) {
        let btnStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: rtkSharedTokenSpace.space6)
        btnStackView.addArrangedSubviews(btnMic, btnVideo)
        let bottomBtnStackView = RtkUIUtility.createStackView(axis: .vertical, spacing: rtkSharedTokenSpace.space4)
        bottomBtnStackView.addArrangedSubviews(confirmAndJoinButton, cancelButton)
        baseView.addSubViews(btnStackView, lblBottom, bottomBtnStackView)

        btnStackView.set(.top(baseView, rtkSharedTokenSpace.space4),
                         .centerX(baseView))

        lblBottom.set(.sameLeadingTrailing(baseView),
                      .below(btnStackView, rtkSharedTokenSpace.space6))
        bottomBtnStackView.set(.below(lblBottom, rtkSharedTokenSpace.space6),
                               .centerX(baseView),
                               .leading(baseView, rtkSharedTokenSpace.space4, .greaterThanOrEqual),
                               .bottom(baseView))
    }

    @objc func clickMic(button: RtkButton) {
        if rtkSelfListener.isMicrophonePermissionGranted() {
            button.showActivityIndicator()
            rtkSelfListener.toggleLocalAudio(completion: { [weak self] isEnabled in
                guard let self else { return }
                button.hideActivityIndicator()
                selfPeerView.nameTag.refresh()
                button.isSelected = !isEnabled
            })
        }
    }

    @objc func clickVideo(button: RtkButton) {
        if rtkSelfListener.isCameraPermissionGranted() {
            button.showActivityIndicator()
            rtkSelfListener.toggleLocalVideo(completion: { [weak self] isEnabled in
                guard let self else { return }
                button.hideActivityIndicator()
                button.isSelected = !isEnabled
                loadSelfVideoView()
            })
        }
    }

    private func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
}
