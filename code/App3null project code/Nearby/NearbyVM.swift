//
//  NearbyVM.swift
//  Linduu
//
//  Created by Constantine Likhachov on 24.01.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import RxSwift
import RxCocoa

// MARK:- Protocol

protocol NearbyVMProtocol {
    var setupScreenState: BehaviorSubject<NearbyScreenState> { get set }
    var statusMessageHandler: PublishSubject<StatusMessage> { get set }
    var showLoadMore: BehaviorSubject<Bool> { get set }
    func viewDidLoad()
    func viewWillAppear()
    func numberOfSections() -> Int
    func numberOfRow(in section: Int) -> Int
    func getNearbyUserItem(with index: Int) -> User
    func loadMoreIfPossible(_ cellIndex: Int)
    func didSelectItem(user: User)
}

class NearbyVM: MVVMViewModel {
    
    let router: MVVMRouter
    private var disposeBag = DisposeBag()
    private let profileManager: ProfileManagerProtocol
    private var users = [User]()
    private var pageIndex: Int = 0
    private var limit = 10
    private var isLoad: Bool = true
    private var isLoading: Bool = false
    var setupScreenState = BehaviorSubject<NearbyScreenState>(value: NearbyScreenState.loading)
    var statusMessageHandler = PublishSubject<StatusMessage>()
    var showLoadMore = BehaviorSubject<Bool>(value: false)
    
    //==============================================================================
    
    init(with router: MVVMRouter, profileManager: ProfileManagerProtocol) {
        self.router = router
        self.profileManager = profileManager
    }
    
    //==============================================================================
}

extension NearbyVM: NearbyVMProtocol {
    
    func viewDidLoad() {
        setupScreenState.onNext(.loading)
        loadNearbyUsers()
    }
    
    func viewWillAppear() {
        if try! setupScreenState.value() == .empty {
            setupScreenState.onNext(.loading)
            loadNearbyUsers()
        }
    }
    
    func numberOfSections() -> Int {
        return NearbyScreenSection.allCases.count
    }
    
    func numberOfRow(in section: Int) -> Int {
        switch NearbyScreenSection(rawValue: section)! {
        case .nearby:
            return users.count
        case .loadMore:
            return self.isLoad && users.count >= limit ? 1 : 0
        }
    }
    
    func getNearbyUserItem(with index: Int) -> User {
        return users[index]
    }
    
    func loadNearbyUsers() {
        if isLoad && !isLoading {
            isLoading = true
            profileManager.searchNearbyProfiles(page: pageIndex, limit: limit) { [weak self] (result) in
                guard let self = self else { return }
                self.showLoadMore.onNext(false)
                switch result {
                case .success(let usersRequests):
                    if usersRequests.isEmpty {
                        self.users = []
                        self.setupScreenState.onNext(.empty)
                    } else {
                        self.isLoad = usersRequests.count == self.limit
                        self.users.append(contentsOf: usersRequests)
                        self.pageIndex += 1
                        self.setupScreenState.onNext(.nearby)
                    }
                case .failure(let statusMessage):
                    self.users = []
                    self.setupScreenState.onNext(.empty)
                    self.statusMessageHandler.onNext(statusMessage)
                }
                self.isLoading = false
            }
        }
    }
    
    func loadMoreIfPossible(_ cellIndex: Int) {
        let cellIndex = cellIndex + 1
        if cellIndex % 10 == 0 {
            let collectionPageIndex = cellIndex / 10
            if collectionPageIndex >= pageIndex {
                loadNearbyUsers()
            }
        }
    }
    
    func didSelectItem(user: User) {
        router.enqueueRoute(with: NearbyRouter.RouteType.showUserProfile(userId: user.userId))
    }
    
}

enum NearbyScreenSection: Int, CaseIterable {
    case nearby
    case loadMore
}

enum NearbyScreenState {
    case loading
    case empty
    case nearby
}
