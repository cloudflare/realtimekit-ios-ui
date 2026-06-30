//
//  RtkMeetingTitleLabel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public class RtkMeetingTitleLabel: RtkLabel {
    private let meeting: RealtimeKitClient

    public init(meeting: RealtimeKitClient, appearance: RtkTextAppearance = AppTheme.shared.meetingTitleAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        text = self.meeting.meta.meetingTitle
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
