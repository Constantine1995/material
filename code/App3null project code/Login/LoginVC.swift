//
//  LoginVC.swift
//  c4institut
//
//  Created by Constantine Likhachov on 09.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxKeyboard
import Combine

class LoginVC: AuthenticationBaseVC, MVVMViewController {
    
    private var cancellables: [AnyCancellable] = []
    
    var textFieldsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 34
        stackView.distribution  = .equalSpacing
        return stackView
    }()
    
    var buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.distribution  = .equalSpacing
        return stackView
    }()
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = Localizations.Login.login_description
        label.font = UIFont(name: UIFont.AppFonts.robotoRegular, size: 13.0)
        label.textColor = UIColor.AppColor.dimgray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var emailTextField = AuthTextField()
    var passwordTextField = AuthTextField()
    var loginButton = UIButton()
    var resetPasswordButton = UIButton()
    var skipButton = UIButton()
    
    let disposeBag = DisposeBag()
    var viewModel: LoginVMProtocol!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar(isMenu: true, isShadow: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    func initUI() {
        setupTextFields()
        setupRx()
        setupButtons()
        stackView.spacing = 45
        stackView.addArrangedSubview(textFieldsStackView)
        stackView.addArrangedSubview(buttonsStackView)
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
        stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 57).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -26).isActive = true
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.isTranslucent = true
    }
    
    private func setupTextFields() {
        emailTextField.widthAnchor.constraint(equalToConstant: 290.0).isActive = true
        emailTextField.rightIcon.image = UIImage(named: "email")
        
        passwordTextField.widthAnchor.constraint(equalToConstant: 290.0).isActive = true
        passwordTextField.rightIcon.image = UIImage(named: "lock")
        
        emailTextField.placeholder = Localizations.Login.login_email
        passwordTextField.placeholder = Localizations.Login.login_password
        
        emailTextField.textColor = UIColor.AppColor.nero
        emailTextField.separatorColor =  UIColor.AppColor.dimgray
        
        passwordTextField.textColor = UIColor.AppColor.nero
        passwordTextField.separatorColor = UIColor.AppColor.dimgray
        
        emailTextField.textField.keyboardType = .emailAddress
        passwordTextField.type = .password
        passwordTextField.isSecuredText = true
        
        textFieldsStackView.addArrangedSubview(emailTextField)
        textFieldsStackView.addArrangedSubview(passwordTextField)
    }
    
    private func setupButtons() {
        resetPasswordButton.titleEdgeInsets = UIEdgeInsets(top: -12, left: 0, bottom: 0, right: 0)
        
        loginButton.setRedButton(with: Localizations.Login.login_loginButton)
        resetPasswordButton.setLinkButton(with: Localizations.Login.login_resetButton)

        skipButton.setBorderButton(with: Localizations.Login.login_skipButton)
        skipButton.heightAnchor.constraint(equalToConstant: 58.0).isActive = true
        skipButton.widthAnchor.constraint(equalToConstant: 290.0).isActive = true
        
        loginButton.heightAnchor.constraint(equalToConstant: 58.0).isActive = true
        loginButton.widthAnchor.constraint(equalToConstant: 290.0).isActive = true
        
        buttonsStackView.addArrangedSubview(loginButton)
        buttonsStackView.addArrangedSubview(skipButton)
        buttonsStackView.addArrangedSubview(resetPasswordButton)
    }
    
    private func setupRx() {
        self.emailTextField.textField.setNextResponder(self.passwordTextField.textField, disposeBag: disposeBag)
        self.passwordTextField.textField.setDoneAction(doneAction: { [weak self] _ in
            guard let self = self else { return }
            self.loginButton.sendActions(for: UIControl.Event.touchUpInside)
            }, disposeBag: disposeBag)
        
        self.emailTextField.textField.rx.controlEvent(.editingChanged).subscribe({ [weak self] _ in
            guard let self = self else { return }
            let value = self.emailTextField.text.isEmpty
            self.emailTextField.setupControlEvent(value: value)
        }).disposed(by: disposeBag)
        
        self.passwordTextField.textField.rx.controlEvent(.editingChanged).subscribe({ [weak self] _ in
            guard let self = self else { return }
            let value = self.passwordTextField.text.isEmpty
            self.passwordTextField.setupControlEvent(value: value)
        }).disposed(by: disposeBag)
        
        resetPasswordButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.viewModel.showForgotPassword(email: self.emailTextField.text ?? "")
        }.disposed(by: disposeBag)
        
        skipButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.viewModel.showSeminars()
        }.disposed(by: disposeBag)
        
        loginButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.login()
        }.disposed(by: disposeBag)
        
        viewModel.popup.acceptButton.rx.tap.bind { [weak self] in
            guard let self = self else {return}
            UserDefaults.standard.set(true, forKey: Constant.UserDefaultsKey.acceptDataPrivacy)
            self.viewModel.popup.dismiss(animated: true)
            self.login()
        }.disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak scrollView] keyboardVisibleHeight in
                scrollView?.contentInset.bottom = keyboardVisibleHeight + 20
                let bottomOffset = CGPoint(x: 0, y: keyboardVisibleHeight)
                scrollView?.setContentOffset(bottomOffset, animated: true)
            }).disposed(by: self.disposeBag)
        self.addEndEditingTap()
        
        viewModel.showStatusMessage.sink { [weak self] (statusMessage) in
            guard let strongSelf = self else {return}
            strongSelf.handleStatusMessage(statusMessage)
        }.store(in: &self.cancellables)
        
        viewModel.displayProgress.sink { (show) in
            show ? LoaderView.sharedInstance.start() : LoaderView.sharedInstance.stop()
        }.store(in: &self.cancellables)
    }
    
    private func login() {
        self.viewModel.login(self.emailTextField.text, password: self.passwordTextField.text)
    }
    
    deinit {
        print(ConsoleHeader.dealloc(String(describing: self)))
    }
}
