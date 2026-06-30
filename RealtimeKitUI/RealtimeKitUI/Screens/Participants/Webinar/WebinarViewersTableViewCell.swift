//
//  WebinarViewersTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class WebinarViewersTableViewCell: ParticipantTableViewCell {
    let moreButton = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_more_tabbar"))), rtkButtonState: .active)

    private var viewModel: WebinarViewersTableViewCellModel?
    var buttonMoreClick: ((RtkButton) -> Void)?

    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        let videoButtonStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 0)
        buttonStackView.addArrangedSubviews(videoButtonStackView, moreButton)
        moreButton.addTarget(self, action: #selector(moreButtonClick(button:)), for: .touchUpInside)
    }

    @objc func moreButtonClick(button: RtkButton) {
        buttonMoreClick?(button)
    }
}

extension WebinarViewersTableViewCell: ConfigureView {
    var model: WebinarViewersTableViewCellModel {
        if let model = viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }

    func configure(model: WebinarViewersTableViewCellModel) {
        viewModel = model
        profileAvatarView.set(participant: model.participantUpdateEventListener.participant)
        nameLabel.text = model.title
        cellSeparatorBottom.isHidden = !model.showBottomSeparator
        cellSeparatorTop.isHidden = !model.showTopSeparator
        moreButton.isHidden = !model.showMoreButton
    }
}
