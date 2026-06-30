//
//  RtkSwitchCameraButtonControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

open class RtkSwitchCameraButtonControlBar: RtkControlBarButton {
    private let meeting: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener

    public init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_flipcamera_topbar")))
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        if meeting.localUser.permissions.media.canPublishVideo {
            isHidden = !meeting.localUser.videoEnabled
            rtkSelfListener.observeSelfVideo { enabled in
                self.isHidden = !enabled
            }
        } else {
            isHidden = false
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button _: RtkControlBarButton) {
        rtkSelfListener.toggleCamera()
    }

    deinit {
        self.rtkSelfListener.clean()
    }
}
