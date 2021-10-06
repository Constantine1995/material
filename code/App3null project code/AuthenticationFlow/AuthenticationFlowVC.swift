//
//  AuthenticationFlowVC.swift
//  c4institut
//
//  Created by Constantine Likhachov on 29.05.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Combine

class AuthenticationFlowVC: AuthenticationBaseVC, MVVMViewController {
    
    var authButton = UIButton()
    var skipLoginButton = UIButton()
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = Localizations.AuthenticationFlow.authenticationFlow_description
        label.font = UIFont(name: UIFont.AppFonts.robotoRegular, size: 13.0)
        label.textColor = UIColor.AppColor.dimgray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let disposeBag = DisposeBag()
    var viewModel: AuthenticationFlowVMProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setupAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar(isMenu: true, isShadow: false)
    }
    
    func initUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupButtons()
        
        stackView.spacing = 23
        stackView.addArrangedSubview(authButton)
        stackView.addArrangedSubview(skipLoginButton)
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 63).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -63).isActive = true
        
        stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 36).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -67).isActive = true
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.isTranslucent = true
    }
    
    private func setupButtons() {
        authButton.setRedButton(with: Localizations.AuthenticationFlow.authenticationFlow_authButton)
        skipLoginButton.setBorderButton(with: Localizations.AuthenticationFlow.authenticationFlow_skipButton)
        authButton.heightAnchor.constraint(equalToConstant: 58.0).isActive = true
        authButton.widthAnchor.constraint(equalToConstant: 290.0).isActive = true
        skipLoginButton.heightAnchor.constraint(equalToConstant: 58.0).isActive = true
        skipLoginButton.widthAnchor.constraint(equalToConstant: 290.0).isActive = true
    }
    
    private func setupAction() {
        authButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.viewModel.showLogin()
        }.disposed(by: disposeBag)
        
        skipLoginButton.rx.controlEvent(.touchUpInside).subscribe({ [weak self]  _ in
            guard let self = self else { return }
            self.viewModel.skipLogin()
        }).disposed(by: disposeBag)
    }
    
    deinit {
        print(ConsoleHeader.dealloc(String(describing: self)))
    }
}
