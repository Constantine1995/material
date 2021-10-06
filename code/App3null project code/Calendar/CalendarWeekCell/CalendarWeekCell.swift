//
//  CalendarWeekCell.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 27.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class CalendarWeekCell: UITableViewCell {
    static let cellIdentifier = "CalendarWeekCell"

    private let cellView = CalendarWeekCellView()
    private var model: CalendarWeekCellModel?

    func config(model: CalendarWeekCellModel) {
        self.model = model
        cellView.largeStyle = model.largeStyle
        cellView.date = model.date

        cellView.resetDayLabels()
        model.texts.forEach {cellView.setDayLabelTitle($0.value, atIndex: $0.key)}
        model.colors.forEach {cellView.setDayLabelColor($0.value, atIndex: $0.key)}
        model.events.forEach {cellView.setDayEvent($0.value, atIndex: $0.key)}
        model.notes.forEach {cellView.setDayNote($0.value, atIndex: $0.key)}
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(cellView)
        cellView.addRoundConstraints(to: contentView)
        cellView.calendarWeekCellViewDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CalendarWeekCell: CalendarWeekCellViewDelegate {
    func buttonSelected(dayIndex: Int) {
        model?.delegate?.daySelected(onCalendarWeekCell: self, weekDate: model?.date ?? Date(), dayIndex: dayIndex, events: model?.events[dayIndex], note: model?.notes[dayIndex])
    }
}
