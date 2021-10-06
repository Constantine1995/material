//
//  LoginVM.swift
//  c4institut
//
//  Created by Constantine Likhachov on 29.05.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation

// MARK:- Protocol

protocol LoginVMProtocol {
    func showRegistration()
}

class AuthenticationFlowVM: MVVMViewModel {
    
    let router: MVVMRouter
    
    //==============================================================================
    
    init(with router: MVVMRouter) {
        self.router = router
    }
    
    //==============================================================================
}

extension AuthenticationFlowVM: LoginVMProtocol {
    
    func showRegistration() {
        router.enqueueRoute(with: AuthenticationFlowRouter.RouteType.showRegistration)
    }
}
