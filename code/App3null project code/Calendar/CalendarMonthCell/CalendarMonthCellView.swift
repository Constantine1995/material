//
//  CalendarMonthCellView.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 27.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class CalendarMonthCellView: UIView {

    // MARK: - Subviews

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .systemWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var month: String {
        get { return titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    var year: String {
        get { return titleLabel.text ?? "" }
        set {
            titleLabel.text = "\(month) \(newValue)"
            titleLabel.font = UIFont(name: UIFont.TheSansBoldPlain, size: largeStyle ? 35 : 25)
        }
    }

    var separatorHeight: NSLayoutConstraint?

    var largeStyle = false {
        didSet {
            titleLabel.font = UIFont(name: UIFont.TheSansBoldExpert, size: largeStyle ? 35 : 25)
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
        addSubview(titleLabel)
        addSubview(separatorView)

        titleLabel.addRoundConstraints(to: self)

        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        separatorHeight = separatorView.heightAnchor.constraint(equalToConstant: Constant.Size.separatorPortrait)
        separatorHeight?.isActive = true

        backgroundColor = .systemBlack
    }

}
