//
//  RtkShowPollsViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/01/23.
//

import RealtimeKit
import UIKit

class SelectionProgressView: UIView {
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded

    let spaceToken = DesignLibrary.shared.space
    let imageView: BaseImageView = {
        let imageView = BaseImageView()
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView

    }()

    let title: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let progressTitle: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .right)
        label.font = UIFont.systemFont(ofSize: 12)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private var progressBaseView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignLibrary.shared.color.background.shade600
        return view
    }()

    private var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignLibrary.shared.color.brand.shade500
        return view
    }()

    private let radioImage: RadioTypeImage
    var index: Int = 0
    private var clickAction: (SelectionProgressView) -> Void

    init(radioImage: RadioTypeImage, title: String, onClick: @escaping (SelectionProgressView) -> Void) {
        self.radioImage = radioImage
        self.title.text = title
        clickAction = onClick
        super.init(frame: .zero)
        createSubView()
        setSelected(selected: false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createSubView() {
        addSubview(imageView)
        addSubview(progressBaseView)

        progressBaseView.addSubview(progressView)
        progressBaseView.addSubview(title)
        progressBaseView.addSubview(progressTitle)
        progressBaseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        progressBaseView.layer.masksToBounds = true

        imageView.set(.leading(self),
                      .top(self, 0.0, .greaterThanOrEqual),
                      .centerY(self))

        progressBaseView.set(.after(imageView, spaceToken.space2),
                             .sameTopBottom(self),
                             .trailing(self))
        progressView.set(.sameTopBottom(progressBaseView),
                         .leading(progressBaseView),
                         .width(0),
                         .trailing(progressBaseView, 0.0, .greaterThanOrEqual))
        title.set(.sameTopBottom(progressBaseView, spaceToken.space2),
                  .leading(progressBaseView, spaceToken.space2))
        progressTitle.set(.centerY(title),
                          .top(progressBaseView, 0.0, .greaterThanOrEqual),
                          .after(title, spaceToken.space2, .greaterThanOrEqual),
                          .trailing(progressBaseView, spaceToken.space2))
    }

    var isSelected: Bool = false {
        didSet {
            setSelected(selected: isSelected)
        }
    }

    func setProgressTitle(text: String?) {
        progressTitle.text = text
    }

    func showProgress(percentage: CGFloat) {
        if percentage >= 0, percentage <= 1 {
            let width = progressBaseView.frame.width * percentage
            progressView.get(.width)?.constant = width
        }
    }

    private func setSelected(selected: Bool) {
        if selected == true {
            imageView.setImage(image: radioImage.selectedImage)
        } else {
            imageView.setImage(image: radioImage.normalImage)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        clickAction(self)
    }
}

class PollCardModel {
    let posterName: String
    let createdAt: String?
    let poll: ListProgressSelectionViewModel
    let leftButton: RtkButton?
    let rightButton: RtkButton?
    let pollMessage: Poll
    init(posterName: String, createdAt: String?, poll: ListProgressSelectionViewModel, leftButton: RtkButton?, rightButton: RtkButton?, pollMessage: Poll) {
        self.posterName = posterName
        self.createdAt = createdAt
        self.poll = poll
        self.pollMessage = pollMessage
        self.leftButton = leftButton
        self.rightButton = rightButton
    }
}

class ListProgressSelectionViewModel {
    let title: String?
    let leftSubTitle: String?
    let rightSubTitle: String?
    let list: [(image: RadioTypeImage, title: String, rightTitle: String?, isSelected: Bool)]
    let isTouchable: Bool
    init(title: String?, leftSubTitle: String?, rightSubTitle: String?, selectionList: [(image: RadioTypeImage, title: String, rightTitle: String?, isSelected: Bool)], isTouchable: Bool) {
        self.title = title
        self.leftSubTitle = leftSubTitle
        self.rightSubTitle = rightSubTitle
        list = selectionList
        self.isTouchable = isTouchable
    }
}

class ListProgressSelectionView: UIView {
    let spaceToken = DesignLibrary.shared.space
    private let model: ListProgressSelectionViewModel

    var onSelectView: ((Int) -> Void)?

    let titleLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    let leftSubTitleLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let rightSubTitleLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private let stackView: UIStackView
    private let stackViewSubtitle: UIStackView

    private let stackViewSelectionView: UIStackView

    private var arrSelectionView = [SelectionProgressView]()

    init(model: ListProgressSelectionViewModel) {
        self.model = model
        stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space4)
        stackViewSubtitle = RtkUIUtility.createStackView(axis: .horizontal, spacing: spaceToken.space2)
        stackViewSelectionView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space2)

        super.init(frame: .zero)
        titleLabel.text = model.title
        leftSubTitleLabel.text = model.leftSubTitle
        rightSubTitleLabel.text = model.rightSubTitle
        isUserInteractionEnabled = model.isTouchable
        createSubView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubView() {
        addSubview(stackView)
        stackView.set(.fillSuperView(self))
        arrSelectionView = createListView(on: stackViewSelectionView)
        stackViewSubtitle.addArrangedSubviews(leftSubTitleLabel, rightSubTitleLabel)

        let stackViewSubTitleSelectionView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space3)
        stackViewSubTitleSelectionView.addArrangedSubviews(stackViewSubtitle, stackViewSelectionView)
        stackView.addArrangedSubviews(titleLabel, stackViewSubTitleSelectionView)
    }

    private func createListView(on stackView: UIStackView) -> [SelectionProgressView] {
        var arrResult = [SelectionProgressView]()
        var index = 0
        for model in model.list {
            let view = get(image: model.image, title: model.title, rightTitle: model.rightTitle, isSelected: model.isSelected)
            view.index = index
            stackView.addArrangedSubview(view)
            arrResult.append(view)
            index += 1
        }
        return arrResult
    }

    private func get(image: RadioTypeImage, title: String, rightTitle: String?, isSelected: Bool) -> SelectionProgressView {
        let view = SelectionProgressView(radioImage: image, title: title) { [weak self] selectionView in
            guard let self else { return }
            selectView(at: selectionView.index)
            onSelectView?(selectionView.index)
        }
        view.isSelected = isSelected
        view.setProgressTitle(text: rightTitle)
        return view
    }

    private func selectView(at index: Int) {
        var key = 0
        for view in arrSelectionView {
            if key == index {
                view.isSelected = true
            } else {
                view.isSelected = false
            }
            key += 1
        }
    }

    func getCurrentSelectedIndex() -> Int? {
        var index = 0
        for view in arrSelectionView {
            if view.isSelected == true {
                return index
            }
            index += 1
        }
        return nil
    }
}

class ShowPolls: UIView {
    let spaceToken = DesignLibrary.shared.space
    let imageView: BaseImageView = .init()

    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeCreateView ?? .rounded

    let backGroundColor = DesignLibrary.shared.color.background.shade900

    let lblTitle: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()

    let lblTime: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let baseView = UIView()
    let separatorView = {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()

    let bottomLeftButton: UIButton?
    let bottomRightButton: UIButton?

    let listSelectionView: ListProgressSelectionView

    init(leftTitle: String, rightTitle: String?, bottomLeftButton: UIButton?, bottomRightButton: UIButton?, listSelectionView: ListProgressSelectionView) {
        self.bottomLeftButton = bottomLeftButton
        self.bottomRightButton = bottomRightButton
        self.listSelectionView = listSelectionView
        super.init(frame: .zero)
        lblTitle.text = leftTitle
        lblTime.text = rightTitle
        setUpView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpView() {
        createSubView()
        baseView.backgroundColor = backGroundColor
        baseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        baseView.layer.masksToBounds = true
    }

    private func createSubView() {
        addSubview(lblTitle)
        addSubview(lblTime)
        addSubview(baseView)

        baseView.addSubview(listSelectionView)
        baseView.addSubview(separatorView)

        baseView.layer.cornerRadius = 8.0
        baseView.clipsToBounds = true
        baseView.layer.masksToBounds = true

        lblTitle.set(.top(self),
                     .leading(self))
        lblTime.set(.centerY(lblTitle),
                    .after(lblTitle, spaceToken.space4),
                    .trailing(self, 0.0, .greaterThanOrEqual))
        baseView.set(.below(lblTitle, spaceToken.space2),
                     .sameLeadingTrailing(self), .bottom(self))
        listSelectionView.set(.top(baseView, spaceToken.space4),
                              .sameLeadingTrailing(baseView, spaceToken.space4))

        separatorView.set(.below(listSelectionView, spaceToken.space4),
                          .sameLeadingTrailing(baseView),
                          .height(1))
        createBottomButtonView()
    }

    private func createBottomButtonView() {
        let buttonBaseView = UIView()
        baseView.addSubview(buttonBaseView)
        buttonBaseView.set(.below(separatorView),
                           .sameLeadingTrailing(baseView),
                           .bottom(baseView))
        if bottomLeftButton != nil || bottomRightButton != nil {
            if let button = bottomLeftButton {
                buttonBaseView.addSubview(button)
                button.set(.sameTopBottom(buttonBaseView, spaceToken.space4, .greaterThanOrEqual),
                           .leading(buttonBaseView, spaceToken.space4))
            }
            if let button = bottomRightButton {
                buttonBaseView.addSubview(button)
                button.set(.top(buttonBaseView, spaceToken.space4, .greaterThanOrEqual),
                           .bottom(buttonBaseView, spaceToken.space4),
                           .trailing(buttonBaseView, spaceToken.space4))
            }
        } else {
            separatorView.get(.height)?.constant = 0.0
        }
    }
}

class ShowPollsViewModel {
    let rtkClient: RealtimeKitClient
    var refreshPolls: (([PollCardModel], Bool) -> Void)?

    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.rtkClient.addPollsEventListener(pollsEventListener: self)
    }

    var canShowCreateButton: Bool {
        rtkClient.localUser.permissions.polls.canCreate
    }

    func refresh(onNewCreated: Bool = false) {
        let polls = rtkClient.polls
        let cardModels = parse(polls: polls.items)
        refreshPolls?(cardModels, onNewCreated)
    }

    func parse(polls: [Poll]) -> [PollCardModel] {
        var result = [PollCardModel]()
        let userId = rtkClient.localUser.userId
        let selectedImage = RtkImage(image: ImageProvider.image(named: "icon_radiobutton_selected"))
        let unSelectedImage = RtkImage(image: ImageProvider.image(named: "icon_radiobutton_unselected"))

        for poll in polls {
            var model = [(image: RadioTypeImage, title: String, rightTitle: String?, isSelected: Bool)]()
            _ = rtkClient.participants.joined.count

            var showVoteButton = true
            for option in poll.options {
                var isVoted = false
                for votee in option.votes {
                    if votee.id == userId {
                        isVoted = true
                        showVoteButton = false
                    }
                }
                var percentageTitle: String? = nil

                if poll.hideVotes == false || isVoted {
                    percentageTitle = "(\(option.votes.count))"
                }

                model.append((image: RadioTypeImage(selectedImage: selectedImage, normalImage: unSelectedImage), title: option.text, rightTitle: percentageTitle, isSelected: isVoted))
            }
            var voteButton: RtkButton? = nil
            if showVoteButton {
                voteButton = RtkButton(style: .solid)
                voteButton!.setTitle("  Vote  ", for: .normal)
            }
            let listModel = ListProgressSelectionViewModel(title: poll.question, leftSubTitle: nil, rightSubTitle: nil, selectionList: model, isTouchable: showVoteButton)
            result.append(PollCardModel(posterName: "Poll by \(poll.createdBy)", createdAt: nil, poll: listModel, leftButton: nil, rightButton: nil, pollMessage: poll))
        }
        return result
    }
}

extension ShowPollsViewModel: RtkPollsEventListener {
    func onPollUpdate(poll _: Poll) {}

    func onNewPoll(poll _: Poll) {
        notificationDelegate?.didReceiveNotification(type: .Poll)
        refresh(onNewCreated: true)
    }

    func onPollUpdates(pollItems _: [Poll]) {
        refresh()
    }
}

public class RtkShowPollsViewController: UIViewController, @preconcurrency SetTopbar {
    public var shouldShowTopBar: Bool = true

    public let topBar: RtkNavigationBar = .init(title: "Polls")

    let scrollView: UIScrollView = .init()
    let spaceToken = DesignLibrary.shared.space
    let viewModel: ShowPollsViewModel
    let rtkClient: RealtimeKitClient

    let viewBackGroundColor = DesignLibrary.shared.color.background.shade1000
    let lblNoPollExist: RtkLabel = {
        let label = RtkUIUtility.createLabel(text: "No active polls! \n\n Let's start a new poll now by clicking Create Poll button below")
        label.numberOfLines = 0
        label.accessibilityIdentifier = "Polls_EmptyScreen_Label"
        label.isHidden = true
        return label
    }()

    let indicatorView: BaseIndicatorView = {
        let indicatorView = BaseIndicatorView.createIndicatorView()
        indicatorView.indicatorView.color = .white
        indicatorView.indicatorView.startAnimating()
        return indicatorView
    }()

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(view, view.safeAreaInsets.top))
    }

    public init(meeting: RealtimeKitClient) {
        viewModel = ShowPollsViewModel(rtkClient: meeting)
        rtkClient = meeting
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "Show_Existing_Polls_Screen"
        setUpView()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.refresh(onNewCreated: true)
    }

    private func setUpView() {
        addTopBar(dismissAnimation: true)
        createSubView(on: view)
        view.backgroundColor = viewBackGroundColor

        viewModel.refreshPolls = { [weak self] cardModels, newCreatedPoll in
            guard let self else { return }

            reloadUI(cardModels: cardModels, newlyAddedPoll: newCreatedPoll)
        }
    }

    private func reloadUI(cardModels: [PollCardModel], newlyAddedPoll: Bool) {
        let previousY = scrollView.contentOffset.y
        for subView in scrollView.subviews {
            subView.removeFromSuperview()
            subView.removeConstraints(subView.constraints)
        }
        indicatorView.isHidden = true
        lblNoPollExist.isHidden = cardModels.count > 0 ? true : false

        if cardModels.count > 0 {
            let view = createShowPollResultView(pollsModel: cardModels)
            view.accessibilityIdentifier = "Polls_View"
            scrollView.addSubview(view)
            view.set(.fillSuperView(scrollView))
            scrollView.set(.equateAttribute(.width, toView: view, toAttribute: .width, withRelation: .equal))
        }
        view.layoutIfNeeded()
        if newlyAddedPoll {
            if scrollView.contentSize.height > scrollView.frame.height {
                let y = scrollView.contentSize.height - scrollView.frame.height
                scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
            }
        } else {
            scrollView.setContentOffset(CGPoint(x: 0, y: previousY), animated: false)
        }
    }

    private func createSubView(on view: UIView) {
        view.addSubview(scrollView)
        view.addSubview(lblNoPollExist)
        view.addSubview(indicatorView)
        indicatorView.set(.centerView(view), .size(CGSize(width: 50, height: 50)))
        lblNoPollExist.set(.centerView(view), .leading(view, spaceToken.space5))

        let createButton = RtkButton(style: .solid)
        createButton.setTitle(" Create Poll ", for: .normal)
        self.view.addSubview(createButton)
        createButton.set(.centerX(self.view),
                         .leading(self.view, spaceToken.space4),
                         .bottom(self.view, spaceToken.space8))
        if viewModel.canShowCreateButton == false {
            createButton.set(.height(0))
        }
        createButton.accessibilityIdentifier = "Create_Polls_Button"
        createButton.addTarget(self, action: #selector(createPollClick(button:)), for: .touchUpInside)

        scrollView.set(.sameLeadingTrailing(view, spaceToken.space3),
                       .below(topBar, spaceToken.space2),
                       .above(createButton, spaceToken.space4))
    }

    private var creatPollController: RtkCreatePollsViewController?

    @objc func createPollClick(button _: RtkButton) {
        let controller = RtkCreatePollsViewController(rtkClient: rtkClient) { [weak self] _ in
            guard let self else { return }
            creatPollController?.view.removeFromSuperview()
            creatPollController = nil
        }
        controller.view.backgroundColor = view.backgroundColor
        view.addSubview(controller.view)
        controller.view.set(.below(topBar), .sameLeadingTrailing(view), .bottom(view))
        creatPollController = controller
    }

    func createShowPollResultView(pollsModel: [PollCardModel]) -> UIView {
        let baseView = UIView()
        var previousView: UIView? = nil
        for (index, model) in pollsModel.enumerated() {
            let view = ShowPolls(leftTitle: model.posterName, rightTitle: model.createdAt, bottomLeftButton: model.leftButton, bottomRightButton: model.rightButton, listSelectionView: ListProgressSelectionView(model: model.poll))
            view.listSelectionView.onSelectView = { [weak self, unowned view] optionIndex in
                guard let self else { return }
                // Make it untouchable so that user can't select another options.
                view.listSelectionView.isUserInteractionEnabled = false
                view.accessibilityIdentifier = "ListSelectionView_IS_Selected"
                // TODO: below method should be based on completionHandler
                rtkClient.polls.vote(pollId: model.pollMessage.id, pollOption: model.pollMessage.options[optionIndex])
            }
            baseView.addSubview(view)
            view.clipsToBounds = true
            view.set(.sameLeadingTrailing(baseView))
            if index == 0 {
                view.set(.top(baseView))
            } else {
                view.set(.below(previousView!, spaceToken.space5))
            }
            if index == (pollsModel.count - 1) {
                view.set(.bottom(baseView, spaceToken.space4))
            }
            previousView = view
        }
        return baseView
    }
}
