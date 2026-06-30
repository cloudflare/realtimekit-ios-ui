//
//  RtkNotificationBadgeView.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 18/01/24.
//

import UIKit

public class RtkNotificationBadgeView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true
        addSubview(label)
        label.set(.sameTopBottom(self, 2),
                  .sameLeadingTrailing(self, 3),
                  .width(10, .greaterThanOrEqual))
    }

    public func setBadgeCount(_ count: Int) {
        if count > 99 {
            label.text = count > 0 ? "\(count)+" : nil
        } else {
            label.text = count > 0 ? "\(count)" : nil
        }
        isHidden = count <= 0
    }
}
