//
//  IntervalsCell.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class IntervalsCell: UITableViewCell {

    static let cellIdentifier = "IntervalsCell"
    var separatorHeight: NSLayoutConstraint?

    var largeStyle = false {
        didSet {
            titleLabel.font = UIFont(name: UIFont.TheSansBoldPlain, size: largeStyle ? 35 : 25)
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
        label.textColor = .systemWhite
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    func config(for interval: Interval, isLarge: Bool) {
        largeStyle = isLarge
        titleLabel.text = interval.title
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        addSubview(titleLabel)
        titleLabel.addRoundConstraints(to: self)

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
        self.titleLabel.textColor = selectedOrHighlighted ? .systemYellow : .systemWhite
        self.separatorView.backgroundColor = selectedOrHighlighted ? .systemYellow : .systemWhite
    }
}
