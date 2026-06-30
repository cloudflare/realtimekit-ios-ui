//
//  BaseTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

open class BaseTableViewCell: UITableViewCell {
    public let cellSeparatorBottom = UIView()
    public let cellSeparatorTop = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(cellSeparatorBottom)
        contentView.addSubview(cellSeparatorTop)
        cellSeparatorTop.set(.leading(contentView, rtkSharedTokenSpace.space4),
                             .trailing(contentView),
                             .height(0.25),
                             .top(contentView))
        cellSeparatorBottom.set(.leading(contentView, rtkSharedTokenSpace.space4),
                                .trailing(contentView),
                                .height(0.25),
                                .bottom(contentView))
        cellSeparatorTop.backgroundColor = rtkSharedTokenColor.background.shade600
        cellSeparatorBottom.backgroundColor = rtkSharedTokenColor.background.shade600
        cellSeparatorTop.isHidden = true
        cellSeparatorBottom.isHidden = true
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
