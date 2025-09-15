//
//  RtkParticipantTileView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 06/01/23.
//

import RealtimeKit
import UIKit

public class RtkParticipantTileView: RtkPeerView {
    private lazy var videoView: RtkVideoView = {
        if self.isDebugModeOn {
            print("Debug RtkUIKit | RtkParticipantTileView trying to create videoView through Lazy Property")
        }

        let view = RtkVideoView(participant: self.viewModel.participant, showSelfPreview: self.viewModel.showSelfPreviewVideo, showScreenShare: self.viewModel.showScreenShareVideoView)
        view.accessibilityIdentifier = "Rtk_Video_View"
        return view
    }()

    private let tokenColor = DesignLibrary.shared.color
    private let spaceToken = DesignLibrary.shared.space
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private lazy var pinView: UIView = {
        let baseView = UIView()
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image: ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.leading(baseView, spaceToken.space1),
                      .trailing(baseView, spaceToken.space1),
                      .top(baseView, spaceToken.space1),
                      .bottom(baseView, spaceToken.space1))
        imageView.get(.leading)?.priority = .defaultHigh
        imageView.get(.trailing)?.priority = .defaultHigh
        imageView.get(.top)?.priority = .defaultHigh
        imageView.get(.bottom)?.priority = .defaultHigh
        return baseView
    }()

    private lazy var rtkAvatarView = RtkAvatarView(participant: self.viewModel.participant)

    public private(set) var nameTag: RtkMeetingNameTag!
    public let viewModel: VideoPeerViewModel

    public init(viewModel: VideoPeerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        initialiseView()
        updateView()
        registerUpdates()
        nameTag.backgroundColor = nameTag.backgroundColor?.withAlphaComponent(0.6)
    }

    public convenience init(rtkClient: RealtimeKitClient, participant: RtkMeetingParticipant, isForLocalUser: Bool, showScreenShareVideoView: Bool = false) {
        self.init(viewModel: VideoPeerViewModel(meeting: rtkClient, participant: participant, showSelfPreviewVideo: isForLocalUser, showScreenShareVideoView: showScreenShareVideoView))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func pinView(show: Bool) {
        if pinView.superview == nil {
            addSubview(pinView)
            pinView.backgroundColor = tokenColor.background.shade900.withAlphaComponent(0.6)
            pinView.set(.leading(self, rtkSharedTokenSpace.space3, .lessThanOrEqual),
                        .top(self, rtkSharedTokenSpace.space3, .lessThanOrEqual),
                        .height(0),
                        .width(0))
            pinView.layer.cornerRadius = rtkSharedTokenSpace.space1
        }
        pinView.isHidden = !show
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updatePinViewHeightConstraint()
        updateAvatarViewHeightConstraint()
        updateNameTagViewHeightConstraint()
    }

    public func refreshVideo() {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkParticipantTileView refreshVideo() is called, Video Enable \(viewModel.participant.videoEnabled) Update is Screen name \(viewModel.participant.name)")
        }
        videoView.refreshView()
    }

    override public func removeFromSuperview() {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkParticipantTileView \(self) removeFromSuperview() is called")
        }
        videoView.removeFromSuperview()
        super.removeFromSuperview()
    }

    deinit {
        self.videoView.clean()
        if self.isDebugModeOn {
            print("Debug RtkUIKit | RtkParticipantTileView \(self) deinit is calling")
        }
    }
}

extension RtkParticipantTileView {
    private func updateAvatarViewHeightConstraint() {
        var width = bounds.height * 0.4
        if bounds.height > bounds.width {
            width = bounds.width * 0.4
        }

        let maxHeightWidth: CGFloat = 100
        let minHeightWidth: CGFloat = 40

        if width > maxHeightWidth || width < minHeightWidth {
            if width > maxHeightWidth {
                rtkAvatarView.get(.width)?.constant = maxHeightWidth
                rtkAvatarView.get(.height)?.constant = maxHeightWidth
            }
            if width < minHeightWidth {
                rtkAvatarView.get(.width)?.constant = minHeightWidth
                rtkAvatarView.get(.height)?.constant = minHeightWidth
            }
        } else {
            rtkAvatarView.get(.width)?.constant = width
            rtkAvatarView.get(.height)?.constant = width
        }
    }

    private func updatePinViewHeightConstraint() {
        let width = bounds.width * 0.2
        let maxHeightWidth: CGFloat = 30
        let minHeightWidth: CGFloat = 15

        if width > maxHeightWidth || width < minHeightWidth {
            if width > maxHeightWidth {
                pinView.get(.width)?.constant = maxHeightWidth
                pinView.get(.height)?.constant = maxHeightWidth
            }
            if width < minHeightWidth {
                pinView.get(.width)?.constant = minHeightWidth
                pinView.get(.height)?.constant = minHeightWidth
            }
        } else {
            pinView.get(.width)?.constant = width
            pinView.get(.height)?.constant = width
        }
    }

    private func updateNameTagViewHeightConstraint() {
        var height = bounds.height * 0.12
        let maxHeightWidth: CGFloat = 36
        let minHeightWidth: CGFloat = 18
        let maxFontSize = 16.0
        let minFontSize = 9.0
        let factorWidth = maxHeightWidth - minHeightWidth
        let fontFactor = maxFontSize - minFontSize
        let maxLeadingBottom = spaceToken.space3
        let minLeadingBottom = spaceToken.space1
        let leadingBottomFactor = maxLeadingBottom - minLeadingBottom

        if height > maxHeightWidth || height < minHeightWidth {
            if height > maxHeightWidth {
                height = maxHeightWidth
            }
            if height < minHeightWidth {
                height = minHeightWidth
            }
        }
        if nameTag.get(.height) == nil {
            nameTag.set(.height(height))
        }
        nameTag.get(.height)?.constant = height

        let newWidth = height - minHeightWidth
        let fontSize = newWidth * (fontFactor / factorWidth) + minFontSize
        let leadingBottomSpace = newWidth * (leadingBottomFactor / factorWidth) + minLeadingBottom
        nameTag.lblTitle.font = UIFont.systemFont(ofSize: fontSize)
        nameTag.get(.leading)?.constant = leadingBottomSpace
        nameTag.get(.bottom)?.constant = -leadingBottomSpace
        pinView.get(.leading)?.constant = leadingBottomSpace
        pinView.get(.top)?.constant = leadingBottomSpace
    }

    private func initialiseView() {
        if isDebugModeOn {
            print("Debug RtkUIKit | New RtkParticipantTileView \(self) tile is created to load a video")
        }
        addSubview(rtkAvatarView)
        rtkAvatarView.set(.centerView(self),
                          .height(0),
                          .width(0))
        addSubview(videoView)
        videoView.set(.fillSuperView(self))
        nameTag = RtkMeetingNameTag(meeting: viewModel.rtkClient, participant: viewModel.participant)
        addSubview(nameTag)

        nameTag.set(.leading(self, spaceToken.space3),
                    .bottom(self, spaceToken.space3),
                    .trailing(self, spaceToken.space3, .greaterThanOrEqual))
    }

    private func updateView() {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkParticipantTileView refreshVideo() is called Internally through updateView()")
        }

        refreshVideo()
        pinView(show: viewModel.participant.isPinned)
    }

    private func registerUpdates() {
        viewModel.nameUpdate = { [weak self] in
            guard let self else { return }
            nameTag.refresh()
        }
        viewModel.nameInitialsUpdate = { [weak self] in
            guard let self else { return }
            rtkAvatarView.refresh()
        }
        viewModel.audioUpdate = { [weak self] in
            guard let self else { return }
            nameTag.refresh()
        }
        viewModel.loadNewParticipant = { [weak self] participant in
            guard let self else { return }
            nameTag.set(participant: participant)
            rtkAvatarView.set(participant: participant)
            videoView.set(participant: participant)
        }
    }
}

public class RtkParticipantTileContainerView: UIView {
    public var tileView: RtkParticipantTileView!

    public func prepareForReuse() {
        tileView?.removeFromSuperview()
        tileView = nil
    }

    public func setParticipant(meeting: RealtimeKitClient, participant: RtkMeetingParticipant) {
        prepareForReuse()

        let isForLocalUser = participant.id == meeting.localUser.id
        let tile = RtkParticipantTileView(rtkClient: meeting, participant: participant, isForLocalUser: isForLocalUser, showScreenShareVideoView: false)
        tileView = tile
        addSubview(tile)
        tile.set(.fillSuperView(self))
    }
}
