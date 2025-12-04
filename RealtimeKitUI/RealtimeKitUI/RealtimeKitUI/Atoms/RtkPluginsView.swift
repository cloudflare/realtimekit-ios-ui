//
//  RtkPluginsView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 06/01/23.
//

import RealtimeKit
import UIKit
import WebKit

public class RtkActiveTabSelectorView: UIView {
    private let scrollView: UIScrollView = .init()
    private let fixButtonBaseView: UIView = .init()

    public private(set) var buttons: [RtkPluginScreenShareTabButton] = .init()
    private(set) var fixButtons: [RtkPluginScreenShareTabButton] = .init()
    let tokenSpace = DesignLibrary.shared.space
    let tokenColor = DesignLibrary.shared.color
    private var stackView: UIStackView!

    init() {
        super.init(frame: .zero)
        backgroundColor = tokenColor.background.shade900
        addSubview(scrollView)
        scrollView.set(.fillSuperView(self))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func scrollToVisible(button: RtkPluginScreenShareTabButton) {
        if buttons.contains(button) {
            let buttonFrame = stackView.convert(button.frame, to: scrollView.coordinateSpace)
            let maxX = buttonFrame.maxX
            let startX = buttonFrame.origin.x
            let currentWidowFrame = CGRect(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y, width: scrollView.bounds.width, height: scrollView.bounds.height)
            if startX >= currentWidowFrame.origin.x, maxX <= currentWidowFrame.maxX {
                // If button is already in visible rect then no need to do anything
            } else {
                if startX < currentWidowFrame.origin.x {
                    scrollView.setContentOffset(CGPoint(x: startX, y: 0), animated: true)
                } else if maxX > currentWidowFrame.maxX {
                    let pages = Int(maxX / scrollView.bounds.width)
                    scrollView.setContentOffset(CGPoint(x: maxX - (scrollView.bounds.width * CGFloat(pages)), y: 0), animated: true)
                }
            }
        }
    }

    public func setAndDisplayButtons(_ buttons: [RtkPluginScreenShareTabButton]) {
        if stackView == nil {
            stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
            scrollView.addSubview(stackView)
            scrollView.addSubview(fixButtonBaseView)
            fixButtonBaseView.set(.leading(scrollView, tokenSpace.space3),
                                  .sameTopBottom(self, tokenSpace.space2))
            stackView.set(.trailing(scrollView, tokenSpace.space3),
                          .after(fixButtonBaseView, tokenSpace.space3),
                          .sameTopBottom(self, tokenSpace.space2))
        }

        for button in self.buttons {
            button.removeFromSuperview()
        }
        for button in buttons {
            stackView.addArrangedSubview(button)
        }
        self.buttons = buttons
    }

    func setButtons(fixButtons: [RtkPluginScreenShareTabButton]) {
        if stackView == nil {
            stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
            scrollView.addSubview(stackView)
            scrollView.addSubview(fixButtonBaseView)
            fixButtonBaseView.set(.leading(scrollView, tokenSpace.space3),
                                  .sameTopBottom(self, tokenSpace.space2))
            stackView.set(.trailing(scrollView, tokenSpace.space3),
                          .after(fixButtonBaseView, tokenSpace.space3),
                          .sameTopBottom(self, tokenSpace.space2))
        }
        for button in self.fixButtons {
            button.removeFromSuperview()
        }
        var pre: RtkPluginScreenShareTabButton! = nil
        for (index, button) in fixButtons.enumerated() {
            fixButtonBaseView.addSubview(button)
            button.set(.sameTopBottom(fixButtonBaseView))
            if index == 0 {
                button.set(.leading(fixButtonBaseView))
            }
            if index == (fixButtons.count - 1) {
                if pre != nil {
                    button.set(.after(pre!, tokenSpace.space3))
                }
                button.set(.trailing(fixButtonBaseView))
            } else {
                if pre != nil {
                    button.set(.after(pre!, tokenSpace.space3))
                }
            }
            pre = button
        }
        self.fixButtons = fixButtons
    }
}

class ActiveSpeakerPinView: UIView {
    let spaceToken = DesignLibrary.shared.space

    private lazy var pinView: UIView = {
        let baseView = UIView()
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image: ImageProvider.image(named: "icon_pin")))
        baseView.addSubview(imageView)
        imageView.set(.fillSuperView(baseView, spaceToken.space1))
        return baseView
    }()

    private(set) var videoView: RtkVideoView!

    func pinView(show: Bool) {
        let heightWidth: CGFloat = 30
        if pinView.superview == nil {
            addSubview(pinView)
            pinView.backgroundColor = rtkSharedTokenColor.background.shade900
            pinView.set(.leading(self, rtkSharedTokenSpace.space3),
                        .top(self, rtkSharedTokenSpace.space3),
                        .height(heightWidth),
                        .width(heightWidth))
            pinView.layer.cornerRadius = spaceToken.space1
        }
        pinView.isHidden = !show
    }

    private let participant: RtkMeetingParticipant

    init(participant: RtkMeetingParticipant) {
        self.participant = participant
        super.init(frame: .zero)
        createSubview()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubview() {
        let videoView = RtkVideoView(participant: participant)
        addSubview(videoView)
        videoView.set(.fillSuperView(self))
        self.videoView = videoView
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handler)))
    }

    @objc func handler(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: superview)
        let animationDuration = 0.5
        let draggedView = gesture.view
        draggedView?.center = location

        if gesture.state == .ended {
            if frame.midX >= superview!.layer.frame.width / 2 {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.x = self.superview!.layer.frame.width - (self.frame.width / 2)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.x = self.frame.width / 2
                }, completion: nil)
            }
            if frame.minY <= 0 {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.y = self.frame.height / 2
                }, completion: nil)
            } else if frame.maxY >= superview!.layer.frame.height {
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.center.y = self.superview!.layer.frame.height - (self.frame.height / 2)
                }, completion: nil)
            }
        }
    }
}

public class RtkPluginsView: UIView {
    public let activeListView = RtkActiveTabSelectorView()
    public let pluginVideoView: RtkParticipantTileView
    public let syncButton: SyncScreenShareTabButton?

    private var clickAction: ((RtkPluginScreenShareTabButton, Bool) -> Void)?
    private var syncButtonClickAction: ((SyncScreenShareTabButton) -> Void)?
    private let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 0)
    private let activeSpeakerView: ActiveSpeakerPinView
    private let backgroundColorValue = DesignLibrary.shared.color.background.video
    private let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePeerView ?? .rounded
    private let spaceToken = DesignLibrary.shared.space
    private var webView: UIView?

    public init(videoPeerViewModel: VideoPeerViewModel) {
        pluginVideoView = RtkParticipantTileView(viewModel: videoPeerViewModel)
        pluginVideoView.nameTag.isHidden = true
        activeSpeakerView = ActiveSpeakerPinView(participant: videoPeerViewModel.participant)
        if videoPeerViewModel.rtkClient.localUser.permissions.miscellaneous.canSpotLight {
            syncButton = SyncScreenShareTabButton(image: nil, title: "Sync on")
            syncButton?.setSelected(title: "Sync off")
            syncButton?.isSelected = false
        } else {
            syncButton = nil
        }
        super.init(frame: .zero)
        addSubview(stackView)
        stackView.set(.fillSuperView(self))
        let pluginBaseView = UIView()
        stackView.addArrangedSubviews(activeListView, pluginBaseView)
        pluginBaseView.addSubview(pluginVideoView)
        pluginVideoView.set(.fillSuperView(pluginBaseView))

        addSubview(activeSpeakerView)
        activeSpeakerView.layer.masksToBounds = true
        activeSpeakerView.backgroundColor = backgroundColorValue
        activeSpeakerView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        activeSpeakerView.set(.trailing(self, spaceToken.space2),
                              .bottom(self, spaceToken.space2),
                              .equateAttribute(.width, toView: self, toAttribute: .width, withRelation: .equal, multiplier: 0.4),
                              .equateAttribute(.height, toView: self, toAttribute: .height, withRelation: .equal, multiplier: 0.4))

        activeSpeakerView.isHidden = true

        syncButton?.addTarget(self, action: #selector(syncButtonClick(button:)), for: .touchUpInside)
    }

    public func observeSyncButtonClick(clickAction: ((SyncScreenShareTabButton) -> Void)?) {
        syncButtonClickAction = clickAction
    }

    @objc func syncButtonClick(button: SyncScreenShareTabButton) {
        button.isSelected = !button.isSelected
        syncButtonClickAction?(button)
    }

    public func setButtons(buttons: [RtkPluginScreenShareTabButton], selectedIndex: Int?, clickAction: @escaping (RtkPluginScreenShareTabButton, Bool) -> Void) {
        if let index = selectedIndex, index < buttons.count {
            buttons[index].isSelected = true
        }
        for (index, button) in buttons.enumerated() {
            button.index = index
            button.addTarget(self, action: #selector(clickButton(button:)), for: .touchUpInside)
        }
        self.clickAction = clickAction
        var fixButtons = [RtkPluginScreenShareTabButton]()
        if let syncButton {
            fixButtons.append(syncButton)
        }
        activeListView.setButtons(fixButtons: fixButtons)
        activeListView.setAndDisplayButtons(buttons)
        activeListView.isHidden = buttons.count > 1 ? false : true
    }

    @objc func clickButton(button: RtkPluginScreenShareTabButton) {
        activeListView.scrollToVisible(button: button)
        clickAction?(button, true)
    }

    public func selectForAutoSync(button: RtkPluginScreenShareTabButton) {
        activeListView.scrollToVisible(button: button)
        clickAction?(button, false)
    }

    public func show(pluginView view: UIView) {
        if let constraints = webView?.constraints {
            webView?.removeConstraints(constraints)
        }
        webView?.removeFromSuperview()
        pluginVideoView.addSubview(view)
        view.set(.fillSuperView(pluginVideoView))
        webView = view
        webView?.isHidden = false
    }

    public func showVideoView(participant: RtkMeetingParticipant) {
        webView?.isHidden = true
        pluginVideoView.viewModel.set(participant: participant)
    }

    public func showPinnedView(participant: RtkMeetingParticipant) {
        activeSpeakerView.pinView(show: true)
        showActiveSpeakerOrPinnedView(participant: participant)
    }

    public func showActiveSpeakerView(participant: RtkMeetingParticipant) {
        activeSpeakerView.pinView(show: false)
        showActiveSpeakerOrPinnedView(participant: participant)
    }

    public func hideActiveSpeaker() {
        if activeSpeakerView.isHidden {
            return
        }
        activeSpeakerView.videoView.prepareForReuse()
        activeSpeakerView.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RtkPluginsView {
    private func showActiveSpeakerOrPinnedView(participant: RtkMeetingParticipant) {
        activeSpeakerView.videoView.set(participant: participant)
        activeSpeakerView.isHidden = false
    }
}
