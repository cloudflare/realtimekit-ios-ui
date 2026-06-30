//
//  TextColorToken.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/11/22.
//

import UIKit

public struct TextColorToken {
    public struct Background {
        public class Shade: UIColor {}

        private let base: Shade
        public let shade1000: Shade
        public let shade900: Shade
        public let shade800: Shade
        public let shade700: Shade
        public let shade600: Shade
        public let factor: CGFloat = 12.0

        init(base: Shade = Shade(hex: "#FFFFFF")!, shade1000: Shade? = nil, shade900: Shade? = nil, shade800: Shade? = nil, shade700: Shade? = nil, shade600: Shade? = nil) {
            self.base = base
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            base.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            self.shade1000 = shade1000 ?? base
            self.shade900 = shade900 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 12) / 100.0)
            self.shade800 = shade800 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 24) / 100.0)
            self.shade700 = shade700 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 36) / 100.0)
            self.shade600 = shade600 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 48) / 100.0)
        }
    }

    public struct Brand {
        public class Shade: UIColor {}

        private let base: Shade
        public let shade700: Shade
        public let shade600: Shade
        public let shade500: Shade
        public let shade400: Shade
        public let shade300: Shade
        public let factor: CGFloat = 12.0

        init(base: Shade = Shade(hex: "#111111")!, factor _: CGFloat = 12.0, shade700: Shade? = nil, shade600: Shade? = nil, shade500: Shade? = nil, shade400: Shade? = nil, shade300: Shade? = nil) {
            self.base = base
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            base.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            self.shade700 = shade700 ?? base
            self.shade600 = shade600 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 12) / 100.0)
            self.shade500 = shade500 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 24) / 100.0)
            self.shade400 = shade400 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 36) / 100.0)
            self.shade300 = shade300 ?? Shade(red: red, green: green, blue: blue, alpha: (100 - 48) / 100.0)
        }
    }

    public let onBackground: Background
    public let onBrand: Brand

    init(background: Background, brand: Brand) {
        onBackground = background
        onBrand = brand
    }
}
