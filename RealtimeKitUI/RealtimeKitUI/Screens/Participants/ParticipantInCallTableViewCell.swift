//
//  ParticipantInCallTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class ParticipantInCallTableViewCell: ParticipantTableViewCell {
    let videoButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_video_enabled"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = .clear
        return button
    }()

    let audioButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = .clear
        return button
    }()

    var notificationBadge: RtkNotificationBadgeView?
    var moreButton = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_more_tabbar"))), rtkButtonState: .active)

    private var viewModel: ParticipantInCallTableViewCellModel?
    var buttonMoreClick: ((RtkButton) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        profileAvatarView.backgroundColor = rtkSharedTokenColor.brand.shade500
        profileAvatarView.profileImageView.image = nil
        profileAvatarView.initialName.text = nil
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        notificationBadge?.isHidden = true
    }

    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        let videoButtonStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 0)
        videoButtonStackView.addArrangedSubviews(videoButton, audioButton)
        buttonStackView.addArrangedSubviews(videoButtonStackView, moreButton)
        moreButton.addTarget(self, action: #selector(moreButtonClick(button:)), for: .touchUpInside)
    }

    @objc func moreButtonClick(button: RtkButton) {
        buttonMoreClick?(button)
    }
}

extension ParticipantInCallTableViewCell: ConfigureView {
    var model: ParticipantInCallTableViewCellModel {
        if let model = viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }

    func configure(model: ParticipantInCallTableViewCellModel) {
        viewModel = model
        profileAvatarView.set(participant: model.participantUpdateEventListener.participant)
        audioButton.isSelected = !model.participantUpdateEventListener.participant.audioEnabled
        videoButton.isSelected = !model.participantUpdateEventListener.participant.videoEnabled
        nameLabel.text = model.title
        cellSeparatorBottom.isHidden = !model.showBottomSeparator
        cellSeparatorTop.isHidden = !model.showTopSeparator
        moreButton.isHidden = !model.showMoreButton
        model.participantUpdateEventListener.observeAudioState { [weak self] isEnabled, _ in
            guard let self else { return }
            audioButton.isSelected = !isEnabled
        }
        model.participantUpdateEventListener.observePinState { [weak self] isPinned, _ in
            guard let self else { return }
            setPinView(isHidden: !isPinned)
        }
        model.participantUpdateEventListener.observeVideoState { [weak self] isEnabled, _ in
            guard let self else { return }
            videoButton.isSelected = !isEnabled
        }
    }
}
