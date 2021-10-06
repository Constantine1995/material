//
//  FavoritesPresenter.swift
//  Instat
//
//  Created by Constantine Likhachov on 12.07.2021.
//  Copyright © 2021 Natife. All rights reserved.
//

import UIKit

final class FavoritesPresenter {

    public class TableSectionItem<T> {
        let items: [T]
        var language: String
        let title: String?
        
        init(title: String?, items: [T], language: String) {
            self.title = title
            self.items = items
            self.language = language
        }
    }
    
    // MARK: - Private properties -
    private weak var view: FavoritesModuleView?
    private let interactor: FavoritesModuleInteractor
    private let router: FavoritesModuleRouter
    private var dataSource: [TableSectionItem<FavoritesItem>] = []
    
    // MARK: - Lifecycle -
    init(view: FavoritesModuleView, interactor: FavoritesModuleInteractor, router: FavoritesModuleRouter) {
        self.view = view
        self.interactor = interactor
        self.router = router
        self.interactor.delegate = self
    }
    
    private func fetchData() {
        self.view?.startLoading()
        self.interactor.getUserFavorites { (result) in
            self.view?.stopLoading()
            switch result {
            case .success(let response):
                let grouped = Dictionary(grouping: response, by: { $0.itemType})
                
                var result = grouped
                    .map { (enumerator) -> TableSectionItem<FavoritesItem> in
                        let sectionTitle = self.interactor.getLexic(enumerator.key.title)
                        
                        return TableSectionItem(
                            title: sectionTitle,
                            items: enumerator.value,
                            language: self.interactor.languageId
                        )
                    }
                
                result.sort { (lhs, rhs) in
                    lhs.title ?? "" > rhs.title ?? ""
                }
                
                if result.isEmpty {
                    result = FavoritesItemType.allCases.map { type -> TableSectionItem<FavoritesItem> in
                        let sectionTitle = self.interactor.getLexic(type.title)
                        return TableSectionItem(
                            title: sectionTitle,
                            items: [],
                            language: self.interactor.languageId
                        )
                    }
                }
                
                self.dataSource = result
                
                self.view?.updateView()
            case .failure(let error):
                debugPrint(error.localizedDescription)
                break
            }
        }
    }
    
}

// MARK: - Extensions -
extension FavoritesPresenter: FavoritesModulePresenter {
    func selectItem(index: IndexPath) {
        guard let section = self.section(by: index.section) else {
            return
        }
        guard let item = self.item(by: index.row, from: section) else {
            return
        }
        let id = item.itemId
        let sportType = item.sportId
        
        switch item.itemType {
        case .tournament:
            self.router.openProfile(id: id, sportType: sportType, searchType: .tournament)
        case .team:
            self.router.openProfile(id: id, sportType: sportType, searchType: .team)
        case .player:
            self.router.openProfile(id: id, sportType: sportType, searchType: .player)
        }
    }
    
    var sectionCount: Int {
        return self.dataSource.count
    }
    
    func viewDidLoad() {
        self.fetchData()
    }
    
    func section(by index: Int) -> FavoritesPresenter.TableSectionItem<FavoritesItem>? {
        guard index < self.dataSource.count else {
            return nil
        }
        
        return self.dataSource[index]
    }
    
    func item(by index: Int, from section: TableSectionItem<FavoritesItem>) -> FavoritesItem? {
        guard index < section.items.count else {
            return nil
        }
        return section.items[index]
    }
}

extension FavoritesPresenter: FavoritesInteractorDelegate {
    func reload() {
        self.fetchData()
    }
    
    func startLoading() {
        self.view?.startLoading()
    }
    
    func stopLoading() {
        self.view?.stopLoading()
    }
}
