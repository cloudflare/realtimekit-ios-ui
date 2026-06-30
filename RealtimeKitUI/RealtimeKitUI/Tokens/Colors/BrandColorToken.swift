//
//  BrandColorToken.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public struct BrandColorToken {
    public class Shade: UIColor {}

    private let base: Shade
    public let shade700: Shade
    public let shade600: Shade
    public let shade500: Shade
    public let shade400: Shade
    public let shade300: Shade
    public let factor: CGFloat = 12.0

    init(base: Shade = Shade(hex: "#0246FD")!, factor: CGFloat = 12.0, shade700: Shade? = nil, shade600: Shade? = nil, shade500: Shade? = nil, shade400: Shade? = nil, shade300: Shade? = nil) {
        self.base = base
        self.shade700 = shade700 ?? base
        self.shade600 = shade600 ?? (base.lighter(by: factor * 1.0) ?? Shade(hex: "#0D51FD")!)
        self.shade500 = shade500 ?? (base.lighter(by: factor * 2.0) ?? Shade(hex: "#2160FD")!)
        self.shade400 = shade400 ?? (base.lighter(by: factor * 3.0) ?? Shade(hex: "#356EFD")!)
        self.shade300 = shade300 ?? (base.lighter(by: factor * 4.0) ?? Shade(hex: "#497CFD")!)
    }
}
