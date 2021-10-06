//
//  HomeViewController.swift
//  Instat
//
//  Created by Alexey Shaforostov on 11.01.2021.
//  Copyright © 2021 Natife. All rights reserved.
//

import UIKit

final class HomeViewController: BaseViewController {
    
    // MARK: - Private properties -
    
    @IBOutlet private weak var favoritesContainer: UIView!
    @IBOutlet private weak var favoritesWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var containerTop: NSLayoutConstraint!
    @IBOutlet private weak var collectionWidth: NSLayoutConstraint!
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                FocusedCell.self,
                forCellWithReuseIdentifier: FocusedCell.identifier
            )
            
            collectionView.register(
                CollectionSpinnerFooter.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: CollectionSpinnerFooter.identifier
            )
            
            collectionView.register(
                UnavaliableMatchCell.nib,
                forCellWithReuseIdentifier: UnavaliableMatchCell.identifier
            )
            
            collectionView.register(
                PaidMatchCell.nib,
                forCellWithReuseIdentifier: PaidMatchCell.identifier
            )
            
            collectionView.register(
                PreviewMatchCell.nib,
                forCellWithReuseIdentifier: PreviewMatchCell.identifier
            )
            
            collectionView.register(
                UICollectionViewCell.self,
                forCellWithReuseIdentifier: UICollectionViewCell.identifier
            )
                        
            collectionView.register(
                HeaderMatchView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: HeaderMatchView.identifier
            )
            collectionView.collectionViewLayout = self.layout
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    
    @IBOutlet private weak var navigationBarView: UIView!
    
    @IBOutlet private weak var leftButton: HomeCalendarButton! {
        didSet {
            leftButton.image = Asset.leftChevron.image
        }
    }
    
    @IBOutlet private weak var calendarLabel: UILabel! {
        didSet {
            calendarLabel.text = self.presenter.currentDate.calendarDate.uppercased()
            calendarLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        }
    }
    
    @IBOutlet private weak var rightButton: HomeCalendarButton! {
        didSet {
            rightButton.image = Asset.rightChevron.image
        }
    }
    
    private let languageService: LanguageManager = DIContainer.default.languageManager
    private var lockButtonTitle: UIImage {
        return presenter.lock
    }
    
    private var tournamentButtonTitle: String {
        return  languageService.getLexic(for: presenter.tournament) ?? "Турнир?"
    }
    
    private var filterButtonTitle: String {
        return languageService.getLexic(for: presenter.filter) ?? "Live?"
    }
    
    private var scoreButtonTitle: String {
        return languageService.getLexic(for: presenter.score) ?? "Счет?"
    }
    
    private var sportButtonTitle: String {
        return languageService.getLexic(for: presenter.sport) ?? "Спорт?"
    }
    
    private lazy var stackView: UIStackView = {
        $0.spacing = 40.0
        $0.axis = .horizontal
        return $0
    }(UIStackView())
    
    private func setupView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBarView.addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: navigationBarView.topAnchor, constant: 40.0),
            stackView.trailingAnchor.constraint(equalTo: navigationBarView.trailingAnchor, constant: -40.0),
            stackView.bottomAnchor.constraint(equalTo: navigationBarView.bottomAnchor, constant: -41.0),
        ])
    }
    
    private lazy var layout: UICollectionViewCompositionalLayout = {
        let headerSize = NSCollectionLayoutSize(widthDimension: .estimated(1.0), heightDimension: .absolute(78.0))
        let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(self.presenter.defaultCellSize.width + 69),
            heightDimension: .absolute(self.presenter.defaultCellSize.height))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 69)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(1.0),
            heightDimension: .absolute(self.presenter.defaultCellSize.height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = .init(top: 0, leading: 0, bottom: 50, trailing: 0)
        section.boundarySupplementaryItems = [headerSupplementary]
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }()
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    // MARK: - Public properties -
    
    var presenter: HomeModulePresenter!
    
    // MARK: - Lifecycle -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.drawBackground = false
    }
    
    // TODO: Временное решение, потому что нету API.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.presenter.fetchItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter.viewDidLoad()
        self.favoritesWidthConstraint.constant = 0
        collectionWidth.constant = UIScreen.main.bounds.width - 100
    }
    
    override func startLoading() {
        super.startLoading()
        self.collectionView.isHidden = true
    }
    
    override func stopLoading() {
        super.stopLoading()
        self.collectionView.isHidden = false
    }
}

// MARK: - Extensions -

extension HomeViewController: HomeModuleView {
    func showFavorites(value: Bool) {
        self.favoritesWidthConstraint.constant = value ? 440 : 0
        containerTop.constant = value ? -35 : 50
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        collectionView.reloadData()
    }
    
    func addModule(module: UIViewController) {
        
        module.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChild(module)
        
        self.favoritesContainer.addSubview(module.view)
        
        NSLayoutConstraint.activate([
            module.view.leadingAnchor.constraint(equalTo: favoritesContainer.leadingAnchor),
            module.view.trailingAnchor.constraint(equalTo: favoritesContainer.trailingAnchor),
            module.view.topAnchor.constraint(equalTo: favoritesContainer.topAnchor),
            module.view.bottomAnchor.constraint(equalTo: favoritesContainer.bottomAnchor)
        ])
        module.didMove(toParent: self)
    }
    
    func updateView() {
        self.collectionView.reloadData()
    }
    
    func invalidateLayoutCollectionView() {
        let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionInset.left = 20
        layout?.sectionInset.right = 0
        layout?.invalidateLayout()
    }
    
    private func setNewInsetCollectionView() {
        let favoritesConstraint = self.favoritesWidthConstraint.constant
        let left = favoritesConstraint == 440 ? 40 : 0
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: CGFloat(left), bottom: 0, right: 0)
    }
    
    func showError() {}
}

extension HomeViewController: UICollectionViewDelegate {}
extension HomeViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.presenter.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.itemBySection(section: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String, at indexPath: IndexPath) {
        guard elementKind == UICollectionView.elementKindSectionFooter else { return }
        self.presenter.loadMore()
    }
    
    func collectionView( _ collectionView: UICollectionView,
                         cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let model = presenter.item(by: indexPath.row, section: indexPath.section) else {
            let cell = collectionView.dequeCell(type: UICollectionViewCell.self, indexPath: indexPath)
            return cell
        }

        let showScore = presenter.showScore
        let isShowScore = presenter.isShowScore

        let configureBlock: (FocusedCell) -> Void = { cell in

            cell.didSelectCell = { [weak self] cell in
                guard let indexPath = self?.collectionView.indexPath(for: cell) else {
                    return
                }
                self?.presenter.didSelectItem(by: indexPath.row)
            }

            if let matchCell = cell as? MatchCellProtocol {
                let infoModel = self.presenter.getTournamentsInfo(with: model)
                matchCell.configure(with: model, infoModel: infoModel, showScore: showScore, isShowScore: isShowScore)
            }
        }

        if !model.item.isAvailable {
            let cell = collectionView.dequeCell(type: UnavaliableMatchCell.self, indexPath: indexPath)
            configureBlock(cell)
            return cell
        }

        if !model.item.startDate.isOngoining {
            let cell = collectionView.dequeCell(type: PaidMatchCell.self, indexPath: indexPath)
            configureBlock(cell)
            return cell
        } else {
            let cell = collectionView.dequeCell(type: PreviewMatchCell.self, indexPath: indexPath)
            configureBlock(cell)
            return cell
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        guard let _ = context.nextFocusedView as? TabBarTableViewCell else {
            setNewInsetCollectionView()
            return
        }
        
        guard let _ = context.previouslyFocusedView as? TabBarTableViewCell else {
            setNewInsetCollectionView()
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionFooter {
            return collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: CollectionSpinnerFooter.identifier,
                for: indexPath
            )
        } else {
            
            let headerView = collectionView.dequeueSupplementaryView(
                type: HeaderMatchView.self,
                kind: kind,
                indexPath: indexPath)
            
            headerView.setText(presenter.sectionTitle[indexPath.section].tournamentName)

            headerView.isHidden = self.favoritesWidthConstraint.constant == 440 ? true : false
            return headerView
        }
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        guard self.presenter.canLoadMore() else {
            return .zero
        }
        return CGSize(width: 0, height: 200)
    }
}
