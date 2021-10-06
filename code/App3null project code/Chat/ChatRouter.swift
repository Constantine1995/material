//
//  ConversationRouter.swift
//  Linduu
//
//  Created by Constantine Likhachov on 17.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import UIKit

class ChatRouter: MVVMRouter {
    
    enum PresentationContext {
        case startChat(chatModel: Chat)
        case fromConversation(chatModel: Chat)
        case fromFriends(chatModel: Chat)
        case fromVisitingProfile(chatModel: Chat)
    }
    
    enum RouteType {
        case showGiftCategories(receiverId: Int)
        case showChatPopup(type: ChatPopupType)
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
        
        let vc = ChatVC.instantiateFromStoryboard(storyboardName: "Chat", storyboardId: "ChatVC")
    
        switch presentationContext {
        case .startChat(let chatModel), .fromConversation(let chatModel), .fromFriends(let chatModel), .fromVisitingProfile(let chatModel):
            let viewModel = ChatVM.init(with: self, chatModel: chatModel, conversationManager: dependencies.conversationManager)
            vc.viewModel = viewModel
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
        case .showGiftCategories(let ReceiverId):
            let giftCaregoryRouter = GiftCategoryRouter(dependencies: self.dependencies)
            let presentationContext = GiftCategoryRouter.PresentationContext.fromChat(receiverId: ReceiverId)
            giftCaregoryRouter.present(on: nc, animated: animated, context: presentationContext, completion: nil)
        case .showChatPopup(let type):
            let chatPopupRouter = ChatPopupRouter(dependencies: dependencies)
            let presentationContext = ChatPopupRouter.PresentationContext.fromChat(popupType: type)
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
