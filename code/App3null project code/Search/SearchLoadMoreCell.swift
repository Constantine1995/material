//
//  SearchLoadMoreCell.swift
//  Linduu
//
//  Created by Constantine Likhachov on 04.02.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialActivityIndicator

class SearchLoadMoreCell: UICollectionViewCell {
    
    static let cellIdentifier = "SearchLoadMoreCell"
    
    let activityIndicator = MDCActivityIndicator()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityIndicator.cycleColors = [UIColor.AppColor.black]
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
