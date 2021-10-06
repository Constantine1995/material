//
//  NearbyVC.swift
//  Linduu
//
//  Created by Constantine Likhachov on 24.01.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MaterialComponents.MaterialActivityIndicator

class NearbyVC: UIViewController, MVVMViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    lazy var placeholder = PlaceholderView(type: .noNearby({ [weak self] in
        self?.showPermissionAlert()
    }))
    
    var viewModel: NearbyVMProtocol!
    var disposeBag = DisposeBag()
    let activityIndicator = MDCActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configCollectionView()
        setupNavigationBar(with: .menuTitle, "Nearby_title".localized())
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.addSubview(self.activityIndicator)
        activityIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        
        viewModel.viewDidLoad()
        setupObservers()
        self.enableNoInternetPlaceholder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }
    
    private func configCollectionView() {
        collectionView.register(NearbyLoadMoreCell.self, forCellWithReuseIdentifier: NearbyLoadMoreCell.cellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        collectionView.showsVerticalScrollIndicator = false
    }
    
    func setupObservers() {
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
                self.activityIndicator.startAnimating()
                self.placeholder.removeFromSuperview()
            case .empty:
                self.view.addSubview(self.placeholder)
                self.placeholder.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                self.placeholder.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                self.placeholder.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.placeholder.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.activityIndicator.stopAnimating()
            case .nearby:
                self.placeholder.removeFromSuperview()
                self.activityIndicator.stopAnimating()
            }
        }).disposed(by: disposeBag)
        
        viewModel.showLoadMore.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (showLoadMoreCell) in
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
            strongSelf.activityIndicator.stopAnimating()
            if statusMessage.code != 0 {
                strongSelf.handleStatusMessage(statusMessage)
            } else {
                strongSelf.placeholder.removeFromSuperview()
            }
        }).disposed(by: disposeBag)
    }
}

extension NearbyVC: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
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
        
        switch NearbyScreenSection(rawValue: indexPath.section)! {
        case .nearby:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NearbyCell.cellIdentifire, for: indexPath) as! NearbyCell
            cell.config(with: (viewModel?.getNearbyUserItem(with: indexPath.row))!)
            return cell
            
        case .loadMore:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NearbyLoadMoreCell.cellIdentifier, for: indexPath) as! NearbyLoadMoreCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch NearbyScreenSection(rawValue: indexPath.section)! {
        case .nearby:
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
        switch NearbyScreenSection(rawValue: indexPath.section)! {
        case .nearby:
            viewModel.didSelectItem(user: viewModel.getNearbyUserItem(with: indexPath.row))
        case .loadMore:
            break
        }
        
    }
}
