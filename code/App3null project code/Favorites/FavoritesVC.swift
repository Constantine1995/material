//
//  FavoritesVC.swift
//  Linduu
//
//  Created by Constantine Likhachov on 11.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MaterialComponents.MaterialActivityIndicator

class FavoritesVC: UIViewController, MVVMViewController, FriendTableViewProtocol, FriendCellDelegate {
    
    var viewModel: FavoritesVMProtocol!
    let disposeBag = DisposeBag()
    let placeholder = PlaceholderView(type: .noFavoriteFriends)
    
    private let tableView: FriendTableView = FriendTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar(with: .title, "Favorites_title".localized())
        disableLocationTabBarItem()
        addFreindTableView(tableView)
        setupObservers()
        viewModel.viewDidLoad()
        self.enableNoInternetPlaceholder()
    }
    
    deinit {
        print("deinit favoritesVC")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableLocationTabBarItem()
    }
    
    func setupObservers() {
        viewModel.setupScreenState.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (screenState) in
            guard let self = self else {return}
            self.tableView.reloadData()
            
            switch screenState {
            case .loading:
                self.showActivitiIndicator(value: true)
                self.placeholder.removeFromSuperview()
            case .empty:
                self.view.addSubview(self.placeholder)
                self.placeholder.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                self.placeholder.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                self.placeholder.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.placeholder.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.showActivitiIndicator(value: false)
            case .profiles:
                self.placeholder.removeFromSuperview()
                self.showActivitiIndicator(value: false)
            }
        }).disposed(by: disposeBag)
        
        viewModel.showLoadMore.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (showLoadMoreCell) in
            guard let self = self else {return}
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        viewModel.statusMessageHandler.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (statusMessage) in
            guard let strongSelf = self else {return}
            strongSelf.showActivitiIndicator(value: false)
            if statusMessage.code == -2 {
                strongSelf.viewModel.showNotEnoughCoinsPopup()
            } else if statusMessage.code != 0 {
                strongSelf.handleStatusMessage(statusMessage)
            } else {
                strongSelf.placeholder.removeFromSuperview()
            }
        }).disposed(by: disposeBag)
        
        viewModel.completionRequest.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (text) in
            guard let strongSelf = self else {return}
            strongSelf.showAlert(text)
        }).disposed(by: disposeBag)
    }
    
    func configMoreButton(at index: Int) {
        viewModel?.userIndex = index
        viewModel.showPopup()
    }
}


extension FavoritesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRow(in: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch FriendsScreenSection(rawValue: indexPath.section)! {
        case .friend:
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.cellIdentifier, for: indexPath) as! FriendCell
            let index = indexPath.row
            let user = viewModel.getUsers(at: index)
            cell.config(at: index, user: user)
            cell.delegate = self
            return cell
        case .loadMore:
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendLoadMoreCell.cellIdentifier, for: indexPath) as! FriendLoadMoreCell
            return cell
        }
    }
}
