//
//  BaseTextField.swift
//  ContactsHelper
//
//  Created by constantine on 18.02.2021.
//

import UIKit

class BaseTextField: UITextField {
    enum TextFieldType: Int {
        case none = 0
        case email = 1
        case password = 2
        case fullName = 3
    }
    
    @IBInspectable
    var typeValue: Int {
        get {
            return type.rawValue
        }
        set {
            type = TextFieldType(rawValue: newValue) ?? .none
        }
    }
    
    var type: TextFieldType = .none {
        didSet {
            updateUI()
        }
    }
    
    var placeholderText: String? {
        switch type {
        case .none:
            return nil
        case .email:
            return  R.string.localizable.email_placeholder()
        case .password:
            return R.string.localizable.password_placeholder()
        case .fullName:
            return R.string.localizable.full_name()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        defaultSetup()
    }
    
    private func defaultSetup() {
        borderStyle = .none
        cornerRadius = 12
        backgroundColor = .textField
        font = .manropeRegular(size: 14)
    }
    
    private func updateUI() {
        placeholder = placeholderText
        
        if type == .fullName {
            autocapitalizationType = .words
        } else {
            autocapitalizationType = .none
        }
        if type == .email {
            keyboardType = .emailAddress
        } else {
            keyboardType = .default
        }
        if type == .password {
            isSecureTextEntry = true
        } else {
            isSecureTextEntry = false
        }
    }
    
    public var topOffset: CGFloat = 0 {
        didSet {
            layoutSubviews()
        }
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect : CGRect = CGRect(x: bounds.origin.x + 10, y: bounds.origin.y + topOffset, width: bounds.size.width, height: bounds.size.height)
        return rect
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect : CGRect = CGRect(x: bounds.origin.x + 10, y: bounds.origin.y + topOffset, width: bounds.size.width, height: bounds.size.height)
        return rect
    }
}
