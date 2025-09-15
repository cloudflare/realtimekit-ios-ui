//
//  RtkCreatePollsViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 12/01/23.
//

import RealtimeKit
import UIKit

class RadioTypeImage {
    var selectedImage: RtkImage
    var normalImage: RtkImage
    init(selectedImage: RtkImage, normalImage: RtkImage) {
        self.selectedImage = selectedImage
        self.normalImage = normalImage
    }
}

class AutoSizingTextView: UIView {
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
    let backGroundColor = DesignLibrary.shared.color.background.shade700
    let textColor = DesignLibrary.shared.color.textColor.onBackground.shade600

    let textView: UITextView = .init()

    let maxHeight: CGFloat

    let minimumHeight: CGFloat

    private var isMaxHeightConstraintSet = false
    private var placeHolderLabel: UILabel!

    var maxHeightAchieved: Bool = false {
        didSet {
            if maxHeightAchieved == true {
                if isMaxHeightConstraintSet == false {
                    isMaxHeightConstraintSet = true
                    if let heightConstraint = textView.get(.height) {
                        textView.removeConstraint(heightConstraint)
                    }
                    textView.set(.height(textView.intrinsicContentSize.height))
                    textView.isScrollEnabled = true
                }
            } else {
                textView.isScrollEnabled = false
                isMaxHeightConstraintSet = false
                if let heightConstraint = textView.get(.height) {
                    textView.removeConstraint(heightConstraint)
                }

                textView.set(.height(max(minimumHeight, textView.intrinsicContentSize.height)))
            }
        }
    }

    init(maxheight height: CGFloat, minHeight: CGFloat = 40, placeHolderText: String = "Enter some text...") {
        maxHeight = height
        minimumHeight = minHeight
        super.init(frame: .zero)
        createSubView(placeHolderText: placeHolderText)
    }

    func createSubView(placeHolderText: String) {
        addSubview(textView)
        textView.set(.fillSuperView(self), .height(minimumHeight))
        textView.delegate = self
        textView.textColor = textColor
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 12)
        placeHolderLabel = createPlaceholderLabel(text: placeHolderText)
        textView.addSubview(placeHolderLabel)
        placeHolderLabel.set(.sameLeadingTrailing(textView, 5),
                             .top(textView, (textView.font?.pointSize)! / 2))
        placeHolderLabel.isHidden = !textView.text.isEmpty
        textView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                  radius: borderRadiusType)
        textView.backgroundColor = backGroundColor
    }

    func setPlaceHolder(text: String) {
        placeHolderLabel.text = text
    }

    func createPlaceholderLabel(text: String) -> UILabel {
        let placeholderLabel = UILabel()
        placeholderLabel.text = text
        placeholderLabel.sizeToFit()
        placeholderLabel.textColor = textColor
        return placeholderLabel
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AutoSizingTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
        if textView.contentSize.height >= maxHeight {
            maxHeightAchieved = true
        } else {
            maxHeightAchieved = false
        }
    }
}

class AutoSizingTitleTextView: BaseMoluculeView {
    let gapBetweenTitleAndTextView: CGFloat = 8

    let lblHeader: RtkLabel = RtkUIUtility.createLabel(text: "", alignment: .left, weight: UIFont.Weight.bold)
    let textView: AutoSizingTextView
    let lblError: RtkLabel = RtkUIUtility.createLabel(text: "", alignment: .left)

    init(headerTitle: String, placeHolderText: String) {
        textView = AutoSizingTextView(maxheight: 100, minHeight: 68, placeHolderText: placeHolderText)
        super.init(frame: .zero)
        createSubviews()
        lblHeader.text = headerTitle
        textView.setPlaceHolder(text: placeHolderText)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createSubviews() {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: gapBetweenTitleAndTextView)
        addSubview(stackView)
        stackView.set(.fillSuperView(self))
        stackView.addArrangedSubviews(lblHeader, textView, lblError)
        lblError.isHidden = true
    }
}

class AddOptions: BaseMoluculeView {
    let btnAdd: RtkButton = {
        let button = RtkButton(style: .line, rtkButtonState: .active)
        button.setTitle("Add Options", for: .normal)
        return button
    }()

    private var textFields = [TextFieldBaseView]()
    let verticalGap: CGFloat = DesignLibrary.shared.space.space2
    let minimumOptionsToBeShown = 2
    let emptyTextFieldError = "Please insert voting option text"
    let tokenSpace = DesignLibrary.shared.space
    var textFiledCount = 0

    let lblErrorColor = DesignLibrary.shared.color.status.danger
    let textFieldBackgroundColorToken = DesignLibrary.shared.color.background.shade700
    let textFieldBorderColorToken =
        DesignLibrary.shared.color.background.shade700

    let stackView: UIStackView

    init() {
        stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: verticalGap)
        super.init(frame: .zero)
        createSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createSubviews() {
        addSubview(stackView)
        addSubview(btnAdd)
        stackView.set(.top(self),
                      .sameLeadingTrailing(self))
        btnAdd.set(.below(stackView, verticalGap),
                   .sameLeadingTrailing(self),
                   .bottom(self))
        btnAdd.addTarget(self, action: #selector(addButtonClick(sender:)), for: .touchUpInside)
        atoms.append(btnAdd)

        var heading: String?
        for i in 0 ..< minimumOptionsToBeShown {
            textFiledCount += 1
            heading = nil
            if i == 0 {
                heading = "Options"
            }
            let textFieldBase = addAndSetTextField(heading: heading, placeHolderText: "Option \(textFiledCount)", needRemoveButton: false)
            stackView.addArrangedSubview(textFieldBase)
            textFieldBase.removeButton?.setClickAction(click: { [weak self, unowned textFieldBase] _ in
                guard let self else { return }
                stackView.removeFully(view: textFieldBase)
                if let index = textFields.firstIndex(of: textFieldBase) {
                    textFields.remove(at: index)
                    textFiledCount -= 1
                }
            })
        }
    }

    @objc func addButtonClick(sender _: RtkButton) {
        if checkAndShowError() {
            return
        }
        textFiledCount += 1
        let textFieldBase = addAndSetTextField(heading: nil, placeHolderText: "Option \(textFiledCount)", needRemoveButton: true)
        stackView.addArrangedSubview(textFieldBase)
        textFieldBase.removeButton?.setClickAction(click: { [weak self, unowned textFieldBase] _ in
            guard let self else { return }
            stackView.removeFully(view: textFieldBase)
            if let index = textFields.firstIndex(of: textFieldBase) {
                textFields.remove(at: index)
                textFiledCount -= 1
            }
        })
    }

    private func addAndSetTextField(heading: String?, placeHolderText: String, needRemoveButton: Bool) -> TextFieldBaseView {
        let result = addTextField(heading: heading, text: "", needRemoveButton: needRemoveButton)
        let textField = result.textField
        textField.lblError.font = UIFont.systemFont(ofSize: 12)
        textField.lblError.textColor = lblErrorColor
        textField.setPlaceHolder(text: placeHolderText)
        textField.delegate = self
        textFields.append(result)
        atoms.append(textField)
        return result
    }

    private func checkAndShowError() -> Bool {
        for textFieldBase in textFields {
            let textField = textFieldBase.textField
            let isEmpty = textField.text?.isEmpty ?? true
            if isEmpty {
                textField.populateError(text: emptyTextFieldError)
                textField.lblError.alpha = 0.2
                UIView.animate(withDuration: 0.2) {
                    textField.lblError.alpha = 1.0
                }
                return true
            } else {
                textField.populateError()
            }
        }
        return false
    }

    func getText(index: Int) -> String? {
        if index < 0, index >= textFields.count {
            return nil
        }
        return textFields[index].textField.text
    }

    func getAllOptions() -> [String] {
        var result = [String]()
        for textField in textFields {
            if let text = textField.textField.text, text.isEmpty == false {
                result.append(text)
            }
        }
        return result
    }

    class TextFieldBaseView: UIView {
        let textField: RtkTextField
        let removeButton: RtkButton?
        init(textField: RtkTextField, removeButton: RtkButton?) {
            self.textField = textField
            self.removeButton = removeButton
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private func addTextField(heading: String?, text: String, needRemoveButton: Bool) -> TextFieldBaseView {
        let baseView = UIView()
        let textField = RtkTextField(textFieldBackgroundColorToken: textFieldBackgroundColorToken, borderColor: textFieldBorderColorToken.cgColor)
        textField.errorLabelValidation = { [weak self] (text: String?, textField: RtkTextField) in
            guard let self else { return }
            if let text, text.count >= 1 {
                textField.populateError()
            } else {
                textField.populateError(text: emptyTextFieldError)
            }
        }
        textField.text = text
        textField.populateText(headerText: heading)
        baseView.addSubview(textField)

        textField.set(.sameTopBottom(baseView))
        var removalButton: RtkButton? = nil
        if needRemoveButton {
            let buttonToRemove = RtkButton(style: .line, size: .small)
            buttonToRemove.setTitle(" - ", for: .normal)
            baseView.addSubview(buttonToRemove)
            textField.set(.leading(baseView))
            buttonToRemove.set(.centerY(textField),
                               .top(baseView, tokenSpace.space0, .greaterThanOrEqual),
                               .after(textField, tokenSpace.space2),
                               .trailing(baseView))
            buttonToRemove.setClickAction { [weak self, unowned baseView] _ in
                guard let self else { return }
                stackView.removeFully(view: baseView)
            }
            removalButton = buttonToRemove
        } else {
            textField.set(.sameLeadingTrailing(baseView))
        }
        let textFieldBase = TextFieldBaseView(textField: textField, removeButton: removalButton)
        textFieldBase.addSubview(baseView)
        baseView.set(.fillSuperView(textFieldBase))
        return textFieldBase
    }
}

extension AddOptions: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        endEditing(true)
        return false
    }
}

class SelectionView: UIView {
    let spaceToken = DesignLibrary.shared.space
    let imageView: BaseImageView = .init()
    let title: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        return label
    }()

    private let radioImage: RadioTypeImage
    var index: Int = 0
    private var clickAction: (SelectionView) -> Void

    init(radioImage: RadioTypeImage, title: String, onClick: @escaping (SelectionView) -> Void) {
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
        addSubview(title)
        imageView.set(.leading(self),
                      .top(self, 0.0, .greaterThanOrEqual),
                      .bottom(self, 0.0, .greaterThanOrEqual),
                      .centerY(title))
        title.set(.after(imageView, spaceToken.space2),
                  .top(self, 0.0, .greaterThanOrEqual),
                  .centerY(self),
                  .trailing(self, 0.0, .greaterThanOrEqual))
    }

    var isSelected: Bool = false {
        didSet {
            setSelected(selected: isSelected)
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

protocol SelectionModel {
    var image: RadioTypeImage { get }
    var title: String { get }
    var isSelected: Bool { get }
}

enum VotePermissionType {
    case anonymous
    case hideResultBeforeVoting
}

class ListSelectionModel: SelectionModel {
    let image: RadioTypeImage
    let title: String
    let permission: VotePermissionType
    let isSelected: Bool
    init(image: RadioTypeImage, title: String, permission: VotePermissionType, isSelected: Bool) {
        self.image = image
        self.title = title
        self.permission = permission
        self.isSelected = isSelected
    }
}

enum SelectionType {
    case radio
    case multiple
}

class ListSelectionView<Model: SelectionModel>: UIView {
    let spaceToken = DesignLibrary.shared.space
    let models: [Model]
    let titleLabel: RtkLabel = RtkUIUtility.createLabel(alignment: .left, weight: UIFont.Weight.bold)
    let selectionType: SelectionType

    private let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 4)
    private let stackViewSelectionView = RtkUIUtility.createStackView(axis: .vertical, spacing: 4)

    private var arrSelectionView = [SelectionView]()

    init(models: [Model], title: String, selectionType: SelectionType = .multiple) {
        self.models = models
        self.selectionType = selectionType
        super.init(frame: .zero)
        titleLabel.text = title
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
        stackView.addArrangedSubviews(titleLabel, stackViewSelectionView)
    }

    private func createListView(on stackView: UIStackView) -> [SelectionView] {
        var arrResult = [SelectionView]()
        var index = 0
        for model in models {
            let view = get(image: model.image, title: model.title, isSelected: model.isSelected)
            view.index = index
            stackView.addArrangedSubview(view)
            arrResult.append(view)
            index += 1
        }
        return arrResult
    }

    private func get(image: RadioTypeImage, title: String, isSelected: Bool) -> SelectionView {
        let view = SelectionView(radioImage: image, title: title) { [weak self] selectionView in
            guard let self else { return }
            if selectionType == .radio {
                selectView(at: selectionView.index)

            } else {
                selectionView.isSelected = !selectionView.isSelected
            }
        }
        view.isSelected = isSelected
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

    func getCurrentSelectedIndex() -> [Int]? {
        var index = 0
        var result = [Int]()
        for view in arrSelectionView {
            if view.isSelected == true {
                result.append(index)
            }
            index += 1
        }
        return result.count > 0 ? result : nil
    }
}

class CreatePollView: UIView {
    let space = DesignLibrary.shared.space

    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeCreateView ?? .rounded

    let backGroundColor = DesignLibrary.shared.color.background.shade900

    let verticalSpacingBetweenElements = DesignLibrary.shared.space.space4

    let lblHeader: RtkLabel = {
        let label = RtkUIUtility.createLabel(text: "Create Poll", alignment: .left)
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.bold)
        return label
    }()

    let askQuestionTextView: AutoSizingTitleTextView = {
        let textView = AutoSizingTitleTextView(headerTitle: "Question", placeHolderText: "Ask a question")
        textView.lblError.text = "Please insert valid question to be asked in poll"
        textView.lblError.textColor = DesignLibrary.shared.color.status.danger
        textView.lblError.font = UIFont.systemFont(ofSize: 12)
        textView.lblError.accessibilityIdentifier = "CreatePoll_Title_TextView_Error_Label"
        textView.accessibilityIdentifier = "CreatePoll_Title_TextView"
        return textView
    }()

    let addOptionView: AddOptions = .init()

    let permissionSelectionView: ListSelectionView = {
        let selectedImage = RtkImage(image: ImageProvider.image(named: "icon_radiobutton_selected"))
        let unSelectedImage = RtkImage(image: ImageProvider.image(named: "icon_radiobutton_unselected"))
        var model = [ListSelectionModel]()

        model.append(ListSelectionModel(image: RadioTypeImage(selectedImage: selectedImage, normalImage: unSelectedImage), title: "Anonymous", permission: .anonymous, isSelected: false))
        model.append(ListSelectionModel(image: RadioTypeImage(selectedImage: selectedImage, normalImage: unSelectedImage), title: "Hide result before voting", permission: .hideResultBeforeVoting, isSelected: true))
        let selectionView = ListSelectionView(models: model, title: "Show Result")
        return selectionView
    }()

    var question: String? {
        askQuestionTextView.textView.textView.text
    }

    let btnCancel: RtkButton = {
        let button = RtkButton(style: .text, size: .medium)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(DesignLibrary.shared.color.status.danger, for: .normal)
        button.accessibilityIdentifier = "CreatePoll_Cancel_Button"
        return button
    }()

    let btnPublish: RtkButton = {
        let button = RtkButton(style: .solid, size: .medium)
        button.setTitle("  Publish  ", for: .normal)
        button.accessibilityIdentifier = "CreatePoll_Publish_Button"
        return button
    }()

    let baseView = UIView()

    init() {
        super.init(frame: .zero)
        addSubview(baseView)
        baseView.set(.fillSuperView(self, space.space4))
        createSubView(on: baseView)
        backgroundColor = backGroundColor
        layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createSubView(on view: UIView) {
        view.addSubview(lblHeader)
        view.addSubview(askQuestionTextView)
        view.addSubview(addOptionView)
        view.addSubview(permissionSelectionView)
        view.addSubview(btnCancel)
        view.addSubview(btnPublish)

        lblHeader.set(.sameLeadingTrailing(view),
                      .top(view))
        askQuestionTextView.set(.sameLeadingTrailing(view),
                                .below(lblHeader, verticalSpacingBetweenElements))
        addOptionView.set(.sameLeadingTrailing(view),
                          .below(askQuestionTextView, verticalSpacingBetweenElements))
        permissionSelectionView.set(.below(addOptionView, verticalSpacingBetweenElements * 2),
                                    .sameLeadingTrailing(view))
        btnPublish.set(.bottom(view),
                       .trailing(view),
                       .below(permissionSelectionView, verticalSpacingBetweenElements))
        btnCancel.set(.leading(view),
                      .centerY(btnPublish))
    }
}

enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}

public class RtkCreatePollsViewController: UIViewController, KeyboardObservable {
    let scrollView: UIScrollView = .init()
    var keyboardObserver: KeyboardObserver?
    let rtkClient: RealtimeKitClient
    let completion: (Result<Bool, Error>) -> Void
    let tokenSpace = DesignLibrary.shared.space
    private var createPollView: CreatePollView!

    init(rtkClient: RealtimeKitClient, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.rtkClient = rtkClient
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.rtkClient.addPollsEventListener(pollsEventListener: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "Create_Polls_Screen"
        setUpView()
    }

    private func setUpView() {
        createSubView(on: view)
        setupKeyboard()
    }

    private func createSubView(on view: UIView) {
        view.addSubview(scrollView)
        let createPollView = CreatePollView()
        createPollView.btnPublish.addTarget(self, action: #selector(publishButtonClick(button:)), for: .touchUpInside)
        createPollView.btnCancel.addTarget(self, action: #selector(cancelButtonClick(button:)), for: .touchUpInside)

        scrollView.addSubview(createPollView)
        createPollView.set(.fillSuperView(scrollView))
        scrollView.set(.leading(view, tokenSpace.space3),
                       .top(view, tokenSpace.space4),
                       .trailing(view, tokenSpace.space3),
                       .bottom(view),
                       .equateAttribute(.width, toView: createPollView, toAttribute: .width, withRelation: .equal))
        self.createPollView = createPollView
    }

    var createdByMe = false
    @objc func publishButtonClick(button: RtkButton) {
        let addOptionView = createPollView.addOptionView
        let allOptions = addOptionView.getAllOptions()
        if let question = createPollView.question, question.count > 2 {
            createPollView.askQuestionTextView.lblError.isHidden = true
            if allOptions.count >= addOptionView.minimumOptionsToBeShown {
                button.showActivityIndicator()

                var anonymous = false
                var hideVotes = false
                if let currentPermissionSelectedIndex = createPollView.permissionSelectionView.getCurrentSelectedIndex() {
                    for index in currentPermissionSelectedIndex {
                        let model = createPollView.permissionSelectionView.models[index]
                        if model.permission == .anonymous {
                            anonymous = true
                        } else if model.permission == .hideResultBeforeVoting {
                            hideVotes = true
                        }
                    }
                }

                rtkClient.polls.create(question: question, options: allOptions, anonymous: anonymous, hideVotes: hideVotes)
                // For now  It is  working as fire and Forget , Actually we need an event which tell us that poll created successfully or not. Or else PollMessage must have UserId of user who created this poll.
                createdByMe = true
            }
        } else {
            createPollView.askQuestionTextView.lblError.isHidden = false
        }
    }

    @objc func cancelButtonClick(button _: RtkButton) {
        rtkClient.removePollsEventListener(pollsEventListener: self)
        completion(.success(false))
    }

    private func setupKeyboard() {
        startKeyboardObserving { keyboardFrame in
            self.scrollView.get(.bottom)?.constant = -keyboardFrame.height
            // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {
            self.scrollView.get(.bottom)?.constant = 0

            // self.view.frame.origin.y = 0 // Move view to original position
        }
    }

    override public func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        view.endEditing(true)
    }
}

extension RtkCreatePollsViewController: RtkPollsEventListener {
    public func onPollUpdate(poll _: Poll) {}

    public func onNewPoll(poll _: Poll) {
        if createdByMe {
            createdByMe = false
            rtkClient.removePollsEventListener(pollsEventListener: self)
            completion(.success(true))
        }
    }

    public func onPollUpdates(pollItems _: [Poll]) {}
}
