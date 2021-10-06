//
//  LoginRouter.swift
//  c4institut
//
//  Created by Constantine Likhachov on 09.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit
import Combine

class LoginRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromAuth
        case fromMenu
        case unauthorized
    }
    
    enum RouteType {
        case showForgotPassword(email: String)
        case showSeminars
        case showPopup
    }
    
    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies
    private var cancellable: AnyCancellable?
    private let popup = PolicyPopupVC()
    
    //==============================================================================
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }
    
    //==============================================================================
    
    func present(on baseVC: UIViewController, animated: Bool, context: Any?, completion: ((Bool) -> Void)?) {
        
        guard let presentationContext = context as? PresentationContext else {
            assertionFailure("The context type missmatch")
            return
        }
        
        guard let nc = baseVC as? UINavigationController else {
            assertionFailure("The baseVC should be UINavigationController")
            return
        }
        baseViewController = baseVC
        
        let vc = LoginVC.instantiateFromStoryboard(storyboardName: "Login", storyboardId: "LoginVC")
        let viewModel = LoginVM.init(with: self, authorizationService: AuthorizationService(self.dependencies.dataManager, self.dependencies.networkService), popup: popup)
        vc.viewModel = viewModel
        
        switch presentationContext {
        case .fromAuth:
            nc.pushViewController(vc, animated: false)
        case .fromMenu, .unauthorized:
            nc.setViewControllers([vc], animated: false)
        }
    }
    
    //==============================================================================
    
    func enqueueRoute(with context: Any?, animated: Bool, completion: ((Bool) -> Void)?) {
        guard let routeType = context as? RouteType else {
            assertionFailure("The route type missmatches")
            return
        }
        
        guard let nc = baseViewController as? UINavigationController else {
            assertionFailure("The baseVC should be UINavigationController")
            return
        }
        
        switch routeType {
        case .showForgotPassword:
            let router = ForgotPasswordRouter(dependencies: dependencies)
            let context = ForgotPasswordRouter.PresentationContext.fromLogin
            router.present(on: nc, animated: true, context: context, completion: nil)
        case .showSeminars:
            let seminarsRouter = SeminarsRouter(dependencies: self.dependencies)
            let seminarsPresentationContext = SeminarsRouter.PresentationContext.fromLogin
            seminarsRouter.present(on: nc, animated: true, context: seminarsPresentationContext, completion: nil)
        case .showPopup:
            nc.present(popup, animated: true)
            
            cancellable = popup.eventTapDataPrivacy.sink() { [weak self] _ in
                guard let self = self else {return}
                self.popup.dismiss(animated: true)

                let vc = WebBaseVC()
                vc.configWebView(for: .privacy)
                nc.pushViewController(vc, animated: false)
            }
        }
    }
    
    //==============================================================================
    
    func dismiss(animated: Bool, context: Any?, completion: ((Bool) -> Void)?) {
        guard let nc = baseViewController as? UINavigationController else {
            assertionFailure("The baseVC should be UINavigationController")
            return
        }
        nc.popViewController(animated: true)
    }
    
    //==============================================================================
}
