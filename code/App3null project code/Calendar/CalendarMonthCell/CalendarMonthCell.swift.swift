//
//  CalendarMonthCell.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 27.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class CalendarMonthCell: UITableViewCell {

    static let cellIdentifier = "MonthCell"
    private var model: CalendarMonthCellModel?
    private let cellView = CalendarMonthCellView()

    func config(model: CalendarMonthCellModel) {
        self.model = model
        cellView.largeStyle = model.largeStyle
        cellView.month = model.month
        cellView.year = model.year
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(cellView)
        cellView.addRoundConstraints(to: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
