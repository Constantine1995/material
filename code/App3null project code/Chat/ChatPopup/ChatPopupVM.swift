//
//  ChatPopupVM.swift
//  Linduu
//
//  Created by Archil on 3/23/20.
//  Copyright © 2020 app3null. All rights reserved.
//

import Foundation
import UIKit
// MARK:- Protocol

protocol ChatPopupVMProtocol {
    func getTitle() -> String
    func getDescription() -> String
    func getImage() -> UIImage
    func getButtonTitle() -> String
    func handleConfirmButton()
}

class ChatPopupVM: MVVMViewModel {
    
    let router: MVVMRouter
    let popupType: ChatPopupType
    
    //==============================================================================
    
    init(with router: MVVMRouter, popupType: ChatPopupType) {
        self.router = router
        self.popupType = popupType
    }
    
    //==============================================================================
}

extension ChatPopupVM: ChatPopupVMProtocol {
    func handleConfirmButton() {
        router.enqueueRoute(with: ChatPopupRouter.RouteType.showAcquireCoins)
    }
    
    func getTitle() -> String {
        return popupType.title
    }
    
    func getDescription() -> String {
        return popupType.description
    }
    
    func getImage() -> UIImage {
        return popupType.image
    }
    
    func getButtonTitle() -> String {
        return popupType.buttonTitle
    }
}
