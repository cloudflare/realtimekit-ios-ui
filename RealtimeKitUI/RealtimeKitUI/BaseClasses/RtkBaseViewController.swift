//
//  RtkBaseViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/01/24.
//

import RealtimeKit
import UIKit

open class RtkBaseViewController: UIViewController, AdaptableUI {
    let rtkSelfListener: RtkEventSelfListener!
    public let meeting: RealtimeKitClient
    private var waitingRoomView: WaitingRoomView?
    public var portraitConstraints = [NSLayoutConstraint]()
    public var landscapeConstraints = [NSLayoutConstraint]()

    public init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setUpReconnection(failed: @escaping () -> Void, success: @escaping () -> Void) {
        rtkSelfListener.observeMeetingReconnectionState { [weak self] state in
            guard let self else { return }
            switch state {
            case .failed:
                view.removeToast()
                let retryAction = UIAlertAction(title: "ok", style: .default) { _ in
                    failed()
                }
                RtkUIUtility.displayAlert(alertTitle: "Connection Lost!", message: "Please try again later", actions: [retryAction])
            case .success:
                success()
                view.showToast(toastMessage: "Connection Restored", duration: 2.0)
            case .start:
                view.showToast(toastMessage: "Reconnecting...", duration: -1)
            }
        }
    }

    public func addWaitingRoom(completion: @escaping () -> Void) {
        rtkSelfListener.waitListStatusUpdate = { [weak self] status in
            guard let self else { return }
            let callBack: () -> Void = {
                completion()
            }
            waitingRoomView?.removeFromSuperview()
            if let waitingView = showWaitingRoom(status: status, completion: callBack) {
                waitingView.backgroundColor = view.backgroundColor
                view.addSubview(waitingView)
                waitingView.set(.fillSuperView(view))
                view.endEditing(true)
                waitingView.show(status: ParticipantMeetingStatus.getStatus(status: status))
                waitingRoomView = waitingView
            }
        }

        func showWaitingRoom(status: WaitListStatus, completion: @escaping () -> Void) -> WaitingRoomView? {
            if status != .none {
                let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {
                    completion()
                })
                waitingView.accessibilityIdentifier = "WaitingRoom_View"
                return waitingView
            }
            return nil
        }
    }

    override open func updateViewConstraints() {
        super.updateViewConstraints()
        applyOnlyConstraintAsPerOrientation()
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.setNeedsUpdateConstraints()
        setOrientationConstraintAsInactive()
    }
}
