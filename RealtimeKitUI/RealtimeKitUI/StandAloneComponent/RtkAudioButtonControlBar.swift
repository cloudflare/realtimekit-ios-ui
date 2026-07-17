//
//  RtkAudioButtonControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 13/06/23.
//

import Foundation
import RealtimeKit

open class RtkAudioButtonControlBar: RtkControlBarButton {
    private let rtkClient: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener
    private let onClick: ((RtkAudioButtonControlBar) -> Void)?

    public init(meeting: RealtimeKitClient, onClick: ((RtkAudioButtonControlBar) -> Void)? = nil, appearance: RtkControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        rtkClient = meeting
        self.onClick = onClick
        rtkSelfListener = RtkEventSelfListener(rtkClient: rtkClient)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled")), title: "Mic on", appearance: appearance)
        setSelected(image: RtkImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mic off")
        selectedStateTintColor = rtkSharedTokenColor.status.danger
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        isSelected = !rtkClient.localUser.audioEnabled

        rtkSelfListener.observeSelfAudio { [weak self] enabled in
            guard let self else { return }
            isEnabled = true
            isSelected = !enabled
        }
    }

    override public var isSelected: Bool {
        didSet {
            if isSelected == true {
                accessibilityIdentifier = "Mic_ControlBarButton_Selected"
            } else {
                accessibilityIdentifier = "Mic_ControlBarButton_UnSelected"
            }
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: RtkAudioButtonControlBar) {
        button.showActivityIndicator()
        accessibilityIdentifier = "ControlBar_Audio_"
        rtkSelfListener.toggleLocalAudio(completion: { [weak self, weak button] enableAudio in
            button?.isEnabled = true
            button?.hideActivityIndicator()
            button?.isSelected = !enableAudio
            if let button { self?.onClick?(button) }
        }, onPermissionDenied: { [weak button] in
            button?.hideActivityIndicator()
            button?.isEnabled = false
        })
    }

    deinit {
        self.rtkSelfListener.clean()
    }
}
