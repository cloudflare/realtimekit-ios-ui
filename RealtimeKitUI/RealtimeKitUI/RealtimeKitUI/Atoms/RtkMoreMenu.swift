//
//  RtkMoreMenu.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 21/01/23.
//

import RealtimeKit
import UIKit

public enum MenuType {
    case shareMeetingUrl
    case poll(notificationMessage: String)
    case chat(notificationMessage: String)
    case plugins
    case settings
    case participants(notificationMessage: String)
    case recordingStart
    case recordingStop
    case muteAllAudio
    case muteAllVideo
    case muteAudio
    case muteVideo
    case pin
    case unPin
    case allowToJoinStage
    case denyToJoinStage
    case removeFromStage
    case startScreenShare
    case stopScreenShare
    case kick
    case files
    case images
    case cancel
}

extension MenuType {
    func getAccessIdentifier() -> String {
        switch self {
        case .shareMeetingUrl:
            "MoreMenu_Option_ShareMeetingUrl"

        case .poll(notificationMessage: _):
            "MoreMenu_Option_Poll"

        case .chat(notificationMessage: _):
            "MoreMenu_Option_Chat"

        case .plugins:
            "MoreMenu_Option_Plugins"

        case .startScreenShare:
            "MoreMenu_Option_Start_Screenshare"

        case .stopScreenShare:
            "MoreMenu_Option_Stop_Screenshare"

        case .settings:
            "MoreMenu_Option_Settings"

        case .participants(notificationMessage: _):
            "MoreMenu_Option_Participants"

        case .recordingStart:
            "MoreMenu_Option_StartRecording"

        case .recordingStop:
            "MoreMenu_Option_StopRecording"

        case .muteAllAudio:
            "MoreMenu_Option_MuteAllAudio"

        case .muteAllVideo:
            "MoreMenu_Option_MuteAllVideo"

        case .muteAudio:
            "MoreMenu_Option_MuteAudio"

        case .muteVideo:
            "MoreMenu_Option_MuteVideo"

        case .pin:
            "MoreMenu_Option_Pin"

        case .unPin:
            "MoreMenu_Option_UnPin"

        case .allowToJoinStage:
            "MoreMenu_Option_AllowToJoinStage"

        case .denyToJoinStage:
            "MoreMenu_Option_DenyToJoinStage"

        case .removeFromStage:
            "MoreMenu_Option_RemoveFromStage"

        case .kick:
            "MoreMenu_Option_Kick"

        case .files:
            "MoreMenu_Option_Files"

        case .images:
            "MoreMenu_Option_Images"

        case .cancel:
            "MoreMenu_Option_Cancel"
        }
    }
}

protocol BottomSheetModelProtocol {
    associatedtype IDENTIFIER
    var image: RtkImage { get }
    var title: String { get }
    var type: IDENTIFIER { get }
    var unreadCount: String { get }
    var onTap: (_ bottomSheet: BottomSheet) -> Void { get }
}

class UnreadCountView: UIView {
    private let title: RtkLabel = {
        let label = RtkUIUtility.createLabel(text: "")
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    override init(frame _: CGRect) {
        super.init(frame: .zero)
        createSubView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(unReadCount: String) {
        if unReadCount.count > 0 {
            isHidden = false
        } else {
            isHidden = true
        }
        title.text = unReadCount
    }

    private func createSubView() {
        backgroundColor = rtkSharedTokenColor.brand.shade500
        addSubview(title)
        title.set(.sameLeadingTrailing(self, rtkSharedTokenSpace.space1),
                  .sameTopBottom(self, rtkSharedTokenSpace.space1))
    }
}

class BottomSheet: UIView {
    let selfTag = 89373
    private let baseStackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 0)
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
    let backgroundColorValue = DesignLibrary.shared.color.background.shade900
    let backgroundColorValueForLineSeparator = DesignLibrary.shared.color.background.shade800
    let tokenSpace = DesignLibrary.shared.space
    var options = [UIView]()
    var onHide: ((BottomSheet) -> Void)?

    init() {
        super.init(frame: .zero)
        addSubview(baseStackView)
        baseStackView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                       radius: borderRadiusType)
        baseStackView.set(.sameLeadingTrailing(self, tokenSpace.space1),
                          .bottom(self),
                          .top(self, tokenSpace.space4, .greaterThanOrEqual))

        baseStackView.backgroundColor = backgroundColorValue
        baseStackView.layoutMargins = UIEdgeInsets(top: 0, left: tokenSpace.space4, bottom: 0, right: 0)
        baseStackView.isLayoutMarginsRelativeArrangement = true
        tag = selfTag
    }

    func reload(title: String? = nil, features: [some BottomSheetModelProtocol]) {
        for view in baseStackView.arrangedSubviews {
            baseStackView.removeFully(view: view)
        }

        if let title, title.count > 0 {
            baseStackView.addArrangedSubview(getTitleView(title: title))
        }

        var views = [UIView]()
        for model in features {
            let button = getMenuButton(title: model.title, systemImage: model.image, unreadCount: model.unreadCount)
            button.button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            button.button.model = model
            baseStackView.addArrangedSubview(button.baseView)
            views.append(button.baseView)
        }
        options = views
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden == false, frame.contains(point) {
            if baseStackView.frame.contains(point) {
                return super.hitTest(point, with: event)
            }
            DispatchQueue.main.async {
                // This is so that when this view say that touches are in this but not action sheet button.
                // then we have to consume these touches and current view should not be hidden before returning from this method else this will ignore these touches and passes down the hierarchy.
                self.hideSheet()
            }
            return self
        }
        return nil
    }

    func show(on view: UIView) {
        view.viewWithTag(selfTag)?.removeFromSuperview()
        view.addSubview(self)
        set(.fillSuperView(view))
    }

    @objc private func buttonTapped(button: CustomButton) {
        // Perform additional actions here
        button.model?.onTap(self)
        hideSheet()
    }

    private func hideSheet() {
        isHidden = true
        onHide?(self)
    }

    class CustomButton: UIButton {
        var model: (any BottomSheetModelProtocol)?
    }

    private func getTitleView(title: String, needLine: Bool = true) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let title = RtkUIUtility.createLabel(text: title, alignment: .center)
        view.addSubview(title)
        title.font = UIFont.systemFont(ofSize: 16)
        title.set(.sameLeadingTrailing(view), .sameTopBottom(view, tokenSpace.space4))
        if needLine {
            let lineView = UIView()
            view.addSubview(lineView)
            lineView.set(.leading(view),
                         .trailing(view, tokenSpace.space4),
                         .height(1),
                         .bottom(view))
            lineView.backgroundColor = backgroundColorValueForLineSeparator
        }
        return view
    }

    private func getMenuButton(title: String, systemImage: RtkImage, needLine: Bool = true, unreadCount: String = "") -> (baseView: UIView, button: CustomButton, notificationMessageView: UnreadCountView) {
        let color = DesignLibrary.shared.color.textColor.onBackground.shade900
        let view = UIView()
        view.isUserInteractionEnabled = false
        let imageView = RtkUIUtility.createImageView(image: systemImage)
        imageView.tintColor = color
        let baseImageView = UIView()
        baseImageView.addSubview(imageView)

        imageView.set(.centerView(baseImageView),
                      .top(baseImageView, 0.0, .greaterThanOrEqual),
                      .leading(baseImageView, 0.0, .greaterThanOrEqual))
        let title = RtkUIUtility.createLabel(text: title, alignment: .left)
        title.textColor = color
        view.addSubview(baseImageView)
        view.addSubview(title)
        baseImageView.set(.sameTopBottom(view, tokenSpace.space2), .leading(view), .width(30))
        title.set(.after(baseImageView, tokenSpace.space2), .centerY(baseImageView))

        let unreadCountView = UnreadCountView()
        view.addSubview(unreadCountView)
        unreadCountView.set(.after(title, tokenSpace.space2, .greaterThanOrEqual),
                            .trailing(view, tokenSpace.space2),
                            .centerY(title),
                            .height(tokenSpace.space5),
                            .width(tokenSpace.space5, .greaterThanOrEqual))
        unreadCountView.layer.cornerRadius = tokenSpace.space5 / 2.0
        unreadCountView.layer.masksToBounds = true
        unreadCountView.set(unReadCount: unreadCount)

        let viewBase = UIView()
        let fixedHeightView = UIView()
        viewBase.addSubview(fixedHeightView)
        fixedHeightView.set(.fillSuperView(viewBase),
                            .height(50))

        let button = CustomButton()
        viewBase.addSubview(button)
        button.set(.fillSuperView(viewBase))
        fixedHeightView.addSubview(view)

        view.set(.top(fixedHeightView, 0.0, .greaterThanOrEqual),
                 .centerY(fixedHeightView),
                 .leading(fixedHeightView),
                 .trailing(fixedHeightView, tokenSpace.space4, .greaterThanOrEqual))
        if needLine {
            let lineView = UIView()
            viewBase.addSubview(lineView)
            lineView.set(.leading(viewBase),
                         .trailing(viewBase, tokenSpace.space4),
                         .height(1),
                         .bottom(viewBase))
            lineView.backgroundColor = backgroundColorValueForLineSeparator
        }
        return (viewBase, button, unreadCountView)
    }
}

public class RtkMoreMenu: UIView {
    struct BottomSheetModel: BottomSheetModelProtocol {
        var unreadCount: String = ""

        var type: MenuType

        var image: RtkImage

        var title: String

        var onTap: (BottomSheet) -> Void
    }

    var bottomSheet: BottomSheet!
    let selfTag = 89372
    private var features: [MenuType]
    private var onSelect: (MenuType) -> Void
    private var title: String?
    public init(title: String? = nil, features: [MenuType], onSelect: @escaping (MenuType) -> Void) {
        self.onSelect = onSelect
        self.title = title
        self.features = features
        super.init(frame: .zero)
        bottomSheet = BottomSheet()
        bottomSheet.onHide = { [weak self] _ in
            guard let self else { return }
            hideSheet()
        }
        reload(title: title, features: features)
        tag = selfTag
    }

    func reload(title: String? = nil, features: [MenuType]) {
        self.features = features
        let model = getModel(features: features)
        bottomSheet.reload(title: title, features: model)
        for i in 0 ..< features.count {
            let menu = features[i]
            // Setting accessIdentifier for Maestro Testing
            bottomSheet.options[i].accessibilityIdentifier = menu.getAccessIdentifier()
        }
    }

    private func getModel(features: [MenuType]) -> [BottomSheetModel] {
        var model = [BottomSheetModel]()
        for feature in features {
            switch feature {
            case .files:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_attach")), title: "File", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .images:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_image")), title: "Image", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .muteAllAudio:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mute All Audio", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .muteAllVideo:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Mute All Video", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .shareMeetingUrl:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_chat_send")), title: "Share meeting", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case let .poll(notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_polls")), title: "Polls", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .unPin:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_unpin")), title: "Unpin", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .startScreenShare:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_start_screenshare")), title: "Screen Share", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .stopScreenShare:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stop_screenshare")), title: "Stop screen share", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .muteAudio:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mute", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .pin:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_pin")), title: "Pin", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .allowToJoinStage:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Allow to join Stage", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .denyToJoinStage:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Revoke to join Stage", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .removeFromStage:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stage_leave")), title: "Remove from Stage", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .muteVideo:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Turn off video", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .kick:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_kick")), title: "Kick", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case let .chat(notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_chat")), title: "Chat", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .plugins:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_plugin")), title: "Plugin", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .settings:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_setting")), title: "Settings", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .recordingStart:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_recording_start")), title: "Record", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .recordingStop:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_recording_stop")), title: "Stop", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case let .participants(notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_participants")), title: "Participants", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            case .cancel:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_cross")), title: "Cancel", onTap: { [weak self] _ in
                    guard let self else { return }
                    onSelect(feature)
                    hideSheet()
                }))
            }
        }
        return model
    }

    public func show(on view: UIView) {
        view.viewWithTag(selfTag)?.removeFromSuperview()
        view.addSubview(self)
        set(.fillSuperView(view))
        bottomSheet.show(on: self)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func hideSheet() {
        isHidden = true
    }
}
