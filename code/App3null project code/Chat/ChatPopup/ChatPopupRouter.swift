//
//  ChatPopupRouter.swift
//  Linduu
//
//  Created by Archil on 3/23/20.
//  Copyright © 2020 app3null. All rights reserved.
//

import Foundation
import UIKit

class ChatPopupRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromChat(popupType: ChatPopupType)
        case fromSendGift
        case fromVisitingProfile
        case fromVisits
        case fromFriendRequests
        case fromFriends
        case fromFavourites
        case fromPokes
    }
    
    enum RouteType {
        case showAcquireCoins
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
        
        let vc = ChatPopupVC(nibName: "ChatPopup", bundle: nil)
        vc.modalPresentationStyle = .overFullScreen
        
        
        switch presentationContext {
        
        case .fromChat(let popupType):
            let viewModel = ChatPopupVM.init(with: self, popupType: popupType)
            vc.viewModel = viewModel
            nc.present(vc, animated: false, completion: nil)
        case .fromSendGift, .fromFavourites, .fromFriends, .fromFriendRequests, .fromPokes, .fromVisitingProfile, .fromVisits:
            let viewModel = ChatPopupVM.init(with: self, popupType: .notEnaughtCoins)
            vc.viewModel = viewModel
            nc.present(vc, animated: false, completion: nil)
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
            
        case .showAcquireCoins:
            let acquireCoinsRouter = AcquireСoinsRouter(dependencies: dependencies)
            let presentationContext = AcquireСoinsRouter.PresentationContext.fromPopup
            acquireCoinsRouter.present(on: nc, animated: true, context: presentationContext, completion: nil)
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
