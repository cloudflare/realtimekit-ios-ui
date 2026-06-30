//
//  WaitingRoomView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/02/23.
//

import RealtimeKit
import UIKit

public enum ParticipantMeetingStatus {
    case waiting
    case rejected
    case accepted
    case kicked
    case meetingEnded
    case none
}

extension ParticipantMeetingStatus {
    static func getStatus(status: WaitListStatus) -> ParticipantMeetingStatus {
        switch status {
        case .accepted:
            .accepted
        case .waiting:
            .waiting
        case .rejected:
            .rejected
        default:
            .none
        }
    }
}

public class WaitingRoomView: UIView {
    var titleLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel()
        label.numberOfLines = 0
        return label
    }()

    public var button: RtkButton = RtkUIUtility.createButton(text: "Leave")

    private let automaticClose: Bool

    private let automaticCloseTime = 2
    private let onComplete: () -> Void

    public init(automaticClose: Bool, onCompletion: @escaping () -> Void) {
        self.automaticClose = automaticClose
        onComplete = onCompletion
        super.init(frame: .zero)
        createSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubviews() {
        let baseView = UIView()
        if automaticClose {
            baseView.addSubview(titleLabel)
            titleLabel.set(.sameLeadingTrailing(baseView),
                           .sameTopBottom(baseView))
            Timer.scheduledTimer(withTimeInterval: TimeInterval(automaticCloseTime), repeats: false) { _ in
                self.onComplete()
            }
        } else {
            let buttonBaseView = RtkUIUtility.wrapped(view: button)
            button.set(.centerX(buttonBaseView),
                       .leading(buttonBaseView, rtkSharedTokenSpace.space2, .greaterThanOrEqual),
                       .sameTopBottom(buttonBaseView))
            baseView.addSubViews(titleLabel, buttonBaseView)
            titleLabel.set(.sameLeadingTrailing(baseView),
                           .top(baseView))
            buttonBaseView.set(.sameLeadingTrailing(baseView), .below(titleLabel, rtkSharedTokenSpace.space2),
                               .bottom(baseView))
        }

        addSubview(baseView)
        baseView.set(.centerView(self),
                     .leading(self, rtkSharedTokenSpace.space4, .greaterThanOrEqual),
                     .top(self, rtkSharedTokenSpace.space4, .greaterThanOrEqual))
        button.addTarget(self, action: #selector(clickBottom(button:)), for: .touchUpInside)
    }

    @objc func clickBottom(button _: RtkButton) {
        removeFromSuperview()
        onComplete()
    }

    public func show(status: ParticipantMeetingStatus) {
        if status == .waiting {
            titleLabel.text = "You are in the waiting room, the host will let you in soon."
            titleLabel.textColor = rtkSharedTokenColor.textColor.onBackground.shade1000

        } else if status == .accepted {
            removeFromSuperview()
        } else if status == .rejected {
            titleLabel.text = "Your request to join the meeting was denied."
            titleLabel.textColor = rtkSharedTokenColor.status.danger
        } else if status == .kicked {
            titleLabel.text = "Your were removed from the meeting"
            titleLabel.textColor = rtkSharedTokenColor.status.danger
        } else if status == .meetingEnded {
            titleLabel.text = "The meeting ended."
            titleLabel.textColor = rtkSharedTokenColor.textColor.onBackground.shade1000
        }
    }

    public func show(message: String) {
        titleLabel.text = message
    }
}
