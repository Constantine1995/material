//
//  TrainingsRouter.swift
//  c4institut
//
//  Created by Constantine Likhachov on 25.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation
import UIKit

class TrainingsRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromMenu
    }
    
    enum RouteType {
        case showDetails(Training)
    }
    
    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies
    
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
        
        let vc = TrainingsVC.instantiateFromStoryboard(storyboardName: "Trainings", storyboardId: "TrainingsVC")
        let viewModel = TrainingsVM.init(with: self, trainingsService: TrainingsService(self.dependencies.dataManager, self.dependencies.networkService))
        vc.viewModel = viewModel
        
        switch presentationContext {
            case .fromMenu:
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
            
        case .showDetails(let training):
            let detailsRouter = DetailsRouter(dependencies: self.dependencies)
            let detailsPresentationContext = DetailsRouter.PresentationContext.fromTrainings(training)
            detailsRouter.present(on: nc, animated: true, context: detailsPresentationContext, completion: nil)
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
}
