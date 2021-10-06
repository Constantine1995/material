//
//  AuthenticationFlowRouter.swift
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
        case showLogin
        case showSeminars
    }
    
    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies
    private var switchSubscriber: AnyCancellable?
    
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
        
        let vc = AuthenticationFlowVC.instantiateFromStoryboard(storyboardName: "AuthenticationFlow", storyboardId: "AuthenticationFlowVC")
        let viewModel = AuthenticationFlowVM.init(with: self)
        vc.viewModel = viewModel
        switch presentationContext {
        case .fromCoordinator:
            let splashvc = SplashScreenVC(behaviour: .loginScreen)
            splashvc.modalPresentationStyle = .overFullScreen
            nc.present(splashvc, animated: false) { [weak self] in
                guard let self = self else {return}
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
        case .showLogin:
            let loginRouter = LoginRouter(dependencies: dependencies)
            let loginContext = LoginRouter.PresentationContext.fromAuth
            loginRouter.present(on: nc, animated: true, context: loginContext, completion: nil)
        case .showSeminars:
            let seminarsRouter = SeminarsRouter(dependencies: self.dependencies)
            let seminarsPresentationContext = SeminarsRouter.PresentationContext.fromLogin
            seminarsRouter.present(on: nc, animated: true, context: seminarsPresentationContext, completion: nil)
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
    
    deinit {
       print(ConsoleHeader.dealloc(String(describing: self)))
    }
    
    //==============================================================================
}
