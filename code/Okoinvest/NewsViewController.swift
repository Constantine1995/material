//
//  NewsViewController.swift
//  Okoinvest
//
//  Created by constantine on 09.03.2021.
//

import UIKit
import Firebase
import Contacts
import RxSwift
import RxCocoa
import SafariServices
import SideMenu

class NewsViewController: BaseViewController, SideMenuNavigationControllerDelegate {
    
    enum NewsType {
        case news
        case bookmarks
        case category
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var filterBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var categoriesButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var dropDownHeaderView: UIView!
    
    private let contactStore = CNContactStore()
    private var refresher: UIRefreshControl!
    
    private var news: [NewsModel] = []
    private var newsHeader: [NewsModel] = []
    private var currentCategory: CategoryModel!
    
    private var type: NewsType = .news
    private var pageNumber: Int = 10
    private var hasMoreNews: Bool = true
    private var isDarkContentBackground = false
    var menuLeftNavigationController: SideMenuNavigationController!
    
    let transparentView = UIView()
    let tableView = UITableView()
    var dataSource = [String]()
    var userTopics = [String]()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        view.showToastActivity()
        checkContacts()
        setupRX()
        setupTableView()
        setupMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(true, animated: animated)
        LogManager.shared().sendLog(with: .tab_news)
        removeDropDown()
        setupCollectionView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeStatusBar()
    }
    
    private func setupCollectionView() {
        collectionView.register(R.nib.newsCollectionViewCell)
        collectionView.register(R.nib.bigNewsCollectionViewCell)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        
        refresher = UIRefreshControl()
        collectionView.addSubview(refresher)
        refresher.addTarget(self, action: #selector(reloadNews), for: .valueChanged)
        collectionView.backgroundColor = UIColor.white
        
        news.removeAll()
        newsHeader.removeAll()
        hasMoreNews = true
        
        if type == .news {
            loadFirstData()
        } else if type == .category {
            sendGetNewsForCategory(currentCategory, page: pageNumber, animated: false)
        } else {
            refresher.endRefreshing()
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DropDownCell.self, forCellReuseIdentifier: DropDownCell.cellIdentifier)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
    }
    
    func setupRX() {
        menuButton.rx.tap.bind { [weak self] in
            guard let strongSelf = self else { return }
            guard let menu = SideMenuManager.default.leftMenuNavigationController else { return }
            strongSelf.present(menu, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        categoriesButton.rx.tap.bind { [weak self] in
            guard let strongSelf = self else { return }
            var array: [String] = [R.string.localizable.news(), R.string.localizable.bookmarks()]
            for item in Constants.categories {
                array.append(item.name)
            }
            strongSelf.dropDownHeaderView.isHidden = !strongSelf.dropDownHeaderView.isHidden
            strongSelf.dropDownHeaderView.isHidden = true
            strongSelf.dataSource = array
            strongSelf.addDropDown()
        }.disposed(by: disposeBag)
        
        closeButton.rx.tap.bind { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.removeDropDown()
        }.disposed(by: disposeBag)
    }
    
    func setupMenu() {
        menuLeftNavigationController = SideMenuNavigationController(rootViewController: R.storyboard.menu.menuViewController()!)
        menuLeftNavigationController.setNavigationBarHidden(true, animated: true)
        menuLeftNavigationController.sideMenuDelegate = self
        SideMenuManager.default.leftMenuNavigationController = menuLeftNavigationController
        menuLeftNavigationController.presentingViewControllerUserInteractionEnabled = false
        menuLeftNavigationController.dismissOnPush = true
        menuLeftNavigationController.menuWidth = UIScreen.main.bounds.width / 1.5
        menuLeftNavigationController.presentationStyle = .menuSlideIn
        menuLeftNavigationController.statusBarEndAlpha = 0.0
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    func addDropDown() {
        dropDownHeaderView.roundCorners([.bottomLeft, .bottomRight], radius: 15)
        setStatusBarColors(color: R.color.dropDown() ?? .white)
        isDarkContentBackground = true
        setNeedsStatusBarAppearanceUpdate()
        
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        let frameWindows = window?.frame ?? self.view.frame
        transparentView.frame = CGRect(x:  frameWindows.origin.x, y: frameWindows.origin.y + self.getStatusBarHeight(), width: frameWindows.width, height: CGFloat(frameWindows.height))
        
        self.view.addSubview(transparentView)
        self.view.bringSubviewToFront(self.dropDownHeaderView)
        tableView.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y + getStatusBarHeight() + 40, width: self.view.frame.width, height: 0)
        self.view.addSubview(tableView)
        
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        tableView.reloadData()
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeDropDown))
        transparentView.addGestureRecognizer(tapgesture)
        
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0.9
            self.tableView.frame = CGRect(x:  self.view.frame.origin.x, y:  self.view.frame.origin.y + self.getStatusBarHeight() + 40, width:  self.view.frame.width, height: CGFloat(self.dataSource.count * 50))
        }, completion: nil)
    }
    
    @objc func removeDropDown() {
        setStatusBarColors(color: .white)
        isDarkContentBackground = false
        setNeedsStatusBarAppearanceUpdate()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0
            self.tableView.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y + self.getStatusBarHeight() + 40, width: self.view.frame.width, height: 0)
            self.dropDownHeaderView.isHidden = true
        }, completion: nil)
    }
    
    @objc func tapHeader() {
        if newsHeader.first?.isOpenWeb != nil, let link = newsHeader.first?.link {
            if let isWeb = newsHeader.first?.isOpenWeb, isWeb == true {
                showWebView(with: link)
            } else {
                showHeaderArticleVC()
            }
        } else {
            showHeaderArticleVC()
        }
    }
    
    private func setStatusBarColors(color: UIColor) {
        removeStatusBar()
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if #available(iOS 13.0, *) {
            let statusBar = UIView(frame: window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
            statusBar.backgroundColor = color
            statusBar.tag = 100
            window?.addSubview(statusBar)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if isDarkContentBackground {
            return .lightContent
        } else {
            return .darkContent
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentSize = scrollView.contentSize.height
        
        if contentSize - scrollView.contentOffset.y <= scrollView.bounds.height {
            didScrollToBottom()
        }
    }
    
    private func didScrollToBottom() {
        loadNextData()
    }
}

// MARK: - SFSafariViewControllerDelegate
extension NewsViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        tabBarController?.tabBar.isHidden = false
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Public Methods
extension NewsViewController {
    
    func showArticleVC(currentNews: [NewsModel]) {
        if let newViewController = R.storyboard.article.articleViewController(), !news.isEmpty {
            newViewController.currentNews = currentNews
            LogManager.shared().sendLog(with: .article_open)
            newViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(newViewController, animated: true)
        }
    }
    
    func showHeaderArticleVC() {
        if let newViewController = R.storyboard.article.articleViewController(), !newsHeader.isEmpty {
            newViewController.currentNews = newsHeader
            LogManager.shared().sendLog(with: .article_open)
            newViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(newViewController, animated: true)
        }
    }
    
    func showWebView(with url: String) {
        if let url = URL(string: url) {
            let config = SFSafariViewController.Configuration()
            let vc = SFSafariViewController(url: url, configuration: config)
            vc.delegate = self
            tabBarController?.tabBar.isHidden = true
            navigationController?.pushViewController(vc)
        }
    }
    
}

// MARK: - Private Methods
private extension NewsViewController {
    
    func loadFirstData() {
        DatabaseManager.shared().getUserTopics { [weak self] (userTopics) in
            if let topics = userTopics, !topics.isEmpty {
                let userTopics = topics.map { $0.name}
                self?.getFirstNews(userTopics: userTopics)
            } else {
                self?.getFirstNews(userTopics: [])
            }
        }
    }
    
    func loadNextData() {
        DatabaseManager.shared().getUserTopics { [weak self] (userTopics) in
            if let topics = userTopics, !topics.isEmpty {
                let userTopics = topics.map { $0.name}
                self?.getNextNews(userTopics: userTopics)
            } else {
                self?.getNextNews(userTopics: [])
            }
        }
    }
    
    private func getFirstNews(userTopics: [String]) {
        DatabaseManager.shared().loadFirstData(page: self.pageNumber, topics: userTopics) { [weak self] (news, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                print("error = \(error)")
                return
            }
            strongSelf.news = news ?? []
            if strongSelf.news.first != nil {
                strongSelf.newsHeader.append(strongSelf.news.first!)
                strongSelf.news.removeFirst()
            }
            strongSelf.collectionView.reloadData()
            strongSelf.refresher.endRefreshing()
            strongSelf.view.hideLoading()
            strongSelf.userTopics.removeAll()
        }
    }
    
    private func getNextNews(userTopics: [String]) {
        DatabaseManager.shared().loadNextData(page: self.pageNumber, topics: userTopics) { [weak self] (news, error) in
            guard let strongSelf = self else { return }
            
            if let error = error {
                print("error = \(error)"); return
            }
            
            if let news = news {
                strongSelf.news.append(contentsOf: news)
                strongSelf.collectionView.reloadData()
                strongSelf.refresher.endRefreshing()
                strongSelf.userTopics.removeAll()
            }
        }
    }
    
    func tryOpenChannel() {
        let user = UserData.shared()
        guard let chatID = user.openChannelID else { return }
        NotificationManager.shared().openChatViewController(chatID)
        user.openChannelID = nil
    }
    
    @objc func reloadNews() {
        news.removeAll()
        newsHeader.removeAll()
        hasMoreNews = true
        
        if type == .news {
            loadFirstData()
        } else if type == .category {
            sendGetNewsForCategory(currentCategory, page: pageNumber, animated: false)
        } else {
            refresher.endRefreshing()
        }
    }
    
    func loadNewsForBookmarks() {
        sendGetNewsForBookmarks()
    }
    
    func loadNewsWithCategory(_ model: CategoryModel) {
        currentCategory = model
        news.removeAll()
        newsHeader.removeAll()
        hasMoreNews = true
        sendGetNewsForCategory(model, page: pageNumber)
    }
    
    func checkContacts() {
        let db = RealmDB.shared()
        let oldNumbers = db.getNumbers()
        let oldEmails:[ContactEmailModel] = db.getEmails()
        if oldEmails.isEmpty && oldNumbers.isEmpty {
            notificationManager.reqestAuthorization()
        }
    }
}

// MARK: - Networking
private extension NewsViewController {
    func sendConfigRequest() {
        networkManager.postConfigRequest { response in
            if let response = response {
                if response.complete {
                    self.loadNextData()
                }
            }
        }
    }
    
    func sendGetNewsForBookmarks() {
        view.makeToastActivity()
        let user = UserData.shared()
        let items = user.bookmarkNewsId
        news.removeAll()
        newsHeader.removeAll()
        for item in items {
            networkManager.sendGetNewsRequest(withId: item) { (response) in
                if let response = response {
                    self.news.append(contentsOf: response.news)
                    if self.news.first != nil {
                        self.newsHeader.append(self.news.first!)
                        
                        self.news.removeFirst()
                    }
                    self.collectionView.reloadData()
                    self.view.hideLoading()
                }
            }
        }
    }
    
    func sendGetNewsForCategory(_ category: CategoryModel, page: Int, animated: Bool = true) {
        if animated {
            view.showToastActivity()
        }
        networkManager.sendGetNewsRequest(withCategoryId: category.id, page: page) { (response) in
            if let response = response {
                if page == response.pages {
                    self.hasMoreNews = false
                }
                if page == 1 {
                    self.news = response.news
                    if self.news.first != nil {
                        self.newsHeader.append(self.news.first!)
                        self.news.removeFirst()
                    }
                } else {
                    for item in response.news {
                        let hasItem = self.news.contains(where: { (obj) -> Bool in
                            return obj.id == item.id
                        })
                        if !hasItem {
                            self.news.append(item)
                        }
                    }
                }
                if self.news.first != nil {
                    self.newsHeader.append(self.news.first!)
                    self.news.removeFirst()
                }
                self.collectionView.reloadData()
                self.refresher.endRefreshing()
            }
            self.view.hideLoading()
        }
        self.pageNumber += 1
    }
}

//MARK: - FetchingContacts
extension NewsViewController {
   
    func fetchContactsNumbers() -> [ContactNumberModel] {
        var contactsNumbers = [ContactNumberModel]()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                    CNContactPhoneNumbersKey,
                    CNContactEmailAddressesKey] as [Any]
        var request: CNContactFetchRequest!
        if let key = keys as? [CNKeyDescriptor] {
            request = CNContactFetchRequest(keysToFetch: key)
        }
        do {
            try self.contactStore.enumerateContacts(with: request) { contact, stop in
                for number in contact.phoneNumbers {
                    let human = ContactNumberModel()
                    human.name = contact.givenName + " " + contact.middleName + " " + contact.familyName
                    human.phone = self.formatPhone(phone: number.value.stringValue )
                    contactsNumbers.append(human)
                }
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return contactsNumbers
    }
    
    func formatPhone(phone: String) -> String {
        var new = ""
        for char in phone.charactersArray {
            if char.isLetter || char.isNumber {
                new.append(char)
            }
        }
        return new
    }
    
    func fetchContactsEmails() -> [ContactEmailModel] {
        var contactsEmails = [ContactEmailModel]()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                    CNContactPhoneNumbersKey,
                    CNContactEmailAddressesKey] as [Any]
        var request: CNContactFetchRequest!
        if let key = keys as? [CNKeyDescriptor] {
            request = CNContactFetchRequest(keysToFetch: key)
        }
        do {
            try self.contactStore.enumerateContacts(with: request) { contact, stop in
                for email in contact.emailAddresses {
                    let human = ContactEmailModel()
                    human.name = contact.givenName + " " + contact.middleName + " " + contact.familyName
                    human.email = email.value.substring(from: 0).lowercased()
                    contactsEmails.append(human)
                }
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return contactsEmails
    }
}


extension NewsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return news.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.bigNewsCollectionViewCell, for: indexPath)!
            if let news = newsHeader.first {
                headerView.setup(news: news)
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHeader))
                headerView.addGestureRecognizer(tapGestureRecognizer)
            }
            return headerView
            
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = indexPath.row
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.newsCollectionViewCell, for: indexPath)!
        if row < news.count {
            cell.setup(news: news[row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 212)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var padding: CGFloat = 20
        padding = UIScreen.width <= 380 ? 20 : 30
        return UIEdgeInsets(top: 16, left: padding, bottom: 16, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentNews = Array(news[indexPath.row...news.count - 1])
        
        if currentNews.first?.isOpenWeb != nil, let link = currentNews.first?.link {
            if let isWeb = currentNews.first?.isOpenWeb, isWeb == true {
                showWebView(with: link)
            } else {
                showArticleVC(currentNews: currentNews)
            }
        } else {
            showArticleVC(currentNews: currentNews)
        }
    }
}

extension NewsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DropDownCell.cellIdentifier, for: indexPath) as! DropDownCell
        cell.setup(title: dataSource[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        removeDropDown()
        let index = indexPath.row
        if index == 0 {
            self.type = .news
            self.reloadNews()
        } else if index == 1 {
            self.type = .bookmarks
            self.loadNewsForBookmarks()
        } else {
            self.type = .category
            self.loadNewsWithCategory(Constants.categories[index - 2])
        }
    }
}
