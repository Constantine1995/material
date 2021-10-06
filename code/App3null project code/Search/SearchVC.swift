//
//  SearchVC.swift
//  Linduu
//
//  Created by Constantine Likhachov on 10.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MaterialComponents.MaterialActivityIndicator

class SearchVC: UIViewController, MVVMViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewModel: SearchVMProtocol!
    var disposeBag = DisposeBag()
    let activityIndicator = MDCActivityIndicator()
    let placeholder = PlaceholderView(type: .noSearchedProfiles)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configCollectionView()
        setupNavigationBar(with: .search({ [weak self] in
            self?.viewModel.showFilter()
        }), "Search_title".localized())
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.addSubview(self.activityIndicator)
        activityIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        
        viewModel.viewDidLoad()
        viewModel.viewWillAppear()
        self.enableNoInternetPlaceholder()
        
        viewModel.setupScreenState.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (screenState) in
            guard let self = self else {return}
            self.collectionView.reloadData()
            self.collectionView.performBatchUpdates({
                UIView.performWithoutAnimation {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }, completion: nil)
            switch screenState {
            case .loading:
                self.showActivitiIndicator(value: true)
                self.placeholder.removeFromSuperview()
            case .search:
                self.placeholder.removeFromSuperview()
                self.showActivitiIndicator(value: false)
            case .empty:
                self.view.addSubview(self.placeholder)
                self.placeholder.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                self.placeholder.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                self.placeholder.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.placeholder.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.showActivitiIndicator(value: false)
            }
        }).disposed(by: disposeBag)
        
        viewModel.showLoadMore.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] _ in
            guard let self = self else {return}
            self.collectionView.reloadData()
            self.collectionView.performBatchUpdates({
                UIView.performWithoutAnimation {
                    self.collectionView.reloadSections(IndexSet(integer: 1))
                }
            }, completion: nil)
        }).disposed(by: disposeBag)
        
        viewModel.statusMessageHandler.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (statusMessage) in
            guard let strongSelf = self else {return}
            strongSelf.showActivitiIndicator(value: false)
            if statusMessage.code != 0 {
                strongSelf.handleStatusMessage(statusMessage)
            } else {
                strongSelf.placeholder.removeFromSuperview()
            }
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name:NSNotification.Name("updateSearchProfiles"), object: nil)
    }
    
    private func configCollectionView() {
        collectionView.register(SearchLoadMoreCell.self, forCellWithReuseIdentifier: SearchLoadMoreCell.cellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        collectionView.showsVerticalScrollIndicator = false
    }
    
    @objc func update() {
        viewModel?.updateData()
    }
}

extension SearchVC: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRow(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.loadMoreIfPossible(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch SearchScreenSection(rawValue: indexPath.section)! {
        case .search:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCell.cellIdentifire, for: indexPath) as! SearchCell
            cell.config(with: viewModel.getSearchUserItem(with: indexPath.row))
            return cell
        case .loadMore:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchLoadMoreCell.cellIdentifier, for: indexPath) as! SearchLoadMoreCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch SearchScreenSection(rawValue: indexPath.section)! {
        case .search:
            let padding: CGFloat = 20
            let collectionViewSize = collectionView.frame.size.width - padding
            return CGSize(width: collectionViewSize / 2, height: collectionViewSize * 0.6)
        case .loadMore:
            return CGSize(width: collectionView.frame.width-16, height: 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch SearchScreenSection(rawValue: indexPath.section)! {
        case .search:
            viewModel.didSelectItem(user: viewModel.getSearchUserItem(with: indexPath.row))
        case .loadMore:
            break
        }
        
    }
}
