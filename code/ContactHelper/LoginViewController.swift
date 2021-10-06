//
//  LoginViewController.swift
//  ContactsHelper
//
//  Created by constantine on 18.02.2021.
//

import UIKit
import IQKeyboardManagerSwift
import RxSwift
import RxCocoa

class LoginViewController: BaseViewController {
    
    @IBOutlet weak var emailTextField: BaseTextField!
    @IBOutlet weak var passwordTextField: BaseTextField!
    @IBOutlet weak var emailErrorLabel: BaseLabel!
    @IBOutlet weak var passwordErrorLabel: BaseLabel!
    @IBOutlet weak var resetLabel: UILabel!
    @IBOutlet weak var registerLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var showPasswordButton: UIButton!
    
    private let forgetPasswordText = R.string.localizable.forget_password()
    private let resetText = R.string.localizable.reset_password()
    
    private let dAccountText = R.string.localizable.dont_have_account()
    private let registerText = R.string.localizable.register()
    
    let authManager = AuthManager.shared()
    
    private var registerAccountText: NSString {
        return NSString(string: dAccountText + " " + registerText)
    }
    
    private var resetPasswordText: NSString {
        return NSString(string: forgetPasswordText + " " + resetText)
    }
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupNavigationBar(with: .back)
        setupRX()
        setupUI()
    }
    
    private func setupLabels() {
        configTexts(resetPasswordText, forgetPasswordText, resetText, label: resetLabel)
        configTexts(registerAccountText, dAccountText, registerText, label: registerLabel)
        
        let tapResetGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnResetLabel))
        resetLabel.addGestureRecognizer(tapResetGesture)
        
        let tapRegisterGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnRegisterLabel))
        registerLabel.addGestureRecognizer(tapRegisterGesture)
    }
    
    @objc func handleTapOnResetLabel() {
        guard let newViewController = R.storyboard.resetPassword.resetPasswordViewController() else { return }
        navigationController?.pushViewController(newViewController)
    }
    
    @objc func handleTapOnRegisterLabel() {
        guard let newViewController = R.storyboard.register.registerViewController() else { return }
        navigationController?.pushViewController(newViewController)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.enable = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enableAutoToolbar = true
    }
    
    private func setupRX() {
        emailTextField.setNextResponder(passwordTextField, disposeBag: disposeBag)
        passwordTextField.setDoneAction(doneAction: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.login()
        }, disposeBag: disposeBag)
        
        loginButton.rx.tap.bind { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.login()
        }.disposed(by: disposeBag)
        
        showPasswordButton.rx.tap.bind { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.passwordTextField.isSecureTextEntry = !strongSelf.passwordTextField.isSecureTextEntry
            strongSelf.showPasswordButton.isSelected = !strongSelf.passwordTextField.isSecureTextEntry
        }.disposed(by: disposeBag)
    }
}

// MARK: - Private Methods
private extension LoginViewController {
    func setupUI() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupLabels()
    }
}

// MARK: - Getters
private extension LoginViewController {
    var email: String {
        return emailTextField.text?.trimmed ?? ""
    }
    
    var password: String {
        return passwordTextField.text?.trimmed ?? ""
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
        }
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == emailTextField {
            emailErrorLabel.isHidden = true
        } else if textField == passwordTextField {
            passwordErrorLabel.isHidden = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField.text == nil || textField.text?.trimmed.count == 0 else { return }
        if textField == emailTextField {
            emailErrorLabel.isHidden = false
            emailErrorLabel.text = R.string.localizable.email_required()
        } else if textField == passwordTextField {
            passwordErrorLabel.isHidden = false
            passwordErrorLabel.text = R.string.localizable.password_required()
        }
    }
}

// MARK: - Auth
extension LoginViewController {
    func login() {
        guard email.count > 0 && password.count > 0 else { return }
        authManager.login(email: email, password: password) { [weak self] (result) in
            guard let strongSelf = self else { return }
            switch result {
            case .success:
                guard let newViewController = R.storyboard.main.mainViewController() else { return }
                strongSelf.navigationController?.pushViewController(newViewController)
            case .failure(let error):
                strongSelf.showAlert(title: R.string.localizable.error(), message: error.description)
            }
        }
    }
}
