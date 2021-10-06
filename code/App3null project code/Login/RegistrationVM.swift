//
//  LoginVM.swift
//  c4institut
//
//  Created by Constantine Likhachov on 09.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation

// MARK:- Protocol

protocol RegistrationVMProtocol {
    
}

class LoginVM: MVVMViewModel {
    
    let router: MVVMRouter
    
    //==============================================================================
    
    init(with router: MVVMRouter) {
        self.router = router
    }
    
    //==============================================================================
}

extension LoginVM: RegistrationVMProtocol {
    
}
