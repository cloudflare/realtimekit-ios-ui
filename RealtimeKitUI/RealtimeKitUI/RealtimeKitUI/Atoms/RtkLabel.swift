//
//  RtkLabel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public protocol RtkTextAppearance: BaseAppearance {
    var textColor: TextColorToken.Background.Shade { get set }
    var font: UIFont { get set }
}

public class RtkTextAppearanceModel: RtkTextAppearance {
    public var textColor: TextColorToken.Background.Shade

    public var font: UIFont

    public var designLibrary: RtkDesignTokens

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.designLibrary = designLibrary
        textColor = designLibrary.color.textColor.onBackground.shade1000
        font = UIFont.systemFont(ofSize: 16)
    }
}

public class RtkLabel: UILabel {
    public init(appearance: RtkTextAppearance = RtkTextAppearanceModel()) {
        super.init(frame: .zero)
        textColor = appearance.textColor
        font = appearance.font
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTextWhenInsideStackView(text: String?) {
        if let text, text.count > 0 {
            isHidden = false
            self.text = text
        } else {
            isHidden = true
        }
    }
}
