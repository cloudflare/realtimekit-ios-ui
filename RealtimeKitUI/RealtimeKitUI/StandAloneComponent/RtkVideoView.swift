//
//  RtkVideoView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 07/02/23.
//

import RealtimeKit
import UIKit

public class RtkVideoView: UIView {
    private var renderView: UIView? // Video View returned from MobileCore SDK
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private var participant: RtkMeetingParticipant
    private var onRendered: (() -> Void)?
    private let showSelfPreview: Bool
    private let showScreenShareView: Bool
    private var hasMovedToWindow = false

    public init(participant: RtkMeetingParticipant, showSelfPreview: Bool = false, showScreenShare: Bool = false) {
        self.participant = participant
        self.showSelfPreview = showSelfPreview
        showScreenShareView = showScreenShare
        super.init(frame: .zero)
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView is being Created")
        }
        set(participant: participant)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(participant: RtkMeetingParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView set(participant:) is called")
        }
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
        self.participant = participant
        self.participant.addParticipantUpdateListener(participantUpdateListener: self)
        refreshView()
    }

    func refreshView() {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView refreshView() is called")
        }
        showVideoView(participant: participant)
    }

    /// Force reattach the video renderer. Call this when returning to a screen after the video view may have been detached.
    /// This is useful when navigating back from screens that used getSelfPreview() or other video views.
    public func reattachRenderer() {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView reattachRenderer() is called")
        }
        // Remove the current render view to force SDK to provide a fresh one
        prepareForReuse()
        // Refresh to get and attach the new render view
        refreshView()
    }

    public func prepareForReuse() {
        if renderView?.superview == self {
            // As Core SDK provides cached renderView, So If someone ask for the view SDK will return the same view and Hence self.renderView.superView is changed , But self.renderView is still pointing to same cached SDK View.
            renderView?.removeFromSuperview()
        }
        renderView = nil
    }

    public func clean() {
        participant.removeParticipantUpdateListener(participantUpdateListener: self)

        prepareForReuse()
    }

    override public func removeFromSuperview() {
        if isDebugModeOn {
            print("Debug RtkUIKit | Removing Video View by calling removeFromSuperview()")
        }
        super.removeFromSuperview()
        prepareForReuse()
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        // When view is added back to window hierarchy, reattach renderer if needed
        if window != nil {
            if hasMovedToWindow {
                // This is a return to window (not first time), so reattach
                if isDebugModeOn {
                    print("Debug RtkUIKit | RtkVideoView returned to window, reattaching renderer")
                }
                reattachRenderer()
            } else {
                hasMovedToWindow = true
            }
        }
    }

    deinit {
        print("Debug RtkUIKit | RtkVideoView deinit is calling")
    }
}

extension RtkVideoView {
    private func showVideoView(participant: RtkMeetingParticipant) {
        if participant.screenShareEnabled, showScreenShareView == true {
            let view = participant.getScreenShareVideoView()

            if let nonNullableView = view {
                if isDebugModeOn {
                    print("Debug RtkUIKit | VideoView Screen share view \(nonNullableView.bounds) \(nonNullableView.frame)")
                }
                setRenderView(view: nonNullableView)
            }
            isHidden = false
        } else if let participant = participant as? RtkSelfParticipant, showSelfPreview == true, participant.videoEnabled == true {
            if let selfVideoView = participant.getSelfPreview() {
                if isDebugModeOn {
                    print("Debug RtkUIKit | Participant \(participant.name) is RtkSelfParticipant videoView bounds \(selfVideoView.bounds) frame \(selfVideoView.frame)")
                }
                setRenderView(view: selfVideoView)
            }
            isHidden = false

        } else if let view = participant.getVideoView(), participant.videoEnabled == true {
            if isDebugModeOn {
                print("Debug RtkUIKit | Participant \(participant.name) videoView bounds \(view.bounds) frame \(view.frame)")
            }
            setRenderView(view: view)
            isHidden = false
        } else {
            if isDebugModeOn {
                print("Debug RtkUIKit | VideoView participant video is NIL: \(String(describing: participant.getVideoView()))")
            }
            isHidden = true
        }
    }

    private func setRenderView(view: UIView) {
        renderView?.removeFromSuperview()
        renderView = view
        addSubview(view)
        view.set(.fillSuperView(self))
        if isDebugModeOn {
            print("Debug RtkUIKit | Rendered VideoView \(view) Parent View :\(self) superView: \(String(describing: superview))")
        }
        onRendered?()
    }
}

extension RtkVideoView: RtkParticipantUpdateListener {
    public func onAudioUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    public func onPinned(participant _: RtkMeetingParticipant) {}

    public func onScreenShareUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    public func onUnpinned(participant _: RtkMeetingParticipant) {}

    public func onUpdate(participant _: RtkMeetingParticipant) {}

    public func onVideoUpdate(participant: RtkMeetingParticipant, isEnabled _: Bool) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate VideoView onVideoUpdate(participant Name \(participant.name)")
        }
        showVideoView(participant: self.participant)
    }
}
