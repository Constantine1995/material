//
//  PopupView.swift
//  Linduu
//
//  Created by Archil on 3/22/20.
//  Copyright © 2020 app3null. All rights reserved.
//

import UIKit
import RxSwift

enum ChatPopupType: CaseIterable {
    case noNetworkConnection
    case notEnaughtCoins
    
    var title: String {
        switch self {
        case .noNetworkConnection:
            return "noNetworkConnection_title".localized()
        case .notEnaughtCoins:
            return "notEnaughtCoins_title".localized()
        }
    }
    
    var description: String {
        switch self {
        case .noNetworkConnection:
            return "noNetworkConnection_description".localized()
        case .notEnaughtCoins:
            return "notEnaughtCoins_description".localized()
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .noNetworkConnection:
            return "noNetworkConnection_buttonTitle".localized()
        case .notEnaughtCoins:
            return "notEnaughtCoins_buttonTitle".localized()
        }
    }
    
    var image: UIImage {
        switch self {
        case .noNetworkConnection:
            return UIImage(named: "noNetworkConnection")!
        case .notEnaughtCoins:
            return UIImage(named: "notEnaughtCoins")!
        }
    }
}

class ChatPopupView: UIView {

    let disposeBag = DisposeBag()
    
    lazy var closeButton: UIButton = {
        var button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", for: .normal)
        button.setImage(UIImage(named: "closePopup"), for: .normal)
        return button
    }()
    
    lazy var imageView: UIImageView = {
        var imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.AppFonts.sfuitTextRegular(with: 20)
        label.textColor = UIColor.AppColor.black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.AppFonts.sfuitTextRegular(with: 14)
        label.textColor = UIColor.AppColor.greyish
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var confirmButton: UIButton = {
        var button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.AppColor.brightTeal
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()
    
    init(popupType: ChatPopupType) {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout() {
        self.backgroundColor = UIColor.black.withAlphaComponent(CGFloat(0.5))
        
        self.addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 36).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -36).isActive = true
        containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        containerView.addSubview(closeButton)
        closeButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 9).isActive = true
        closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 9).isActive = true
        
        containerView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 45).isActive = true
        imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: CGFloat(231 / 263)).isActive = true
        
        containerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 23).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        
        containerView.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40).isActive = true
        
        
        containerView.addSubview(confirmButton)
        confirmButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 50).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -50).isActive = true
        confirmButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 23).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30).isActive = true
        

        confirmButton.rx.tap.bind {
            self.removeFromSuperview()
        }.disposed(by: disposeBag)
        
        closeButton.rx.tap.bind {
            self.removeFromSuperview()
        }.disposed(by: disposeBag)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
