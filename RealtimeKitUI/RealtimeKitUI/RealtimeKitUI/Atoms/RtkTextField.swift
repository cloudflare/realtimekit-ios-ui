//
//  RtkTextField.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 06/12/22.
//

import UIKit

private class RtkCustomTextField: UITextField {
    let textInset: CGPoint

    init(insetPoint: CGPoint) {
        textInset = insetPoint
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        CGRectInset(bounds, textInset.x, textInset.y)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        CGRectInset(bounds, textInset.x, textInset.y)
    }
}

public class RtkTextField: BaseAtomView {
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
    let borderWidthType: BorderWidthToken.Width = AppTheme.shared.borderSizeWidthTypeTextField ?? .thin

    var borderColor = DesignLibrary.shared.color.brand.shade600.cgColor
    let backGroundColor: UIColor
    let textFieldTextColorToken = DesignLibrary.shared.color.textColor.onBackground.shade600

    fileprivate let textField: RtkCustomTextField = {
        let textField = RtkCustomTextField(insetPoint: CGPoint(x: 10, y: 10))

        return textField
    }()

    let lblHeader: RtkLabel = RtkUIUtility.createLabel(text: "", alignment: .left)
    let lblError: RtkLabel = RtkUIUtility.createLabel(text: "", alignment: .left)

    let verticalSpaceTopLabelAndTextField = 8.0
    let verticalSpaceErrorLabel = 4.0

    var errorLabelValidation: ((String?, RtkTextField) -> Void)?

    weak var delegate: UITextFieldDelegate? {
        get {
            textField.delegate
        }
        set(newValue) {
            textField.delegate = newValue
        }
    }

    var text: String? {
        get {
            textField.text
        }
        set(newText) {
            textField.text = newText
        }
    }

    init(textFieldBackgroundColorToken: UIColor = DesignLibrary.shared.color.background.shade900,
         borderColor: CGColor = DesignLibrary.shared.color.brand.shade600.cgColor)
    {
        backGroundColor = textFieldBackgroundColorToken
        self.borderColor = borderColor
        super.init(frame: .zero)
        createSubViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createSubViews() {
        let stackViewTextField = RtkUIUtility.createStackView(axis: .vertical, spacing: verticalSpaceTopLabelAndTextField)
        stackViewTextField.addArrangedSubviews(lblHeader, textField)
        let stackViewTextFieldAndErrorLabel = RtkUIUtility.createStackView(axis: .vertical, spacing: verticalSpaceErrorLabel)
        stackViewTextFieldAndErrorLabel.addArrangedSubviews(stackViewTextField, lblError)
        addSubview(stackViewTextFieldAndErrorLabel)
        stackViewTextFieldAndErrorLabel.set(.fillSuperView(self))

        textField.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                   radius: borderRadiusType)
        textField.layer.borderWidth = DesignLibrary.shared.borderSize.getWidth(size: .one,
                                                                               width: borderWidthType)
        textField.layer.borderColor = borderColor
        textField.backgroundColor = backGroundColor
        textField.textColor = textFieldTextColorToken
        lblHeader.isHidden = lblHeader.text?.isEmpty ?? true
        lblError.isHidden = lblError.text?.isEmpty ?? true
        textField.addTarget(self, action: #selector(textChanged(textField:)), for: .editingChanged)
    }

    @objc func textChanged(textField: UITextField) {
        errorLabelValidation?(textField.text, self)
    }

    func populateText(headerText: String? = nil, error: String? = nil) {
        populateHeader(text: headerText)
        populateHeader(text: error)
    }

    func populateHeader(text: String? = nil) {
        lblHeader.setTextWhenInsideStackView(text: text)
    }

    func populateError(text: String? = nil) {
        lblError.setTextWhenInsideStackView(text: text)
    }

    func setPlaceHolder(text: String) {
        textField.attributedPlaceholder = NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.foregroundColor: textFieldTextColorToken],
        )
    }

    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        textField.addTarget(target, action: action, for: controlEvents)
    }
}
