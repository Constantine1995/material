//
//  TrainingsVC.swift
//  c4institut
//
//  Created by Constantine Likhachov on 25.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit
import Combine
import SideMenu

class TrainingsVC: BaseViewController, MVVMViewController, TableViewProtocol, TableViewDelegate {
    
    var viewModel: TrainingsVMProtocol!
    private let tableView: TableView = TableView()
    private var cancellables: [AnyCancellable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar(title: Localizations.Trainings.title, isMenu: true)
        tableView.tableViewDelegate = self
        addTableView(tableView)
        
        viewModel.viewDidLoad()
        viewModel.fetchTrainings()
        
        viewModel.reloadTableView.sink { [weak self] () in
            guard let self = self else {return}
            self.tableView.reloadData()
        }.store(in: &self.cancellables)
        
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    func numberOfSections() -> Int {
        return viewModel.numberOfSections()
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        return viewModel.numberOfRow(in: section)
    }
    
    func sectionTitle(for section: Int) -> String {
        return viewModel.sectionTitle(for: section)
    }
    
    func getCellVM(at indexPath: IndexPath) -> TableViewCellVM? {
        return viewModel.getTableViewCellVM(at: indexPath)
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        viewModel.cellDidSelect(at: indexPath)
    }
    
    deinit {
       print(ConsoleHeader.dealloc(String(describing: self)))
    }
}

