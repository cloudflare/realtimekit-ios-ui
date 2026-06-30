//
//  RtkMeetingNameTag.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public class RtkMeetingNameTag: RtkNameTag {
    private let meeting: RealtimeKitClient
    private var participant: RtkMeetingParticipant

    public init(meeting: RealtimeKitClient, participant: RtkMeetingParticipant, appearance: RtkNameTagAppearance = AppTheme.shared.nameTagAppearance) {
        self.participant = participant
        self.meeting = meeting
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled")), appearance: appearance, title: "")
        refresh()
    }

    public func set(participant: RtkMeetingParticipant) {
        self.participant = participant
        refresh()
    }

    public func refresh() {
        let name = participant.name
        if meeting.localUser.userId == participant.userId {
            lblTitle.text = "\(name) (you)"
        } else {
            lblTitle.text = name
        }
        setAudio(isEnabled: participant.audioEnabled)
    }

    private func setAudio(isEnabled: Bool) {
        if isEnabled {
            imageView.accessibilityIdentifier = "NameTag_Mic_Enabled"
            imageView.image = ImageProvider.image(named: "icon_mic_enabled")?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = appearance.designLibrary.color.textColor.onBackground.shade1000
        } else {
            imageView.accessibilityIdentifier = "NameTag_Mic_Disabled"
            imageView.image = ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = appearance.designLibrary.color.status.danger
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
