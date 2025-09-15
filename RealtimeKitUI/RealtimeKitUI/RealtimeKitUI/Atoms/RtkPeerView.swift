//
//  RtkPeerView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 12/12/22.
//

import Foundation

protocol RtkPeerViewDesignDependency: BaseAppearance {
    var backgroundColor: BackgroundColorToken.Shade { get }
    var cornerRadius: BorderRadiusToken.RadiusType { get }
}

class RtkPeerViewViewModel: RtkPeerViewDesignDependency {
    var designLibrary: RtkDesignTokens
    var backgroundColor: BackgroundColorToken.Shade
    var cornerRadius: BorderRadiusToken.RadiusType = .rounded

    required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.designLibrary = designLibrary
        backgroundColor = designLibrary.color.background.video
    }
}

public class RtkPeerView: BaseView {
    private let appearance: RtkPeerViewDesignDependency

    init(frame _: CGRect, appearance: RtkPeerViewDesignDependency = RtkPeerViewViewModel()) {
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = self.appearance.backgroundColor
        layer.cornerRadius = self.appearance.designLibrary.borderRadius.getRadius(size: .two, radius: self.appearance.cornerRadius)
        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
