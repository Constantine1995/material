//
//  LoginRouter.swift
//  c4institut
//
//  Created by Constantine Likhachov on 29.05.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit
import Combine

class AuthenticationFlowRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromCoordinator
    }
    
    enum RouteType {
        case showRegistration
    }
    
    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies
    private var switchSubscriber: AnyCancellable?
    
    //==============================================================================
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }
    
    //==============================================================================
    
    private func addMenu(_ nc: UINavigationController) {
        let menuRouter = MenuRouter(dependencies: self.dependencies)
        let menuPresentationContext = MenuRouter.PresentationContext.fromDashboard
        menuRouter.present(on: nc, animated: true, context: menuPresentationContext, completion: nil)
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

        let vc = AuthenticationFlowVC.instantiateFromStoryboard(storyboardName: "Login", storyboardId: "LoginVC")
        let viewModel = LoginVM.init(with: self)
        vc.viewModel = viewModel
        switch presentationContext {
        case .fromCoordinator:
            let splashvc = SplashScreenVC(behaviour: .loginScreen)
            splashvc.modalPresentationStyle = .overFullScreen
            nc.present(splashvc, animated: false) { [weak self] in
                guard let self = self else {return}
                self.addMenu(nc)
                nc.pushViewController(vc, animated: false)
                nc.setNavigationBarHidden(false, animated: true)
                self.switchSubscriber = splashvc.$isPresentationState.assign(to: \.isHidden, on: vc.logoImageView)
            }
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
        case .showRegistration:
            let registrationRouter = RegistrationRouter(dependencies: dependencies)
            let registrationContext = RegistrationRouter.PresentationContext.fromLogin
            registrationRouter.present(on: nc, animated: true, context: registrationContext, completion: nil)
            
//                let registrationVC = RegistrationVC
//                registrationVC.modalPresentationStyle = .overFullScreen
//                nc.present(registrationVC, animated: false) { [weak self] in
//                    guard let self = self else {return}
//                    nc.pushViewController(vc, animated: false)
//                    nc.setNavigationBarHidden(false, animated: true)
//                }
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
