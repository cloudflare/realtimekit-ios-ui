//
//  RtkDropDown.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 08/12/22.
//

import UIKit

public class RtkDropdown<Model: PickerCellModel>: UIView {
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeDropDown ?? .rounded
    let borderWidthType: BorderWidthToken.Width = AppTheme.shared.borderSizeWidthTypeDropDown ?? .thin

    let borderColor = DesignLibrary.shared.color.brand.shade600
    let backGroundColor = DesignLibrary.shared.color.background.shade700

    let spaceToken = DesignLibrary.shared.space

    fileprivate var lblTitle: RtkLabel = {
        let lbl = RtkUIUtility.createLabel(text: "", alignment: .left)
        return lbl
    }()

    let lblHeader: RtkLabel = RtkUIUtility.createLabel(text: "", alignment: .left)
    let lblError: RtkLabel = RtkUIUtility.createLabel(text: "", alignment: .left)

    let verticalSpaceTopLabelAndTextField = 8.0
    let verticalSpaceErrorLabel = 4.0

    var text: String? {
        didSet {
            lblTitle.text = text
        }
    }

    private let iconImage: RtkImage
    private let onClick: (RtkDropdown) -> Void
    let heading: String
    private var selectedIndex: Int
    var options: [Model]

    var selectedState: Bool = false

    public init(rightImage: RtkImage, heading: String, options: [Model], selectedIndex: UInt = 0, onClick: @escaping (RtkDropdown) -> Void) {
        iconImage = rightImage
        self.options = options
        self.heading = heading
        self.onClick = onClick
        self.selectedIndex = selectedIndex < options.count ? Int(exactly: selectedIndex)! : 0
        super.init(frame: .zero)
        setUpView()
    }

    func refresh(selectedIndex: UInt = 0, options: [Model]) {
        self.selectedIndex = selectedIndex < options.count ? Int(exactly: selectedIndex)! : 0
        setOptions(options: options)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        createSubViews()
        setTexts()
    }

    private func setOptions(options: [Model]) {
        self.options = options
        setTexts()
    }

    private func createSubViews() {
        let stackViewTextField = RtkUIUtility.createStackView(axis: .vertical, spacing: verticalSpaceTopLabelAndTextField)
        let lblBaseView = lblTitle.wrapperView()

        let trailingSpace = spaceToken.space9
        lblTitle.set(.fillSuperView(lblBaseView, spaceToken.space2, left: spaceToken.space3, bottom: spaceToken.space2, right: trailingSpace))

        createIconImageView(image: iconImage, width: trailingSpace, on: lblBaseView)

        stackViewTextField.addArrangedSubviews(lblHeader, lblBaseView)

        let stackViewTextFieldAndErrorLabel = RtkUIUtility.createStackView(axis: .vertical, spacing: verticalSpaceErrorLabel)
        stackViewTextFieldAndErrorLabel.addArrangedSubviews(stackViewTextField, lblError)
        addSubview(stackViewTextFieldAndErrorLabel)
        stackViewTextFieldAndErrorLabel.set(.fillSuperView(self))

        let tapButton = UIButton()
        lblBaseView.addSubview(tapButton)
        tapButton.set(.fillSuperView(lblBaseView))
        tapButton.addTarget(self, action: #selector(tapButtonClick), for: .touchUpInside)

        lblBaseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: borderRadiusType)
        lblBaseView.layer.borderWidth = DesignLibrary.shared.borderSize.getWidth(size: .one, width: borderWidthType)
        lblBaseView.layer.borderColor = borderColor.cgColor
        lblBaseView.backgroundColor = backGroundColor
        lblHeader.isHidden = lblHeader.text?.isEmpty ?? true
        lblError.isHidden = lblError.text?.isEmpty ?? true
    }

    private func setTexts() {
        lblHeader.setTextWhenInsideStackView(text: heading)
        lblTitle.setTextWhenInsideStackView(text: options[selectedIndex].name)
    }

    func selectOption(index: UInt) {
        selectedIndex = index < options.count ? Int(exactly: index)! : 0
        if options.count > 0 {
            lblTitle.setTextWhenInsideStackView(text: options[selectedIndex].name)
        }
    }

    private func createIconImageView(image: RtkImage, width: CGFloat, on view: UIView) {
        let viewBaseArrow = UIView()
        view.addSubview(viewBaseArrow)
        viewBaseArrow.set(.width(width), .trailing(view), .sameTopBottom(view))
        let iconImageView = RtkUIUtility.createImageView(image: image)
        viewBaseArrow.addSubview(iconImageView)
        iconImageView.set(.centerView(viewBaseArrow), .leading(viewBaseArrow, 0.0, .greaterThanOrEqual), .top(viewBaseArrow, 0.0, .greaterThanOrEqual))
    }

    func populate(heading: String? = nil, error: String? = nil) {
        lblHeader.setTextWhenInsideStackView(text: heading)
        lblError.setTextWhenInsideStackView(text: error)
    }

    @objc func tapButtonClick() {
        selectedState = true
        onClick(self)
    }
}
