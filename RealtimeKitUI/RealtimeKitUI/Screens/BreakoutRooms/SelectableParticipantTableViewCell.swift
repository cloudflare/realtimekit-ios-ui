//
//  SelectableParticipantTableViewCell.swift
//  RealtimeKitUI
//

import RealtimeKit
import UIKit

final class SelectableParticipantTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SelectableParticipantTableViewCell"

    // MARK: Subviews

    private let checkboxView: UIView = {
        let v = UIView()
        v.layer.borderWidth = 2
        v.layer.borderColor = rtkSharedTokenColor.brand.shade500.cgColor
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let checkmark: UILabel = {
        let l = UILabel()
        l.text = "✓"
        l.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = rtkSharedTokenColor.brand.shade500
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let youBadge: UILabel = {
        let l = UILabel()
        l.text = "(you)"
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = DesignLibrary.shared.color.textColor.onBackground.shade700
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    // MARK: State

    var isChecked = false {
        didSet { updateCheckbox() }
    }

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

        checkboxView.addSubview(checkmark)
        avatarView.addSubview(avatarLabel)

        contentView.addSubview(checkboxView)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(youBadge)

        NSLayoutConstraint.activate([
            checkboxView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkboxView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkboxView.widthAnchor.constraint(equalToConstant: 20),
            checkboxView.heightAnchor.constraint(equalToConstant: 20),

            checkmark.centerXAnchor.constraint(equalTo: checkboxView.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: checkboxView.centerYAnchor),

            avatarView.leadingAnchor.constraint(equalTo: checkboxView.trailingAnchor, constant: 12),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            youBadge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            youBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            youBadge.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),
        ])
    }

    // MARK: Configure

    func configure(participant: RtkConnectedMeetingParticipant, isChecked: Bool, isSelf: Bool) {
        let initial = participant.displayName.prefix(1).uppercased()
        avatarLabel.text = initial.isEmpty ? "?" : initial
        nameLabel.text = participant.displayName
        youBadge.isHidden = !isSelf
        self.isChecked = isChecked
    }

    // MARK: Private

    private func updateCheckbox() {
        if isChecked {
            checkboxView.backgroundColor = rtkSharedTokenColor.brand.shade500
            checkmark.isHidden = false
        } else {
            checkboxView.backgroundColor = .clear
            checkmark.isHidden = true
        }
    }
}
