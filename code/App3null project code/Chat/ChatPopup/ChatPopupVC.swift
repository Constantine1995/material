//
//  ChatPopupVC.swift
//  Linduu
//
//  Created by Archil on 3/23/20.
//  Copyright © 2020 app3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChatPopupVC: UIViewController, MVVMViewController {
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
    
    let disposeBag = DisposeBag()
    
    var viewModel: ChatPopupVMProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    func setupLayout() {
        self.view.backgroundColor = UIColor.black.withAlphaComponent(CGFloat(0.5))
        
        self.view.addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 36).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -36).isActive = true
        containerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        containerView.addSubview(closeButton)
        closeButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 9).isActive = true
        closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 9).isActive = true
        
        containerView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 45).isActive = true
        imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: CGFloat(231) / CGFloat(263)).isActive = true
//        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        containerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 23).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        
        containerView.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40).isActive = true
        
        
        containerView.addSubview(confirmButton)
        confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50).isActive = true
        confirmButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 23).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30).isActive = true
        

        confirmButton.rx.tap.bind {
            self.viewModel.handleConfirmButton()
            self.dismiss(animated: false, completion: nil)
        }.disposed(by: disposeBag)
        
        closeButton.rx.tap.bind {
            self.dismiss(animated: false, completion: nil)
        }.disposed(by: disposeBag)
        
        confirmButton.setTitle(viewModel.getButtonTitle(), for: .normal)
        imageView.image = viewModel.getImage()
        titleLabel.text = viewModel.getTitle()
        descriptionLabel.text = viewModel.getDescription()
    }
}
