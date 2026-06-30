//
//  ParticipantTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 13/02/23.
//

import RealtimeKit
import UIKit

class ParticipantTableViewCell: BaseTableViewCell {
    let profileAvatarViewBaseView: BaseView = .init()

    var profileAvatarView: RtkAvatarView = {
        let view = RtkAvatarView()
        view.setInitialName(font: UIFont.boldSystemFont(ofSize: 12))
        return view
    }()

    let spaceToken = DesignLibrary.shared.space

    private lazy var pinView: UIView = {
        let baseView = UIView()
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image: ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.leading(baseView, spaceToken.space1, .lessThanOrEqual),
                      .trailing(baseView, spaceToken.space0, .lessThanOrEqual),
                      .top(baseView, spaceToken.space0, .lessThanOrEqual),
                      .bottom(baseView, spaceToken.space1, .lessThanOrEqual),
                      .height(15),
                      .width(15))
        return baseView
    }()

    let profileImageWidth = rtkSharedTokenSpace.space9

    let nameLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = rtkSharedTokenColor.textColor.onBackground.shade900
        label.numberOfLines = 0
        return label
    }()

    let buttonStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 8)

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Views

    func setupView() {
        let baseView = UIView()
        createSubView(on: baseView)
        contentView.addSubview(baseView)
        baseView.set(.below(cellSeparatorTop, rtkSharedTokenSpace.space3),
                     .above(cellSeparatorBottom, rtkSharedTokenSpace.space3), .sameLeadingTrailing(cellSeparatorBottom))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pinView.isHidden = true
    }

    func setPinView(isHidden: Bool) {
        pinView.isHidden = isHidden
    }

    func createSubView(on baseView: UIView) {
        contentView.backgroundColor = rtkSharedTokenColor.background.shade1000
        baseView.addSubViews(profileAvatarViewBaseView, nameLabel, buttonStackView)
        profileAvatarViewBaseView.addSubview(profileAvatarView)
        profileAvatarView.set(.fillSuperView(profileAvatarViewBaseView))

        profileAvatarViewBaseView.set(.leading(baseView),
                                      .top(baseView, 0.0, .greaterThanOrEqual),
                                      .centerY(baseView), .height(profileImageWidth), .width(profileImageWidth))
        profileAvatarViewBaseView.addSubViews(pinView)
        pinView.set(.trailing(profileAvatarViewBaseView),
                    .top(profileAvatarViewBaseView))

        nameLabel.set(.after(profileAvatarViewBaseView, rtkSharedTokenSpace.space3),
                      .centerY(profileAvatarViewBaseView),
                      .top(baseView, 0.0, .greaterThanOrEqual))
        buttonStackView.set(.after(nameLabel, rtkSharedTokenSpace.space2, .greaterThanOrEqual),
                            .centerY(profileAvatarViewBaseView),
                            .trailing(baseView, 10),
                            .top(baseView, 0.0, .greaterThanOrEqual))
    }
}
