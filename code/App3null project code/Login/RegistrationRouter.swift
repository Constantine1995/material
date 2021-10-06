//
//  RegistrationRouter.swift
//  c4institut
//
//  Created by Constantine Likhachov on 09.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import UIKit

class LoginRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromLogin
    }
    
    enum RouteType {
    }
    
    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies
    
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
        
        let vc = LoginVC.instantiateFromStoryboard(storyboardName: "Login", storyboardId: "LoginVC")
        let viewModel = RegistrationVM.init(with: self)
        vc.viewModel = viewModel
        
        switch presentationContext {
        case .fromLogin:
            addMenu(nc)
            nc.pushViewController(vc, animated: false)
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
