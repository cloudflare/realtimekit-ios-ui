//
//  RtkStageActionButtonControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 19/07/23.
//

import RealtimeKit
import UIKit

class StageButtonStateMachine {
    enum Event {
        case onAccepted
        case onRejected
        case onSuccess
        case leaveSuccessFullWithCanRequest
        case leaveSuccessFullWithJoinStage
        case onFail
        case onButtonTapped
    }

    var currentState: WebinarStageStatus {
        didSet {
            stateTransition?(oldValue, currentState)
        }
    }

    private let possibleState: [WebinarStageStatus: Set<WebinarStageStatus>] =
        [.canRequestToJoinStage: [.requestingToJoinStage],
         .requestingToJoinStage: [.inRequestedStateToJoinStage, .canRequestToJoinStage],
         .inRequestedStateToJoinStage: [.canRequestToJoinStage, .canJoinStage],
         .canJoinStage: [.joiningStage],
         .joiningStage: [.canJoinStage, .alreadyOnStage],
         .alreadyOnStage: [.leavingFromStage],
         .leavingFromStage: [.alreadyOnStage, .canJoinStage, .canRequestToJoinStage],
         .viewOnly: []]

    private var stateTransition: ((WebinarStageStatus, WebinarStageStatus) -> Void)?

    init(state: WebinarStageStatus) {
        currentState = state
    }

    func forcedToSet(currentState: WebinarStageStatus) {
        self.currentState = currentState
    }

    func start() {
        stateTransition?(currentState, currentState)
    }

    func setTransition(update: @escaping (WebinarStageStatus, WebinarStageStatus) -> Void) {
        stateTransition = update
    }

    func removeTransition() {
        stateTransition = nil
    }

    @discardableResult private func transition(toState: WebinarStageStatus) -> Bool {
        if let nextState = canTransition(fromState: currentState, toState: toState) {
            currentState = nextState
            return true
        }
        return false
    }

    private func canTransition(fromState: WebinarStageStatus, toState: WebinarStageStatus) -> WebinarStageStatus? {
        if let possibleState = possibleState[fromState], possibleState.contains(toState) {
            return toState
        }
        return nil
    }

    func handleEvent(event: Event) {
        switch (currentState, event) {
        case (.canRequestToJoinStage, .onButtonTapped):
            transition(toState: .requestingToJoinStage)

        case (.requestingToJoinStage, .onSuccess):
            transition(toState: .inRequestedStateToJoinStage)

        case (.requestingToJoinStage, .onFail):
            transition(toState: .canRequestToJoinStage)

        case (.inRequestedStateToJoinStage, .onRejected):
            transition(toState: .canRequestToJoinStage)

        case (.inRequestedStateToJoinStage, .onAccepted):
            transition(toState: .canJoinStage)

        case (.canJoinStage, .onButtonTapped):
            transition(toState: .joiningStage)

        case (.joiningStage, .onFail):
            transition(toState: .canJoinStage)

        case (.joiningStage, .onSuccess):
            transition(toState: .alreadyOnStage)

        case (.alreadyOnStage, .onButtonTapped):
            transition(toState: .leavingFromStage)

        case (.leavingFromStage, .onFail):
            transition(toState: .alreadyOnStage)

        case (.leavingFromStage, .leaveSuccessFullWithJoinStage):
            transition(toState: .canJoinStage)

        case (.leavingFromStage, .leaveSuccessFullWithCanRequest):
            transition(toState: .canRequestToJoinStage)

        default:
            print("Invalid \(event) happen on current state \(currentState)")
        }
    }
}

public extension StageStatus {
    static func getStageStatus(status: StageStatus? = nil, rtkClient: RealtimeKitClient) -> WebinarStageStatus {
        let state = status ?? rtkClient.stage.stageStatus

        switch state {
        case .offStage:
            // IN off Stage three condition is possible whether
            // 1 He can send request(Permission to join Stage) for approval.(canRequestToJoinStage)
            // 2 He is only in view mode, means can't do anything expect watching.(viewOnly)
            // 3 He is already have permission to join stage and if this is true then stage.stageStatus == acceptedToJoinStage (canJoinStage)
            let videoPermission = rtkClient.localUser.permissions.media.video.permission
            let audioPermission = rtkClient.localUser.permissions.media.audioPermission
            if videoPermission == MediaPermission.allowed || audioPermission == .allowed {
                // Person can able to join on Stage, It means he/she already have permission to join stage.
                return .canJoinStage
            } else if videoPermission == MediaPermission.canRequest || audioPermission == .canRequest {
                return .canRequestToJoinStage
            } else if videoPermission == MediaPermission.notAllowed, audioPermission == .notAllowed {
                return .viewOnly
            }
            return .viewOnly
        case .acceptedToJoinStage:
            return .canJoinStage
        case .onStage:
            return .alreadyOnStage
        case .requestedToJoinStage:
            return .inRequestedStateToJoinStage
        }
    }
}

public protocol RtkStageActionButtonControlBarDataSource {
    func getImage(for stageStatus: WebinarStageStatus) -> RtkImage?
    func getTitle(for stageStatus: WebinarStageStatus) -> String?
    func getAlertView() -> ConfigureWebinerAlertView
}

public protocol ConfigureWebinerAlertView: UIView {
    var confirmAndJoinButton: RtkButton { get }
    var cancelButton: RtkButton { get }
    func show(on view: UIView)
    init(meeting: RealtimeKitClient, participant: RtkMeetingParticipant)
}

public class RtkStageActionButtonControlBar: RtkControlBarButton {
    let stateMachine: StageButtonStateMachine
    private let rtkClient: RealtimeKitClient
    private let selfListener: RtkEventSelfListener
    private let presentingViewController: UIViewController
    public var dataSource: RtkStageActionButtonControlBarDataSource?

    public init(rtkClient: RealtimeKitClient, buttonState: WebinarStageStatus, presentingViewController: UIViewController) {
        self.rtkClient = rtkClient
        self.presentingViewController = presentingViewController
        selfListener = RtkEventSelfListener(rtkClient: rtkClient)
        stateMachine = StageButtonStateMachine(state: buttonState)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Join stage")
        addTarget(self, action: #selector(click(button:)), for: .touchUpInside)
    }

    public func addObserver() {
        stateMachine.setTransition { [weak self] _, currentState in
            guard let self else { return }
            showState(state: currentState)
        }
        stateMachine.start()
    }

    public func updateButton(stageStatus: StageStatus) {
        stateMachine.forcedToSet(currentState: StageStatus.getStageStatus(status: stageStatus, rtkClient: rtkClient))
    }

    public func handleRequestToJoinStage() {
        stateMachine.forcedToSet(currentState: .joiningStage)
        showAlert(baseController: presentingViewController)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clean() {
        stateMachine.removeTransition()
        selfListener.clean()
        removeAlertView()
    }

    deinit {
        clean()
        print("******* stageButton Deinit is calling")
    }

    private func showState(state: WebinarStageStatus) {
        var image: RtkImage? = nil
        var title: String? = nil

        switch state {
        case .canRequestToJoinStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = dataSource?.getTitle(for: state) ?? "Request"
        case .requestingToJoinStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = dataSource?.getTitle(for: state) ?? "Requesting..."
        case .inRequestedStateToJoinStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = dataSource?.getTitle(for: state) ?? "Cancel request"
        case .canJoinStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = dataSource?.getTitle(for: state) ?? "Join stage"
        case .joiningStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_join")))
            title = dataSource?.getTitle(for: state) ?? "Joining..."
        case .alreadyOnStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_leave")))
            title = dataSource?.getTitle(for: state) ?? "Leave stage"
        case .leavingFromStage:
            image = getImage(state: state, defaultImage: RtkImage(image: ImageProvider.image(named: "icon_stage_leave")))
            title = dataSource?.getTitle(for: state) ?? "Leaving..."
        case .viewOnly:
            print("")
        }
        hideActivityIndicator()
        setDefault(image: image, title: title)
        if state == .requestingToJoinStage || state == .leavingFromStage || state == .joiningStage, title != nil {
            showActivityIndicator(title: title!)
        }

        if state == .alreadyOnStage {
            isSelected = true
        }
    }

    private func getImage(state: WebinarStageStatus, defaultImage: RtkImage) -> RtkImage {
        if let image = dataSource?.getImage(for: state) {
            print("image returned for stage \(state)")
            return image
        }
        return defaultImage
    }

    private var alert: ConfigureWebinerAlertView?

    func showAlert(baseController: UIViewController) {
        if alert == nil {
            let alert = dataSource?.getAlertView() ?? RtkWebinarAlertView(meeting: rtkClient, participant: rtkClient.localUser)
            alert.confirmAndJoinButton.addTarget(self, action: #selector(alertConfirmAndJoinClick(button:)), for: .touchUpInside)
            alert.cancelButton.addTarget(self, action: #selector(alertCancelButton(button:)), for: .touchUpInside)
            self.alert = alert
            alert.show(on: baseController.view)
            Shared.data.delegate?.webinarJoinStagePopupDidShow()
        }
    }

    private func removeAlertView() {
        alert?.removeFromSuperview()
        alert = nil
    }

    @objc open func alertConfirmAndJoinClick(button _: RtkJoinButton) {
        removeAlertView()
        Shared.data.delegate?.webinarJoinStagePopupDidHide(click: .confirmAndJoin)
        selfListener.joinWebinarStage { _ in
        }
    }

    @objc open func alertCancelButton(button _: RtkJoinButton) {
        removeAlertView()
        Shared.data.delegate?.webinarJoinStagePopupDidHide(click: .cancel)
        stateMachine.handleEvent(event: .onFail)
        selfListener.leaveWebinarStage { _ in
        }
    }

    @objc func click(button _: RtkControlBarButton) {
        let currentState = stateMachine.currentState
        switch currentState {
        case .canJoinStage:
            stateMachine.handleEvent(event: .onButtonTapped)
            showAlert(baseController: presentingViewController)

        case .alreadyOnStage:
            stateMachine.handleEvent(event: .onButtonTapped)
            selfListener.leaveWebinarStage { _ in }

        case .inRequestedStateToJoinStage:
            stateMachine.handleEvent(event: .onButtonTapped)
            selfListener.cancelRequestForPermissionToJoinWebinarStage { _ in }

        case .canRequestToJoinStage:
            stateMachine.handleEvent(event: .onButtonTapped)
            selfListener.requestForPermissionToJoinWebinarStage { _ in }

        default:
            print("Not handle case")
        }
    }
}
