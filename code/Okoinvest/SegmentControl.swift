//
//  SegmentControl.swift
//  Okoinvest
//
//  Created by constantine on 17.03.2021.
//

import UIKit

enum Segment: CaseIterable {
    case Chats
    case Contacts
    
    var title: String {
        switch self {
        case .Chats:
            return R.string.localizable.chats()
        case .Contacts:
            return R.string.localizable.adminContacts()
        }
    }
}

class SegmentControl: UIView {
    
    lazy var segmentedControl: UISegmentedControl = {
        var segmentedControl = UISegmentedControl(items : Segment.allCases.map({$0.title}))
        
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
        
        segmentedControl.setTitleTextAttributes([ NSAttributedString.Key.foregroundColor: UIColor.black,
                                                  NSAttributedString.Key.font: R.font.sfuiDisplayRegular(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .regular)], for: .normal)
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    private lazy var bottomUnderlineView: UIView = {
        let underlineView = UIView()
        underlineView.backgroundColor =  R.color.lightBlue()
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        return underlineView
    }()
    
    private lazy var leadingDistanceConstraint: NSLayoutConstraint = {
        return bottomUnderlineView.leftAnchor.constraint(equalTo: segmentedControl.leftAnchor)
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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

