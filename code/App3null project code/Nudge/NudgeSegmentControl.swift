//
//  NudgeSegmentControl.swift
//  Linduu
//
//  Created by Constantine Likhachov on 06.01.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import UIKit

enum NudgeSegment: CaseIterable {
    case nudge
    case nudgeMe
    
    var title: String {
        switch self {
        case .nudge:
            return "Nudge_nudge".localized()
        case .nudgeMe:
            return "Nudge_nudgeMe".localized()
        }
    }
}

class NudgeSegmentControl: UIView {
    
    lazy var segmentedControl: UISegmentedControl = {
        var segmentedControl = UISegmentedControl(items : NudgeSegment.allCases.map({$0.title}))
        
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .white
            segmentedControl.isSelected = false
        }
        
        segmentedControl.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        segmentedControl.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        segmentedControl.backgroundColor = .white
        segmentedControl.tintColor = .white
        segmentedControl.layer.cornerRadius = 0
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.AppColor.silverTwo,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .light)], for: .normal)
        
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.AppColor.brightTeal,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular)], for: .selected)
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    private lazy var bottomUnderlineView: UIView = {
        let underlineView = UIView()
        underlineView.backgroundColor = UIColor.AppColor.brightTeal
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        return underlineView
    }()
    
    private lazy var leadingDistanceConstraint: NSLayoutConstraint = {
        return bottomUnderlineView.leftAnchor.constraint(equalTo: segmentedControl.leftAnchor)
    }()
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentedControl)
        addSubview(bottomUnderlineView)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            bottomUnderlineView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            bottomUnderlineView.heightAnchor.constraint(equalToConstant: 2),
            leadingDistanceConstraint,
            bottomUnderlineView.widthAnchor.constraint(equalTo: segmentedControl.widthAnchor, multiplier: 1 / CGFloat(segmentedControl.numberOfSegments))
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        changeSegmentedControlLinePosition()
    }
    
    private func changeSegmentedControlLinePosition() {
        let segmentIndex = CGFloat(segmentedControl.selectedSegmentIndex)
        let segmentWidth = segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments)
        let leadingDistance = segmentWidth * segmentIndex
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.leadingDistanceConstraint.constant = leadingDistance
            self?.layoutIfNeeded()
        })
    }
}
