//
//  ColorTokens.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public class ColorTokens {
    public let brand: BrandColorToken
    public let background: BackgroundColorToken
    public let status: StatusColor
    public let textColor: TextColorToken
    init(brand: BrandColorToken, background: BackgroundColorToken, status: StatusColor, textColor: TextColorToken) {
        self.brand = brand
        self.background = background
        self.status = status
        self.textColor = textColor
    }
}
