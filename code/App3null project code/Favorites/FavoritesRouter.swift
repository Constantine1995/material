//
//  FavoritesRouter.swift
//  Linduu
//
//  Created by Constantine Likhachov on 11.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FavoritesRouter: MVVMRouter {
    
    enum PresentationContext {
        case fromMenu
    }
    
    enum RouteType {
        case popup(popupDelegate: PopupDelegate?, userId: Int, gift: Gift, username: String)
        case showChat(chat: Chat)
        case showNotEnaughtCoinsPopup
    }
    
    weak var baseViewController: UIViewController?
    let dependencies: AppDependencies
    
    //==============================================================================
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }
    
    //==============================================================================
    
    deinit {
        print("deinit favoritesRouter")
    }
    
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
        
        let vc = FavoritesVC.instantiateFromStoryboard(storyboardName: "Favorites", storyboardId: "FavoritesVC")
        let dep = dependencies
        let viewModel = FavoritesVM.init(with: self, friendshipManager:
            dep.friendshipManager, favoriteManager: dep.favoriteManager, messagingManager: dep.messagingManager, blockManager: dep.blockManager)
        vc.viewModel = viewModel

        switch presentationContext {
        case .fromMenu:
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
        case .popup(let popupDelegate, let userId, let gift, let username):
            let popupRouter = PopupRouter(dependencies: dependencies)
            let popupData = PopupData(popupDelegate: popupDelegate, popupType: .favorites, userId: userId, username: username, gift: gift)
            let presentationContext = PopupRouter.PresentationContext.fromPopup(popupData: popupData)
            popupRouter.present(on: nc, animated: animated, context: presentationContext, completion: nil)
            case .showChat(let chat):
                let chatRouter = ChatRouter(dependencies: self.dependencies)
                let presentationContext = ChatRouter.PresentationContext.fromConversation(chatModel: chat)
                chatRouter.present(on: nc, animated: animated, context: presentationContext, completion: nil)
            case .showNotEnaughtCoinsPopup:
                let chatPopupRouter = ChatPopupRouter(dependencies: dependencies)
                let presentationContext = ChatPopupRouter.PresentationContext.fromFavourites
                chatPopupRouter.present(on: nc, animated: animated, context: presentationContext, completion: nil)
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
