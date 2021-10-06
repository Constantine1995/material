//
//  LoginVM.swift
//  c4institut
//
//  Created by Constantine Likhachov on 09.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import Combine

// MARK:- Protocol

protocol LoginVMProtocol {
    func showForgotPassword(email: String)
    func login(_ email: String, password: String)
    func showSeminars()
    var displayProgress: PassthroughSubject<Bool, Never> { get set }
    var showStatusMessage: PassthroughSubject<StatusMessage, Never> { get set }
    var popup: PolicyPopupVC { get set }
}

final class LoginVM: MVVMViewModel {
    
    let router: MVVMRouter
    let authorizationService: AuthorizationServiceType
    var displayProgress = PassthroughSubject<Bool, Never>()
    var showStatusMessage =  PassthroughSubject<StatusMessage, Never>()
    var popup: PolicyPopupVC
    
    //==============================================================================
    
    init(with router: MVVMRouter, authorizationService: AuthorizationServiceType, popup: PolicyPopupVC) {
        self.router = router
        self.authorizationService = authorizationService
        self.popup = popup
    }
    
    //==============================================================================
}

extension LoginVM: LoginVMProtocol {
    
    private func showPopup() {
        if UserDefaults.standard.object(forKey: Constant.UserDefaultsKey.acceptDataPrivacy) == nil {
            router.enqueueRoute(with: LoginRouter.RouteType.showPopup)
        }
    }
    
    func showForgotPassword(email: String) {
        router.enqueueRoute(with: LoginRouter.RouteType.showForgotPassword(email: email))
    }
    
    func login(_ email: String, password: String) {
        if UserDefaults.standard.object(forKey: Constant.UserDefaultsKey.acceptDataPrivacy) == nil {
            showPopup()
        } else {
            displayProgress.send(true)
            self.authorizationService.login(email, password) { [weak self] (result) in
                guard let strongSelf = self else {return}
                strongSelf.displayProgress.send(false)
                switch result {
                case .success(()):
                    NotificationCenter.default.post(name: Notification.Name.init(Constant.NotificationCenterKey.userDidLogin), object: nil)
                    strongSelf.showSeminars()
                case .failure(let statusMessage):
                    strongSelf.showStatusMessage.send(statusMessage)
                }
            }
        }
    }
    
    func showSeminars() {
        router.enqueueRoute(with: LoginRouter.RouteType.showSeminars)
    }
}
