//
//  WeatherRouter.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import UIKit

class WeatherRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromCoordinator
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
        nc.setNavigationBarHidden(true, animated: false)
        let vc = WeatherVC.instantiateFromStoryboard(storyboardName: "Weather", storyboardId: "WeatherVC")
        let viewModel = WeatherVM.init(with: self, weatherService: WeatherService(self.dependencies.networkService))
        vc.viewModel = viewModel
        
        switch presentationContext {
        case .fromCoordinator:
            nc.viewControllers = [vc]
        }
    }
    
    //==============================================================================
    
    func enqueueRoute(with context: Any?, animated: Bool, completion: ((Bool) -> Void)?) {
        guard let routeType = context as? RouteType else {
            assertionFailure("The route type missmatches")
            return
        }
        
        guard let _ = baseViewController as? UINavigationController else {
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
