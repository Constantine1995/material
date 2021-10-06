//
//  AdminViewController.swift
//  Okoinvest
//
//  Created by constantine on 10.03.2021.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseFirestore

struct DataChat {
    var menuType: MenuType
    var row: Int?
}

class AdminViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vertialMenuButton: UIBarButtonItem!
    @IBOutlet weak var segmentControl: SegmentControl!
    
    private var channelListener: ListenerRegistration?
    private var items: [Channel] = []
    let subject = BehaviorSubject<DataChat?>(value: nil)
    let dataBaseManager = DatabaseManager.shared()
    
    var actions: [(String, UIAlertAction.Style)] = []
    let user = UserData.shared()
    
    let disposeBag = DisposeBag()
    
    let viewBG: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.frame = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.frame ?? .zero
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRX()
        setupTableView()
        setupNavigationBar(with: .hideBack, R.string.localizable.chats())
        segmentControl.segmentedControl.addTarget(self, action: #selector(segmentControlAction), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let storedDate = user.storedDate() {
            let diffs = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: storedDate, to: Date())
            if diffs.minute ?? 0 >= 5 {
                showEnterMasterPassword()
            } else {
                unlockTableView()
            }
        } else {
            showEnterMasterPassword()
        }
    }
    
    private func setupUI() {
        if let navController = navigationController as? BaseNavigationController {
            navController.isDarkContentBackground = false
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private func setupRX() {
        var menuArray = [String]()
        vertialMenuButton.rx.tap.bind { [weak self] in
            guard let strongSelf = self else { return }
            let data = DataChat(menuType: MenuType.vertical, row: nil)
            strongSelf.subject.onNext(data)
        }.disposed(by: disposeBag)
        
        subject.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (data) in
            
            guard let strongSelf = self else { return }
            let isEnabledChats = strongSelf.user.isEnabledChats
            switch data?.menuType {
            case .vertical:
                let text = isEnabledChats ? R.string.localizable.hideChats() : R.string.localizable.showChats()
                menuArray = [text, R.string.localizable.create_chat(), R.string.localizable.accessToChat()]
                
                menuArray.forEach {
                    strongSelf.actions.append(($0, .default))
                }
                strongSelf.actions.append((R.string.localizable.cancel(), .cancel))
                
                MenuActionSheet.showActionsheet(viewController: self!, actions: strongSelf.actions) { [weak self] (index) in
                    guard let strongSelf = self else { return }
                    strongSelf.setupSelectedVerticalWith(index)
                    strongSelf.actions.removeAll()
                }
            case .cell:
                menuArray = [R.string.localizable.edit_chat(), R.string.localizable.invite(), R.string.localizable.deleteChat()]
                
                menuArray.forEach {
                    strongSelf.actions.append(($0, .default))
                }
                strongSelf.actions.append((R.string.localizable.cancel(), .cancel))
                
                MenuActionSheet.showActionsheet(viewController: self!, actions: strongSelf.actions) { [weak self] (index) in
                    guard let strongSelf = self, let row = data?.row else { return }
                    strongSelf.setupSelectedCellWith(index, row: row)
                    strongSelf.actions.removeAll()
                }
            case .none: break
            }
        }).disposed(by: disposeBag)
    }
    
    private func setupTableView() {
        tableView.register(R.nib.chatAdminTableViewCell)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func setupSelectedVerticalWith(_ index: Int) {
        switch index {
        case 0:
            activateChat()
        case 1:
            guard let viewController = R.storyboard.createEditChat.createEditChatVC() else { return }
            navigationController?.pushViewController(viewController, completion: {
                viewController.setupChannel(nil)
            })
        case 2:
            guard let viewController = R.storyboard.accessToChat.accessToChatViewController() else { return }
            navigationController?.pushViewController(viewController)
        default: break
        }
    }
    
    private func setupSelectedCellWith(_ index: Int, row: Int) {
        switch index {
        case 0:
            let channel = items[row]
            guard let viewController = R.storyboard.createEditChat.createEditChatVC() else { return }
            navigationController?.pushViewController(viewController, completion: {
                viewController.setupChannel(channel)
            })
        case 1:
            let channel = items[row]
            let viewController = InvitePopupVC(nibName: R.nib.invitePopupVC.name, bundle: nil)
            viewController.modalPresentationStyle = .overFullScreen
            navigationController?.present(viewController, animated: false, completion: {
                viewController.setupChannel(channel, isFromMenu: true)
            })
        case 2:
            let channel = items[row]
            showAlert(R.string.localizable.want_delete_chat()) {
                self.view.makeToastActivity()
                self.dataBaseManager.removeChat(channel: channel) { [weak self] (result) in
                    guard let strongSelf = self else { return }
                    strongSelf.view.hideToastActivity()
                    switch result {
                    case .success:
                        strongSelf.tableView.reloadData()
                    case .failure(let error):
                        strongSelf.showAlert(error.localizedDescription)
                    }
                }
            } handlerNo: {}
        default: break
        }
    }
    
    @objc func segmentControlAction(_ segmentedControl: UISegmentedControl) {
        switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            print("Chats tableview")
        case 1:
            print("Contacts tableview")
        default:
            break
        }
    }
    
    deinit {
        channelListener?.remove()
    }
}

// MARK: - Private Methods
private extension AdminViewController {
    
    private func activateChat() {
        let masterPassword = user.masterPassword
        let isEnabledChats = user.isEnabledChats
        guard let documentID = user.documentID else { return }
        
        self.showEnterMasterPassword(R.string.localizable.ok(), false, completion: { [weak self] (password) in
            guard let strongSelf = self else { return }
            if let password = password {
                if masterPassword != password.md5 {
                    strongSelf.showAlert(R.string.localizable.passwordNotCorrect()) {
                        strongSelf.unlockTableView()
                    }
                } else {
                    if isEnabledChats {
                        strongSelf.dataBaseManager.activateChats(false, documentID) { (result) in
                            switch result {
                            case .success:
                                strongSelf.unlockTableView()
                            case .failure(let error):
                                strongSelf.showAlert(error.description)
                            }
                        }
                    } else {
                        strongSelf.dataBaseManager.activateChats(true, documentID) { (result) in
                            switch result {
                            case .success:
                                strongSelf.unlockTableView()
                            case .failure(let error):
                                strongSelf.showAlert(error.description)
                            }
                        }
                    }
                }
            } else {
                if let tabBarViewController = TabBarViewController().getTabBarController() {
                    tabBarViewController.selectedIndex = 0
                }
            }
        })
    }
    
    private func showEnterMasterPassword() {
        view.addSubview(viewBG)
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewBG.isHidden = false
        
        let masterPassword = user.masterPassword
        
        self.showEnterMasterPassword(R.string.localizable.ok(), completion: { [weak self] (password) in
            guard let strongSelf = self else { return }
            if let password = password {
                if  masterPassword != password {
                    strongSelf.showAlert(R.string.localizable.passwordNotCorrect()) {
                        strongSelf.showEnterMasterPassword()
                    }
                } else {
                    strongSelf.user.dateLastPin = Date()
                    strongSelf.user.saveDate()
                    strongSelf.unlockTableView()
                }
            } else {
                if let tabBarViewController = TabBarViewController().getTabBarController() {
                    tabBarViewController.selectedIndex = 0
                }
            }
        })
    }
    
    func unlockTableView() {
        viewBG.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        subscribeToChats()
        tableView.reloadData()
    }
    
    func subscribeToChats() {
        view.makeToastActivity()
        channelListener = dataBaseManager.getAdminChannelsList { (querySnapshot, error) in
            self.view.hideToastActivity()
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            snapshot.documentChanges.forEach({ (change) in
                self.handleDocumentChange(change)
            })
        }
    }
    
    func handleDocumentChange(_ change: DocumentChange) {
        guard let channel = Channel.init(document: change.document) else { return }
        switch change.type {
        case .added:
            addChannelToTable(channel)
        case .modified:
            updateChannelInTable(channel)
        case .removed:
            removeChannelFromTable(channel)
        }
    }
    
    func addChannelToTable(_ channel: Channel) {
        guard !items.contains(channel) else { return }
        items.append(channel)
        items.sort()
        guard let index = items.index(of: channel) else { return }
        tableView.insertRows(at: [IndexPath.init(row: index, section: 0)], with: .automatic)
    }
    
    func updateChannelInTable(_ channel: Channel) {
        guard let index = items.index(of: channel) else { return }
        items[index] = channel
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    func removeChannelFromTable(_ channel: Channel) {
        guard let index = items.index(of: channel) else { return }
        items.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
}

// MARK: - UITableViewDelegate
extension AdminViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = DataChat(menuType: MenuType.cell, row: indexPath.row)
        subject.onNext(data)
    }
}

//MARK: - UITableViewDataSource
extension AdminViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.chatAdminTableViewCell, for: indexPath)!
        let model = items[indexPath.row]
        cell.setup(withChat: model)
        return cell
    }
    
}
