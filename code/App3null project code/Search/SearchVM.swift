//
//  SearchVM.swift
//  Linduu
//
//  Created by Constantine Likhachov on 10.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import RxSwift
import RxCocoa

// MARK:- Protocol

protocol SearchVMProtocol {
    var setupScreenState: BehaviorSubject<SearchScreenState> { get set }
    var statusMessageHandler: PublishSubject<StatusMessage> { get set }
    var showLoadMore: BehaviorSubject<Bool> { get set }
    func viewDidLoad()
    func viewWillAppear()
    func numberOfRow(in section: Int) -> Int
    func numberOfSections() -> Int
    func didSelectItem(user: SearchFilterResult)
    func getSearchUserItem(with index: Int) -> SearchFilterResult
    func showFilter()
    func loadMoreIfPossible(_ cellIndex: Int)
    func updateData()
}

class SearchVM: MVVMViewModel {
    
    let router: MVVMRouter
    private var disposeBag = DisposeBag()
    private let profileManager: ProfileManagerProtocol
    private let dataManager: DataManagerProtocol
    private var users = [SearchFilterResult]()
    private var isLoad: Bool = true
    private var isLoading: Bool = false
    private var pageIndex: Int = 0
    private let limit: Int = 10
    var setupScreenState = BehaviorSubject<SearchScreenState>(value: SearchScreenState.loading)
    var statusMessageHandler = PublishSubject<StatusMessage>()
    var showLoadMore = BehaviorSubject<Bool>(value: false)
    
    //==============================================================================
    
    init(with router: MVVMRouter, profileManager: ProfileManagerProtocol, dataManager: DataManagerProtocol) {
        self.router = router
        self.profileManager = profileManager
        self.dataManager = dataManager
    }
    
    //==============================================================================
}

extension SearchVM: SearchVMProtocol {
    
    func viewDidLoad() {
        setupScreenState.onNext(.loading)
        getProfiles()
    }
    
    func viewWillAppear() {
        if try! setupScreenState.value() == .empty {
            setupScreenState.onNext(.loading)
            getProfiles()
        }
    }
    
    func numberOfRow(in section: Int) -> Int {
        switch SearchScreenSection(rawValue: section)! {
        case .search:
            return users.count
        case .loadMore:
            return self.isLoad ? 1 : 0
        }
    }
    
    func numberOfSections() -> Int {
        return SearchScreenSection.allCases.count
    }
    
    func didSelectItem(user: SearchFilterResult) {
        router.enqueueRoute(with: SearchRouter.RouteType.showUserProfile(userId: user.userId))
    }
    
    func getProfiles(isUpdate: Bool = false) {
        if isLoad && !isLoading {
            isLoading = true
            //  if the result exists in the database
            if let searchFilterMo: SearchFilterMO = self.dataManager.getSearchProfile() {
                if searchFilterMo.username?.isEmpty ?? false {
                    searchProfiles(searchFilterMo: searchFilterMo, isUpdate)
                } else {
                    searchbyUsername(searchFilterMo: searchFilterMo, isUpdate)
                }
            } else {
                if let userMO: UserMO = self.dataManager.getAuthProfile() {
                    // If there is no database, create a request with default values
                    searchProfilesDefault(userMO: userMO)
                } else {
                    self.statusMessageHandler.onNext(StatusMessage.unknown(message: "User does't exist"))
                }
            }
        }
    }
    
    // SearchProfiles
    private func searchProfiles(searchFilterMo: SearchFilterMO, _ isUpdate: Bool) {
        profileManager.searchProfiles(gender: searchFilterMo.gender!, ageFrom: Int(searchFilterMo.ageFrom), ageTo: Int(searchFilterMo.ageTo), postcode: searchFilterMo.postcode!, country: searchFilterMo.country ?? "", online: searchFilterMo.status, page: pageIndex, limit: limit, onlyFavorites: false) { [weak self] (result) in
            
            guard let strongself = self else { return }
            strongself.showLoadMore.onNext(false)
            switch result {
            case .failure(let message):
                strongself.failureSearch(with: message)
            case .success(let users):
                strongself.successSearch(with: users, isUpdate)
            }
            strongself.isLoading = false
        }
    }
    
    // SearchbyUsername
    private func searchbyUsername(searchFilterMo: SearchFilterMO, _ isUpdate: Bool) {
        profileManager.searchProfilesByUsername(username: searchFilterMo.username ?? "", page: pageIndex, limit: limit) { [weak self] (result) in
            
            guard let strongself = self else { return }
            strongself.showLoadMore.onNext(false)
            
            switch result {
            case .failure(let message):
                strongself.failureSearch(with: message)
            case .success(let users):
                strongself.successSearch(with: users, isUpdate)
            }
            strongself.isLoading = false
        }
    }
    
    // SearchProfilesDefault
    private func searchProfilesDefault(userMO: UserMO) {
        guard let gender = userMO.gender else {return}
        profileManager.searchProfiles(gender: gender.setOppositeGender(), ageFrom: 18, ageTo: 99, postcode: userMO.postcode!, country: userMO.country!, online: false, page: pageIndex, limit: limit, onlyFavorites: false) { [weak self] (result) in
            
            guard let strongself = self else { return }
            strongself.showLoadMore.onNext(false)
            
            switch result {
            case .failure(let message):
                strongself.failureSearch(with: message)
            case .success(let users):
                strongself.successSearch(with: users, false)
            }
            strongself.isLoading = false
        }
    }
    
    private func successSearch(with users: [SearchFilterResult], _ isUpdate: Bool) {
        switch isUpdate {
        case true:
            self.users.removeAll()
        case false:
            break
        }
        if users.isEmpty {
            self.users.removeAll()
            setupScreenState.onNext(.empty)
        } else {
            self.isLoad = users.count == self.limit
            self.users.append(contentsOf: users)
            self.pageIndex += 1
            setupScreenState.onNext(.search)
        }
    }
    
    private func failureSearch(with message: StatusMessage) {
        users.removeAll()
        setupScreenState.onNext(.empty)
        statusMessageHandler.onNext(message)
    }
    
    func getSearchUserItem(with index: Int) -> SearchFilterResult {
        return users[index]
    }
    
    func showFilter() {
        router.enqueueRoute(with: SearchRouter.RouteType.showFilter)
    }
    
    func loadMoreIfPossible(_ cellIndex: Int) {
        let cellIndex = cellIndex + 1
        if cellIndex % 10 == 0 {
            let collectionPageIndex = cellIndex / 10
            if collectionPageIndex >= pageIndex {
                getProfiles()
            }
        }
    }
    
    func updateData() {
        setupScreenState.onNext(.loading)
        pageIndex = 0
        getProfiles(isUpdate: true)
    }
}

enum SearchScreenSection: Int, CaseIterable {
    case search
    case loadMore
}

enum SearchScreenState {
    case loading
    case empty
    case search
}
