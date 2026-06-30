//
//  RtkAvatarView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public class RtkAvatarView: UIView {
    var profileImageView: BaseImageView = {
        let imageView = RtkUIUtility.createImageView(image: nil)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    let initialName: RtkLabel = RtkUIUtility.createLabel(text: "")
    private var participant: RtkMeetingParticipant?

    public init() {
        super.init(frame: .zero)
        createSubView()
        refresh()
    }

    public init(participant: RtkMeetingParticipant) {
        self.participant = participant
        super.init(frame: .zero)
        createSubView()
        refresh()
    }

    public func set(participant: RtkMeetingParticipant) {
        self.participant = participant
        refresh()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateInitialNameConstraints()
    }

    public func refresh() {
        if let participant {
            if let path = participant.picture {
                showImage(path: path)
            }
            setInitials(name: participant.name)
        }
    }

    public func setInitialName(font: UIFont) {
        initialName.font = font
    }
}

extension RtkAvatarView {
    private func createSubView() {
        addSubview(initialName)
        backgroundColor = rtkSharedTokenColor.brand.shade500
        addSubview(profileImageView)
        profileImageView.set(.fillSuperView(self))
        initialName.adjustsFontSizeToFitWidth = true
        initialName.font = UIFont.boldSystemFont(ofSize: 30)
        initialName.set(.leading(self, rtkSharedTokenSpace.space1),
                        .trailing(self, rtkSharedTokenSpace.space1),
                        .centerY(self),
                        .height(0))
        initialName.get(.leading)?.priority = .defaultHigh
        initialName.get(.trailing)?.priority = .defaultHigh
        layer.masksToBounds = true
    }

    private func updateInitialNameConstraints() {
        let multiplier: CGFloat = 0.4
        let height = bounds.height * multiplier
        let minheight: CGFloat = 20
        let maxheight: CGFloat = 40
        if height < minheight || height > maxheight {
            if height < minheight {
                initialName.get(.height)?.constant = minheight
            }
            if height > maxheight {
                initialName.get(.height)?.constant = maxheight
            }
        } else {
            initialName.get(.height)?.constant = height
        }
        layer.cornerRadius = bounds.width / 2.0
    }

    private func showImage(path: String) {
        if let url = URL(string: path) {
            profileImageView.isHidden = false
            profileImageView.setImage(image: RtkImage(url: url))
        }
    }

    private func setInitials(name: String) {
        initialName.text = getNameInitials(name: name.isEmpty ? "P" : name)
    }

    private func getNameInitials(name: String) -> String {
        var nameInitials = ""
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            formatter.style = .abbreviated
            nameInitials = formatter.string(from: components)
        } else {
            if let first = name.first {
                nameInitials = "\(first)"
            } else {
                nameInitials = ""
            }
        }
        return nameInitials
    }
}
