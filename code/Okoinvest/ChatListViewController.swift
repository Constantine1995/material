//
//  ChatListViewController.swift
//  Okoinvest
//
//  Created by constantine on 20.03.2021.
//

import UIKit
import FirebaseFirestore

class ChatListViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var items: [Channel] = []
    private var messages: [Message] = []
    private var channelListener: ListenerRegistration?
    private let dataBaseManager = DatabaseManager.shared()
    private var isEnableChats = false
    
    var isSearchBarActive: Bool {
        return messages.count > 0
    }
    
    var openChannelID: String?
    let user = UserData.shared()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
    }

    deinit {
        channelListener?.remove()
        unsubscribeFromNotifications()
    }
}

// MARK: - Private Methods
private extension ChatListViewController {
    
    func setupUI() {
        isEnableChats = true
        subscribeToNotifications()
        subscribeToChats()
        getUserName()
        searchBar.placeholder = R.string.localizable.search()
        tableView.reloadData()
    }
    
    func subscribeToChats() {
        title = R.string.localizable.chats()
        view.makeToastActivity()
        channelListener = dataBaseManager.getChannelsList { (querySnapshot, error) in
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
    
    func searchMessages(withText text: String, animated: Bool) {
        if text.count > 2 {
            let query = Lingvo.getWords(fromText: text)
            if animated { view.makeToastActivity() }
            dataBaseManager.getMessages(withQuery: query, channels: items) { (messages) in
                self.view.hideLoading()
                self.messages = messages
                self.tableView.reloadData()
            }
        } else {
            messages.removeAll()
            tableView.reloadData()
        }
    }
    
    func getUserName() {
        let userID = user.userID
        guard user.username == nil else { return }
        dataBaseManager.getUserName(userID) { [weak self] (userName) in
            if let userName = userName {
                self?.user.username = userName
                self?.user.save()
            } else {
                self?.showSetUserNameAlert()
            }
        }
    }
    
    func showSetUserNameAlert() {
        let alertController = UIAlertController.init(title: R.string.localizable.enterNameForChats(), message: nil, preferredStyle: .alert)
        alertController.addTextField { (textfield) in
            textfield.placeholder = R.string.localizable.username()
            textfield.autocapitalizationType = .words
        }
        let save = UIAlertAction.init(title: R.string.localizable.save(), style: .default) { (_) in
            let textField = (alertController.textFields?.first)!
            if let text = textField.text {
                self.saveUserName(text)
            } else {
                self.showSetUserNameAlert()
            }
        }
        alertController.addAction(save)
        let cancel = UIAlertAction.init(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func saveUserName(_ username: String) {
        user.username = username
        user.save()
        dataBaseManager.saveUserName(username, userID: user.userID)
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
        
        if let openChannelID = openChannelID, channel.id == openChannelID, let username = user.username {
            openChannel(channel, userID: user.userID, username: username)
            self.openChannelID = nil
        }
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
    
    func openChannel(_ channel: Channel, userID: String, username: String, message: Message? = nil) {
        updateSeenChannels(channel)
        
        let newViewController = ChatViewController.init(channel: channel, userID: userID, username: username)
        newViewController.searchMessage = message
        newViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(newViewController, completion: {
            self.tableView.reloadData()
        })
    }
    
    func updateSeenChannels(_ channel: Channel) {
        let seenChannels = user.seenChannels
        let index = seenChannels.firstIndex(where: { (obj) -> Bool in
            if let id = obj["id"] as? String, id == channel.id {
                return true
            }
            return false
        })
        if let index = index {
            user.seenChannels.remove(at: index)
        }
        user.seenChannels.append(["id" : channel.id, "timestamp" : Date().timeIntervalSince1970.int + 5])
        user.save()
    }
}

// MARK: - Notifications
private extension ChatListViewController {
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(openChat), name: kNotificationOpenChat, object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: kNotificationOpenChat, object: nil)
    }
    
    @objc func openChat() {
        guard let chatID = openChannelID else { return }
        guard let channel = items.first(where: { (obj) -> Bool in
            return obj.id == chatID
        }) else { return }
        guard let username = user.username else { return }
        self.openChannelID = nil
        openChannel(channel, userID: user.userID, username: username)
    }
}

// MARK: - UITableViewDataSource
extension ChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchBarActive {
            return messages.count
        }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.chatTableViewCell, for: indexPath)!
        if isSearchBarActive {
            let model = messages[row]
            let channel = items.first { (obj) -> Bool in
                return obj.id == model.chatID
            }
            cell.setup(withMessage: model, channel: channel)
        } else {
            let model = items[row]
            cell.setup(withChat: model)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isEnableChats {
            if isSearchBarActive {
                let message = messages[indexPath.row]
                if let channel = items.first(where: { (obj) -> Bool in
                    return obj.id == message.chatID
                }) {
                    if let username = user.username {
                        openChannel(channel, userID: user.userID, username: username, message: message)
                    } else {
                        showSetUserNameAlert()
                    }
                }
            } else {
                if let username = user.username {
                    let row = indexPath.row
                    let channel = items[row]
                    openChannel(channel, userID: user.userID, username: username)
                } else {
                    showSetUserNameAlert()
                }
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension ChatListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchMessages(withText: searchBar.text ?? "", animated: false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchMessages(withText: searchBar.text ?? "", animated: true)
    }
}
