//
//  BackgroundColorToken.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public struct BackgroundColorToken {
    public class Shade: UIColor {}

    private let base: Shade
    public let shade1000: Shade
    public let shade900: Shade
    public let shade800: Shade
    public let shade700: Shade
    public let shade600: Shade
    public let factor: CGFloat = 12.0
    public let video: Shade

    init(base: Shade = Shade(hex: "#050505")!, shade1000: Shade? = nil, shade900: Shade? = nil, shade800: Shade? = nil, shade700: Shade? = nil, shade600: Shade? = nil, videoBackGround: Shade? = nil) {
        self.base = base
        self.shade1000 = shade1000 ?? base
        self.shade900 = shade900 ?? (base.lighter(by: factor * 1.0) ?? Shade(hex: "#252525")!)
        self.shade800 = shade800 ?? (base.lighter(by: factor * 2.0) ?? Shade(hex: "#333333")!)
        self.shade700 = shade700 ?? (base.lighter(by: factor * 3.0) ?? Shade(hex: "#4C4C4C")!)
        self.shade600 = shade600 ?? (base.lighter(by: factor * 4.0) ?? Shade(hex: "#666666")!)
        video = videoBackGround ?? self.shade800
    }
}

public struct StatusColor {
    public class Shade: UIColor {}

    public let danger: Shade
    public let success: Shade
    public let warning: Shade
    init(danger: Shade? = nil, success: Shade? = nil, warning: Shade? = nil) {
        self.danger = danger ?? Shade(hex: "#FF2D2D")!
        self.success = success ?? Shade(hex: "#83D017")!
        self.warning = warning ?? Shade(hex: "#FFCD07")!
    }
}
