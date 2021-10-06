//
//  NudgeVC.swift
//  Linduu
//
//  Created by Constantine Likhachov on 06.01.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MaterialComponents.MaterialActivityIndicator

class NudgeVC: UIViewController, MVVMViewController {
    
    var viewModel: NudgeVMProtocol!
    let nudgeSegmentControl = NudgeSegmentControl()
    let disposeBag = DisposeBag()
    let activityIndicator = MDCActivityIndicator()
    let placeholder = PlaceholderView(type: .noNudge)
    
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar(with: .title, "Nudge_title".localized())
        setupUI()
        disableLocationTabBarItem()
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.addSubview(self.activityIndicator)
        activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        setupObservers()
        viewModel.loadPokes()
        
    }
    
    func setupUI() {
        tableView.register(FriendLoadMoreCell.self, forCellReuseIdentifier: FriendLoadMoreCell.cellIdentifier)
        tableView.register(UINib(nibName: "FriendCell", bundle:nil), forCellReuseIdentifier:  FriendCell.cellIdentifier)
        view.addSubview(tableView)
        view.addSubview(nudgeSegmentControl)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.tableFooterView = UIView(frame: .zero)
        activityIndicator.cycleColors = [UIColor.AppColor.black]
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(self.activityIndicator)
        activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        
        tableView.topAnchor.constraint(equalTo:  self.nudgeSegmentControl.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let safeLayoutGuide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            nudgeSegmentControl.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor),
            nudgeSegmentControl.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor),
            nudgeSegmentControl.widthAnchor.constraint(equalTo: safeLayoutGuide.widthAnchor),
            nudgeSegmentControl.heightAnchor.constraint(equalToConstant: 36.5)
        ])
        nudgeSegmentControl.segmentedControl.addTarget(self, action: #selector(segmentControlAction), for: .valueChanged)
        
        viewModel.screenState.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (screenState) in
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
                self.placeholder.topAnchor.constraint(equalTo: self.nudgeSegmentControl.bottomAnchor).isActive = true
                self.placeholder.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.showActivitiIndicator(value: false)
            case .pokes:
                self.placeholder.removeFromSuperview()
                self.showActivitiIndicator(value: false)
            case .loadMore:
                break
            }
        }).disposed(by: disposeBag)
        
        viewModel.statusMessageHandler.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (statusMessage) in
            guard let strongSelf = self else {return}
            strongSelf.showActivitiIndicator(value: false)
            if statusMessage.code == -2 {
                strongSelf.viewModel.showNotEnoughCoinsPopup()
            } else if statusMessage.code != 0 {
                strongSelf.handleStatusMessage(statusMessage)
            }
        }).disposed(by: disposeBag)
    }
    
    
    @objc func segmentControlAction(_ segmentedControl: UISegmentedControl) {
        switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            viewModel.showRecievedPokes()
            break
        case 1:
            viewModel.showPokesByMe()
            break
        default:
            break
        }
    }
    
    func setupObservers() {
        viewModel.pokesToShow.bind(to: tableView.rx.items(cellIdentifier: FriendCell.cellIdentifier)){ tableView, user, cell in
            if let cellToUse = cell as? FriendCell {
                cellToUse.config(with: user)
                cellToUse.moreButton.rx.tap.bind {
                    self.viewModel.showPopup(for: user.userId)
                }.disposed(by: self.disposeBag)
            }
        }.disposed(by: disposeBag)
        
        self.tableView.rx.contentOffset.asObservable().subscribe(onNext: { (_) in
            if self.tableView.isNearBottomEdge() {
                self.viewModel.loadPokes()
            }
        }).disposed(by: disposeBag)
            
    }
}


extension UIScrollView {
    func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
        return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}
