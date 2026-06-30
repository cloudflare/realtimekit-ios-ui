//
//  RtkRecordingView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

public protocol RtkRecordingViewAppearance: BaseAppearance {
    var textColor: StatusColor.Shade { get set }
    var font: UIFont { get set }
    var imageBackGroundColor: StatusColor.Shade { get set }
}

public class RtkRecordingViewAppearanceModel: RtkRecordingViewAppearance {
    public var textColor: StatusColor.Shade

    public var font: UIFont

    public var imageBackGroundColor: StatusColor.Shade

    public var designLibrary: RtkDesignTokens

    public required init(designLibrary: RtkDesignTokens) {
        self.designLibrary = designLibrary
        font = UIFont.boldSystemFont(ofSize: 12)
        textColor = designLibrary.color.status.danger
        imageBackGroundColor = designLibrary.color.status.danger
    }
}

public class RtkRecordingView: UIView {
    private let tokenSpace = DesignLibrary.shared.space

    private var title: String
    private var image: RtkImage?
    private let appearance: RtkRecordingViewAppearance
    private let meeting: RealtimeKitClient

    public init(meeting: RealtimeKitClient, title: String = "Rec", image: RtkImage? = nil, appearance: RtkRecordingViewAppearance = RtkRecordingViewAppearanceModel(designLibrary: DesignLibrary.shared)) {
        self.title = title
        self.image = image
        self.appearance = appearance
        self.meeting = meeting
        super.init(frame: .zero)
        createSubViews()
        meeting.addRecordingEventListener(recordingEventListener: self)
        if meeting.recording.recordingState == .recording || meeting.recording.recordingState == .starting {
            blinking(start: true)
        } else if meeting.recording.recordingState == .stopping || meeting.recording.recordingState == .idle {
            blinking(start: false)
        }
        accessibilityIdentifier = "Recording_Red_Dot"
    }

    deinit {
        self.meeting.removeRecordingEventListener(recordingEventListener: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubViews() {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 4)
        var imageView = BaseImageView()
        if let image {
            imageView = RtkUIUtility.createImageView(image: image)
        }
        let title = RtkUIUtility.createLabel(text: title)
        title.font = appearance.font
        title.textColor = appearance.textColor
        stackView.addArrangedSubviews(imageView, title)
        if image == nil {
            imageView.set(.width(tokenSpace.space2),
                          .height(tokenSpace.space2))
            imageView.layer.cornerRadius = tokenSpace.space1
        }
        imageView.backgroundColor = appearance.imageBackGroundColor
        addSubview(stackView)
        stackView.set(.fillSuperView(self))
    }

    public func blinking(start: Bool) {
        isHidden = !start
        if start {
            // I have to use DispatchQueue here because recording view didn't blink, and by doing so its start working
            DispatchQueue.main.async {
                self.blink()
            }
        } else {
            stopBlink()
        }
    }
}

extension RtkRecordingView: RtkRecordingEventListener {
    public func onRecordingStateChanged(oldState: RecordingState, newState: RecordingState) {
        if oldState != newState {
            switch newState {
            case .idle:
                onMeetingRecordingEnded()
            case .recording:
                onMeetingRecordingStarted()
            default:
                break
            }
        }
    }

    private func onMeetingRecordingEnded() {
        blinking(start: false)
        NotificationCenter.default.post(name: Notification.Name("Notify_RecordingUpdate"), object: nil, userInfo: nil)
    }

    private func onMeetingRecordingStarted() {
        blinking(start: true)
        NotificationCenter.default.post(name: Notification.Name("Notify_RecordingUpdate"), object: nil, userInfo: nil)
    }
}
