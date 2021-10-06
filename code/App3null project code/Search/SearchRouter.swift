//
//  SearchRouter.swift
//  Linduu
//
//  Created by Constantine Likhachov on 10.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import Foundation
import UIKit

class SearchRouter: MVVMRouter {
    
    enum PresentationContext {
        case searchFromTabBar
    }
    
    enum RouteType {
        case showFilter
        case showUserProfile(userId: Int)
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
        
        let vc = SearchVC.instantiateFromStoryboard(storyboardName: "Search", storyboardId: "SearchVC")
        let viewModel = SearchVM.init(with: self, profileManager: dependencies.profileManager, dataManager: dependencies.dataManager)
        vc.viewModel = viewModel
        
        switch presentationContext {
        case .searchFromTabBar:
            nc.pushViewController(vc, animated: true)
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
        case .showFilter:
            let filterRouter = FilterRouter(dependencies: self.dependencies)
            let presentationContext = FilterRouter.PresentationContext.fromSearch
            filterRouter.present(on: nc, animated: animated, context: presentationContext, completion: nil)
        case .showUserProfile(let userId):
            let userProfileRouter = VisitingProfileRouter(dependencies: self.dependencies)
            let presentationContext = VisitingProfileRouter.PresentationContext.fromNearbyUser(userId: userId)
            userProfileRouter.present(on: nc, animated: animated, context: presentationContext, completion: nil)
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
