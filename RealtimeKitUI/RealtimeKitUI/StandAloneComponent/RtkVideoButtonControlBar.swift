//
//  RtkVideoButtonControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 10/04/23.
//

import RealtimeKit
import UIKit

open class RtkVideoButtonControlBar: RtkControlBarButton {
    private let rtkClient: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener

    public init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        rtkSelfListener = RtkEventSelfListener(rtkClient: rtkClient)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_video_enabled")), title: "Video On")
        setSelected(image: RtkImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Video off")
        selectedStateTintColor = rtkSharedTokenColor.status.danger
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        isSelected = !rtkClient.localUser.videoEnabled
        rtkSelfListener.observeSelfVideo { [weak self] enabled in
            guard let self else { return }
            isSelected = !enabled
        }
    }

    override public var isSelected: Bool {
        didSet {
            if isSelected == true {
                accessibilityIdentifier = "Video_ControlBarButton_Selected"
            } else {
                accessibilityIdentifier = "Video_ControlBarButton_UnSelected"
            }
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: RtkControlBarButton) {
        if rtkSelfListener.isCameraPermissionGranted() {
            button.showActivityIndicator()
            rtkSelfListener.toggleLocalVideo(completion: { enableVideo in
                button.isSelected = !enableVideo
                button.hideActivityIndicator()
            })
        }
    }

    deinit {
        self.rtkSelfListener.clean()
    }
}
