//
//  CalendarWeekCellView.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 27.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Timepiece
import UIKit

protocol CalendarWeekCellViewDelegate: class {
    func buttonSelected(dayIndex: Int)
}

class CalendarWeekCellView: UIView {

    weak var calendarWeekCellViewDelegate: CalendarWeekCellViewDelegate?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: dayLabels)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var dayLabels: [UILabel] = [
        dayNameLabel(tag: 0),
        dayNameLabel(tag: 1),
        dayNameLabel(tag: 2),
        dayNameLabel(tag: 3),
        dayNameLabel(tag: 4),
        dayNameLabel(tag: 5),
        dayNameLabel(tag: 6)
    ]

    private func dayNameLabel(tag: Int) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: UIFont.TheSansBoldPlain, size: 25)
        label.tag = tag
        label.isUserInteractionEnabled = true

        let button = UIButton()
        button.tag = tag
        button.addTarget(self, action: #selector(dayLabelButtonPressed(_:)), for: .touchUpInside)
        label.addSubview(button)
        button.addRoundConstraints(to: label)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var separatorHeight: NSLayoutConstraint?

    var largeStyle = false {
        didSet {
            for label in dayLabels {
                label.font = UIFont(name: UIFont.TheSansBoldPlain, size: largeStyle ? 35 : 25)
            }
            separatorHeight?.constant = largeStyle ? Constant.Size.separatorLandscape : Constant.Size.separatorPortrait
        }
    }

    func resetDayLabels() {
        for label in dayLabels {
            if label.tag >= 0, label.tag <= 4 {
                // Monday ... Friday -> light white color.
                label.textColor = .systemWhite
            } else {
                // Weekend -> gray color.
                label.textColor = .systemAppGray
            }
            label.text = ""
        }
    }

    func setDayLabelColor(_ color: UIColor, atIndex index: Int) {
        precondition(index >= 0 && index <= 6)
        let label = dayLabels[index]
        label.textColor = color
    }

    func setDayLabelTitle(_ title: String, atIndex index: Int) {
        precondition(index >= 0 && index <= 6)
        let label = dayLabels[index]
        label.text = title
    }

    func setDayEvent(_ events: [Event], atIndex index: Int) {
        precondition(index >= 0 && index <= 6)
        //let label = dayLabels[index]
        //label.text = title
        if !events.isEmpty {
            let label = dayLabels[index]
            let typesStr = events.map({$0.eventType}).compactMap({$0}).removingDuplicates()
            if let event = events.first, let eventType = EventType.init(rawValue: event.eventType ?? "") {
                label.textColor = (typesStr.count == 1) ? eventType.color : EventType.otherDates.color
            }
        }
    }

    func setDayNote(_ note: Note, atIndex index: Int) {
        precondition(index >= 0 && index <= 6)
        let label = dayLabels[index]
        label.textColor = .systemMagenta
    }

    var date = Date()

    var calendar: () -> Calendar = {
        CommonDateFormatter.calendar
    }

    init() {
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBlack
        addSubview(stackView)
        addSubview(separatorView)

        stackView.addRoundConstraints(to: self)
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        separatorHeight = separatorView.heightAnchor.constraint(equalToConstant: Constant.Size.separatorPortrait)
        separatorHeight?.isActive = true

        resetDayLabels()
    }

    @objc func dayLabelButtonPressed(_ sender: UIButton) {
        calendarWeekCellViewDelegate?.buttonSelected(dayIndex: sender.tag)
    }

}
