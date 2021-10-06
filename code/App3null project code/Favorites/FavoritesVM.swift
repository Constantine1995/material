//
//  FavoritesVM.swift
//  Linduu
//
//  Created by Constantine Likhachov on 11.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import RxSwift
import RxCocoa

// MARK:- Protocol

protocol FavoritesVMProtocol {
    var setupScreenState: BehaviorSubject<FavoriteProfilesScreenState> { get set }
    var statusMessageHandler: PublishSubject<StatusMessage> { get set }
    var completionRequest: PublishSubject<String> { get set }
    var showLoadMore: BehaviorSubject<Bool> { get set }
    var userIndex: Int { get set }
    func viewDidLoad()
    func viewWillAppear()
    func numberOfSections() -> Int
    func numberOfRow(in section: Int) -> Int
    func getFavoriteProfilesPreview(at index: Int) -> Favorite
    func showPopup()
    func getUsers(at index: Int) -> FriendCellVM
    func showNotEnoughCoinsPopup()
}

class FavoritesVM: MVVMViewModel, PopupDelegate {
    
    let router: MVVMRouter
    let disposeBag = DisposeBag()
    private let favoriteManager: FavoriteManagerProtocol
    private let friendshipManager: FriendshipManagerProtocol
    private let messagingManager: MessagingManagerProtocol
    private let blockManager: BlockManagerProtocol
    private var users: [Favorite] = []
    private var isLoadMore: Bool = false
    private var loading: Bool = false
//    private var gift = Gift()
    
    var userIndex: Int = 0
    var setupScreenState = BehaviorSubject<FavoriteProfilesScreenState>(value: FavoriteProfilesScreenState.loading)
    var statusMessageHandler = PublishSubject<StatusMessage>()
    var showLoadMore = BehaviorSubject<Bool>(value: false)
    var completionRequest = PublishSubject<String>()
    
    //==============================================================================
    
    init(with router: MVVMRouter, friendshipManager: FriendshipManagerProtocol, favoriteManager: FavoriteManagerProtocol, messagingManager: MessagingManagerProtocol, blockManager: BlockManagerProtocol) {
        self.router = router
        self.friendshipManager = friendshipManager
        self.favoriteManager = favoriteManager
        self.messagingManager = messagingManager
        self.blockManager = blockManager
    }
    
    //==============================================================================

    deinit {
        print("deinit favoritesVM")
    }
}

extension FavoritesVM: FavoritesVMProtocol {
    func showNotEnoughCoinsPopup() {
        router.enqueueRoute(with: FavoritesRouter.RouteType.showNotEnaughtCoinsPopup)
    }
    
    func viewDidLoad() {
        setupScreenState.onNext(.loading)
        loadFavoritesProfile()
    }
    
    func viewWillAppear() {
        if try! setupScreenState.value() == .empty {
            setupScreenState.onNext(.loading)
            loadFavoritesProfile()
        }
    }
    
    func numberOfSections() -> Int {
        return FavoriteProfilesScreenSection.allCases.count
    }
    
    func numberOfRow(in section: Int) -> Int {
        switch FavoriteProfilesScreenSection(rawValue: section)! {
        case .favotireProfiles:
            return users.count
        case .loadMore:
            return self.isLoadMore ? 1 : 0
        }
    }
    
    func loadFavoritesProfile(shouldLoadMore: Bool = false) {
        
        guard !loading else { return }
        
        loading = shouldLoadMore
        
        let page = shouldLoadMore ? users.count : 0
        let limit = 0
        
        favoriteManager.getFavoriteProfiles(page: page, limit: limit) { [weak self] (result) in
            guard let self = self else { return }
            self.loading = false
            self.showLoadMore.onNext(false)
            switch result {
            case .success(let friendRequests):
                if friendRequests.isEmpty && !shouldLoadMore {
                    self.users = []
                    self.setupScreenState.onNext(.empty)
                } else {
                    self.isLoadMore = friendRequests.count == limit
                    if shouldLoadMore {
                        self.users.append(contentsOf: friendRequests)
                    } else {
                        self.users = friendRequests
                    }
                    self.setupScreenState.onNext(.profiles)
                }
            case .failure(let statusMessage):
                if !shouldLoadMore {
                    self.users = []
                    self.setupScreenState.onNext(.empty)
                } else {
                    self.showLoadMore.onNext(false)
                }
                self.statusMessageHandler.onNext(statusMessage)
            }
        }
    }
    
    func getFavoriteProfilesPreview(at index: Int) -> Favorite {
        users[index]
    }
    
    func getUsers(at index: Int) -> FriendCellVM {
        let user = users[index]
        let friendCell = FriendCellVM(name: user.userName, age: user.age, imageURL: user.imageURL)
        return friendCell
    }
    
    func showPopup() {
        let userId = users[userIndex].userId
        let username = users[userIndex].userName
        router.enqueueRoute(with: FavoritesRouter.RouteType.popup(popupDelegate: self, userId: userId, gift: Gift(), username: username))
    }
    
    //MARK: Actions on user
    func sendFriendRequestDidPress(at userId: Int) {
        friendshipManager.addFriendship(userId: userId) { [weak self] (result) in
            switch result {
            case .success(let response):
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NotificationCenterKey.didUpdateCoinsAmmount), object: nil, userInfo: ["coins": response.coins])
                self?.completionRequest.onNext("Alert_friendRequest".localized())
            case .failure(let statusMessage):
                self?.statusMessageHandler.onNext(statusMessage)
            }
        }
    }
    
    func sendPokeDidPress(at userId: Int) {
        messagingManager.sendPoke(userId: userId) { [weak self] (result) in
            switch result {
            case .success(let response):
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NotificationCenterKey.didUpdateCoinsAmmount), object: nil, userInfo: ["coins": response.coins])
                self?.completionRequest.onNext("Alert_pokeSent".localized())
            case .failure(let statusMessage):
                self?.statusMessageHandler.onNext(statusMessage)
            }
        }
    }
    
    func sendMessageDidPress(at userId: Int) {
        let user = users.first { (model) -> Bool in
            return model.userId == userId
        }
        
        guard let validUser = user else {
            return
        }
        
        router.enqueueRoute(with: FavoritesRouter.RouteType.showChat(chat: Chat(conversationID: userId, opponentID: userId, opponentName: validUser.userName)), animated: true, completion: nil)
    }
    
    func blockProfileDidPress(at userId: Int) {
        blockManager.stateBlock(stateOption: true, userId: userId) { [weak self] (result) in
            switch result {
            case .success(_):
                self?.completionRequest.onNext("Alert_UserBlocked".localized())
                self?.viewDidLoad()
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

enum FavoriteProfilesScreenSection: Int, CaseIterable {
    case favotireProfiles
    case loadMore
}

enum FavoriteProfilesScreenState {
    case loading
    case empty
    case profiles
}
