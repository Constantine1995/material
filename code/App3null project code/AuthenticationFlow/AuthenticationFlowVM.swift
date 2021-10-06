//
//  AuthenticationFlowVM.swift
//  c4institut
//
//  Created by Constantine Likhachov on 29.05.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation

// MARK:- Protocol

protocol AuthenticationFlowVMProtocol {
    func showLogin()
    func skipLogin()
}

class AuthenticationFlowVM: MVVMViewModel {
    
    let router: MVVMRouter
    
    //==============================================================================
    
    init(with router: MVVMRouter) {
        self.router = router
    }
    
    //==============================================================================

    deinit {
       print(ConsoleHeader.dealloc(String(describing: self)))
    }
    
    //==============================================================================
}

extension AuthenticationFlowVM: AuthenticationFlowVMProtocol {
    
    func showLogin() {
        router.enqueueRoute(with: AuthenticationFlowRouter.RouteType.showLogin)
    }
     
    func skipLogin() {
        router.enqueueRoute(with: AuthenticationFlowRouter.RouteType.showSeminars)
    }
}
