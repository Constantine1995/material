//
//  IntervalDetailsCell.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class IntervalDetailsCell: UITableViewCell {

    static let cellIdentifier = "IntervalDetailsCell"
    var separatorHeight: NSLayoutConstraint?
    var item: IntervalDetailsItem?

    var largeStyle = false {
        didSet {
            titleLabel.font = UIFont(name: UIFont.TheSansBoldPlain, size: largeStyle ? 35 : 25)
            valueLabel.font = UIFont(name: UIFont.TheSansBoldPlain, size: largeStyle ? 35 : 25)
            separatorHeight?.constant = largeStyle ? Constant.Size.separatorLandscape : Constant.Size.separatorPortrait
        }
    }

    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: UIFont.TheSansBoldPlain, size: 25)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: UIFont.TheSansBoldPlain, size: 25)
        label.textColor = .systemWhite
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let placeholder = StatusMessage.placeholder.localizedDescription

    func config(for item: IntervalDetailsItem, interval: Interval, isLarge: Bool) {
        let date = Int(interval.time == 0 ? interval.startTime : interval.time).secondsToTime()
        let leftEye = interval.leftEyeDrugName ?? placeholder
        let rightEye = interval.rightEyeDrugName ?? placeholder

        largeStyle = isLarge
        self.item = item
        titleLabel.textColor = item.color

        switch item {
        case .time:
            setTitleForCell(value: date)
        case .left:
            setTitleForCell(value: leftEye)
        case .right:
            setTitleForCell(value: rightEye)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(valueLabel)
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

        addSubview(separatorView)
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        separatorHeight = separatorView.heightAnchor.constraint(equalToConstant: Constant.Size.separatorPortrait)
        separatorHeight?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setAsSelectedOrHighlighted(selectedOrHighlighted: highlighted, animated: animated)
        super.setHighlighted(highlighted, animated: animated)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setAsSelectedOrHighlighted(selectedOrHighlighted: selected, animated: animated)
        super.setSelected(selected, animated: animated)
    }

    func setAsSelectedOrHighlighted(selectedOrHighlighted: Bool, animated: Bool) {
        self.titleLabel.textColor = selectedOrHighlighted ? .systemYellow : item?.color
        self.valueLabel.textColor = selectedOrHighlighted ? .systemYellow : .systemWhite
        self.separatorView.backgroundColor = selectedOrHighlighted ? .systemYellow : .systemWhite
    }

    private func setTitleForCell(value: String) {
        let value = value.isEmpty ? placeholder : value
        titleLabel.text = item?.title ?? placeholder
        valueLabel.text = value
    }
}
