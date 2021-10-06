//
//  WeekNamesView.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 27.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class WeekNamesView: UIView {

    private let stackView: UIStackView = {
        var labels: [UILabel] = [
            weekNameLabel(title: Localizations.WeekName.monday, color: .systemWhite),
            weekNameLabel(title: Localizations.WeekName.tuesday, color: .systemWhite),
            weekNameLabel(title: Localizations.WeekName.wednesday, color: .systemWhite),
            weekNameLabel(title: Localizations.WeekName.thursday, color: .systemWhite),
            weekNameLabel(title: Localizations.WeekName.friday, color: .systemWhite),
            weekNameLabel(title: Localizations.WeekName.saturday, color: .systemAppGray),
            weekNameLabel(title: Localizations.WeekName.sunday, color: .systemAppGray)
        ]
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private static func weekNameLabel(title: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = title
        label.textColor = color
        label.textAlignment = .center
        label.font = UIFont(name: UIFont.TheSansBoldPlain, size: 25)
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
            for subview in stackView.arrangedSubviews {
                if let label = subview as? UILabel {
                    label.font = UIFont(name: UIFont.TheSansBoldPlain, size: largeStyle ? 35 : 25)
                }
            }
            separatorHeight?.constant = largeStyle ? Constant.Size.separatorLandscape : Constant.Size.separatorPortrait
        }
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
        addSubview(stackView)
        addSubview(separatorView)
        heightAnchor.constraint(greaterThanOrEqualToConstant: 75).isActive = true

        stackView.addRoundConstraints(to: self)
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        separatorHeight = separatorView.heightAnchor.constraint(equalToConstant: Constant.Size.separatorPortrait)
        separatorHeight?.isActive = true

        backgroundColor = .systemBlack
    }
}
