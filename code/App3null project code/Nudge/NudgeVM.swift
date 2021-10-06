//
//  NudgeVM.swift
//  Linduu
//
//  Created by Constantine Likhachov on 06.01.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import RxSwift
import RxCocoa
// MARK:- Protocol

protocol NudgeVMProtocol {
    var screenState: BehaviorSubject<PokesScreenState> { get set }
    var showLoadMore: BehaviorSubject<Bool> { get set }
    func numberOfSections() -> Int
    func numberOfRow() -> Int
    func showPopup(for userID: Int)
    func loadPokes()
    func showRecievedPokes()
    func showPokesByMe()
    var reloadData: PublishSubject<Void> { get set }
    var pokesToShow: PublishSubject<[UserCompactModel]> { get set }
    var completionRequest: PublishSubject<String> { get set }
    var statusMessageHandler: PublishSubject<StatusMessage> { get set }
    func showNotEnoughCoinsPopup()
}

class NudgeVM: MVVMViewModel {
    
    let router: MVVMRouter
    let messagingManager: MessagingManagerProtocol
    let blockManager: BlockManagerProtocol
    let giftManager: GiftsManagerProtocol
    
    private var pokesByMe: UsersDataSource = UsersDataSource()
    private var recievedPokes: UsersDataSource = UsersDataSource()
    private var pokes: UsersDataSource
    private var selectedSegment: NudgeSegmentState = .recievedPokes
    private var loading: Bool = false
    var completionRequest = PublishSubject<String>()
    var reloadData: PublishSubject<Void> = PublishSubject<Void>()
    var statusMessageHandler = PublishSubject<StatusMessage>()
    var screenState = BehaviorSubject<PokesScreenState>(value: .loading)
    var showLoadMore = BehaviorSubject<Bool>(value: false)
    var pokesToShow: PublishSubject<[UserCompactModel]> = PublishSubject<[UserCompactModel]>.init()
    
    //==============================================================================
    
    init(with router: MVVMRouter, messagingManager: MessagingManagerProtocol, giftManager: GiftsManagerProtocol, blockManager: BlockManagerProtocol) {
        self.router = router
        self.messagingManager = messagingManager
        self.blockManager = blockManager
        self.giftManager = giftManager
        pokes = recievedPokes
    }
    
    //==============================================================================
    
    func presentPokes() {
        pokesToShow.onNext(pokes.users)
        if pokes.users.count == 0 {
            self.screenState.onNext(.empty)
        } else {
            self.screenState.onNext(.pokes)
        }
    }
    
}

extension NudgeVM: NudgeVMProtocol {
    func showNotEnoughCoinsPopup() {
        router.enqueueRoute(with: NudgeRouter.RouteType.showNotEnaughtCoinsPopup)
    }
    
    func showRecievedPokes() {
        pokes = recievedPokes
        selectedSegment = .recievedPokes
        if pokes.shouldLoadMore && pokes.users.count == 0 {
            loadPokes()
        } else {
            presentPokes()
        }
    }
    
    func showPokesByMe() {
        pokes = pokesByMe
        selectedSegment = .pokesByMe
        if pokes.users.count == 0 {
            loadPokes()
        } else {
            presentPokes()
        }
    }

    func showPopup(for userID: Int) {
        let gift = Gift()
        router.enqueueRoute(with: NudgeRouter.RouteType.popup(delegate: self, userId: userID, gift: gift))
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRow() -> Int {
        return pokes.users.count
    }
    
    func loadPokes() {
        guard pokes.shouldLoadMore && !loading else {
            return
        }
        
        switch selectedSegment {
        case .recievedPokes:
            laodRecievedPokes()
        case .pokesByMe:
            loadPokesByMe()
        }
    }
    
    func loadPokesByMe() {
        loading = true
        if pokesByMe.page > 0 {
            screenState.onNext(.loadMore)
        } else {
            screenState.onNext(.loading)
        }
        messagingManager.loadPokesByMe(page: pokesByMe.page, limit: pokesByMe.limit) { (result) in
            self.loading = false
            switch result {
            case .success(let users):
                self.pokesByMe.users.append(contentsOf: users)
                if users.count < self.pokesByMe.limit {
                    self.pokesByMe.shouldLoadMore = false
                } else {
                    self.pokesByMe.page += 1
                }
            case .failure(let statusMessage):
                self.statusMessageHandler.onNext(statusMessage)
            }
            self.presentPokes()
        }
    }
    
    func laodRecievedPokes() {
        loading = true
        if recievedPokes.page > 0 {
            screenState.onNext(.loadMore)
        } else {
            screenState.onNext(.loading)
        }
        messagingManager.loadRecievedPokes(page: recievedPokes.page, limit: recievedPokes.limit) { (result) in
            self.loading = false
            switch result {
            case .success(let users):
                self.recievedPokes.users.append(contentsOf: users)
                if users.count < self.recievedPokes.limit {
                    self.recievedPokes.shouldLoadMore = false
                } else {
                    self.recievedPokes.page += 1
                }
            case .failure(let statusMessage):
                self.statusMessageHandler.onNext(statusMessage)
            }
            self.presentPokes()
        }
    }
    
}

extension NudgeVM: PopupDelegate {
    
    func sendPokeDidPress(at userId: Int) {
        messagingManager.sendPoke(userId: userId) { [weak self] (result) in
            switch result {
            case .success(_):
                self?.completionRequest.onNext("Alert_pokeSent".localized())
            case .failure(let statusMessage):
                self?.statusMessageHandler.onNext(statusMessage)
            }
        }
    }
    
    func sendMessageDidPress(at userId: Int) {
        let user = pokes.users.first { (model) -> Bool in
            return model.userId == userId
        }
        
        guard let validUser = user else {
            return
        }
        
        router.enqueueRoute(with: NudgeRouter.RouteType.showChat(chat: Chat(conversationID: userId, opponentID: userId, opponentName: validUser.userName)), animated: true, completion: nil)
    }
    
     func blockProfileDidPress(at userId: Int) {
        blockManager.stateBlock(stateOption: true, userId: userId) { [weak self] (result) in
            switch result {
            case .success(_):
                self?.completionRequest.onNext("Alert_UserBlocked".localized())
                self?.reloadData.onNext(())
            case .failure(let statusMessage):
                self?.statusMessageHandler.onNext(statusMessage)
            }
        }
    }
    
    
    func reportUserDidPress(for userId: Int, message: String) {
        messagingManager.reportUser(id: userId, message: message) { [weak self] (result) in
            switch result {
            case .success(_):
                NotificationCenter.default.post(name: NSNotification.Name("dismissReportVC"), object: nil, userInfo: nil)
            case .failure(let statusMessage):
                self?.statusMessageHandler.onNext(statusMessage)
            }
        }
    }

}

enum NudgeSegmentState {
    case recievedPokes
    case pokesByMe
}

class UsersDataSource {
    var shouldLoadMore: Bool = true
    var users:[UserCompactModel] = []
    var page = 0
    var limit = 10
}

enum PokesScreenState {
    case loading
    case loadMore
    case empty
    case pokes
}
