//
//  ChatViewController.swift
//  Okoinvest
//
//  Created by constantine on 18.03.2021.
//

import UIKit
import Photos
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore
import IQKeyboardManagerSwift
import AssetsPickerViewController
import MWPhotoBrowser

struct ChatUser: SenderType {
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    private let database = DatabaseManager.shared()
    private let storage = StorageManager.shared()
    
    private var messages: [Message] = []
    private var messageListener: ListenerRegistration?
    
    private weak var settingsBarButtonItem: UIBarButtonItem!
    
    private let channel: Channel
    private let userID: String
    private let username: String
    
    private lazy var currentUser: ChatUser = {
        return ChatUser(senderId: userID, displayName: username)
    }()
    
    var searchMessage: Message?
    
    var channelID: String {
        return channel.id
    }
    
    deinit {
        messageListener?.remove()
    }
    
    init(channel: Channel, userID: String, username: String) {
        self.channel = channel
        self.userID = userID
        self.username = username
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setup()
        getFirstMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = true
        if isMovingFromParent {
            messageListener?.remove()
        }
    }
    
    // MARK: - Actions
    @objc private func cameraButtonPressed() {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: isIpad ? .alert : .actionSheet)
        let takePhoto = UIAlertAction.init(title: R.string.localizable.takePhoto(), style: .default) { (_) in
            self.takePhotoAction()
        }
        alertController.addAction(takePhoto)
        let addFromGallery = UIAlertAction.init(title: R.string.localizable.addFromGallery(), style: .default) { (_) in
            self.addFromGalleryAction()
        }
        alertController.addAction(addFromGallery)
        
        let cancel = UIAlertAction.init(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        alertController.addAction(cancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func clickedSettingsBarButton() {
        let user = UserData.shared()
        let masterPassword = user.masterPassword
        
        showDeleteConfirmationAlert(allMessages: true) { (forAll) in
            if forAll {
                self.showEnterMasterPassword(R.string.localizable.delete(), completion: { (password) in
                    if let password = password {
                        if masterPassword == password {
                            self.database.deleteAllMessages(self.channel, forAll: forAll)
                        } else {
                            self.showMasterPasswordNotCorrect()
                        }
                    }
                })
            } else {
                self.view.makeToastActivity()
                self.database.deleteAllMessages(self.channel, forAll: forAll, completion: {
                    self.view.hideLoading()
                    self.reloadCollectionView()
                })
            }
        }
    }
    
    // MARK: Override
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if action == NSSelectorFromString("delete:") {
            let model = messages[indexPath.section]
            return isFromCurrentSender(message: model)
        } else if action == NSSelectorFromString("copy:") {
            let model = messages[indexPath.section]
            if model.image != nil {
                return false
            } else {
                return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
            }
        } else {
            return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let user = UserData.shared()
        let masterPassword = user.masterPassword
        
        if action == NSSelectorFromString("delete:") {
            let model = messages[indexPath.section]
            showDeleteConfirmationAlert(allMessages: false) { (forAll) in
                if forAll {
                    self.showEnterMasterPassword(R.string.localizable.delete(), completion: { (password) in
                        if let password = password {
                            if masterPassword == password {
                                self.deleteMessage(model, forAll: forAll)
                            } else {
                                self.showMasterPasswordNotCorrect()
                            }
                        }
                    })
                } else {
                    self.deleteMessage(model, forAll: forAll)
                    self.reloadCollectionView()
                }
            }
        } else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
}

// MARK: - Private Methods
private extension ChatViewController {
    func setupNavigationBar() {
        let usersCount: Int = channel.userIds.count
        let subtitle = Lingvo.lingvo(withNumber: usersCount, word1: R.string.localizable.chatUsers1(usersCount), word2: R.string.localizable.chatUsers2(usersCount), word3: R.string.localizable.chatUsers3(usersCount))
        navigationItem.setTitle(title: channel.name, subtitle: subtitle)
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(clickedTitleView))
        navigationItem.titleView?.addGestureRecognizer(tapGesture)
        let barButtonItem = UIBarButtonItem.init(image: R.image.dots(), style: .plain, target: self, action: #selector(clickedSettingsBarButton))
        settingsBarButtonItem = barButtonItem
        navigationItem.rightBarButtonItem = settingsBarButtonItem
    }
    
    @objc func clickedTitleView() {
        guard let newViewController = R.storyboard.chatUsers.chatUsersViewController() else { return }
        newViewController.channel = channel
        navigationController?.pushViewController(newViewController)
    }
    
    func setup() {
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .primary
        messageInputBar.inputTextView.placeholder = R.string.localizable.newMessage()
        messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.setMessageIncomingMessageTopLabelAlignment(.init(textAlignment: .center, textInsets: .zero))
            layout.setMessageOutgoingMessageTopLabelAlignment(.init(textAlignment: .center, textInsets: .zero))
            layout.setMessageIncomingMessageBottomLabelAlignment(.init(textAlignment: .left, textInsets: .zero))
            layout.setMessageOutgoingMessageBottomLabelAlignment(.init(textAlignment: .right, textInsets: .zero))
        }
        
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = .primary
        cameraItem.image = R.image.camera()
        cameraItem.addTarget(self, action: #selector(cameraButtonPressed), for: .primaryActionTriggered)
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
        
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
    
    func getFirstMessages() {
        view.makeToastActivity()
        database.getFirstMessagesForChannel(channel) { (items, error) in
            if let error = error {
                self.view.hideLoading()
                print("Error listening for channel updates: \(error.localizedDescription)")
                return
            }
            self.handleFirstMessages(items)
        }
    }
    
    func showDeleteConfirmationAlert(allMessages: Bool, completion: @escaping (Bool) -> Void) {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let alertController = UIAlertController.init(title: allMessages ? R.string.localizable.deleteAllMessages() : R.string.localizable.deleteMessage(), message: nil, preferredStyle: isIpad ? .alert : .actionSheet)
        let forMe = UIAlertAction.init(title: R.string.localizable.deleteForMe(), style: .default) { (_) in
            completion(false)
        }
        alertController.addAction(forMe)
        let forAll = UIAlertAction.init(title: R.string.localizable.deleteForAll(), style: .default) { (_) in
            completion(true)
        }
        alertController.addAction(forAll)
        let cancel = UIAlertAction.init(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func reloadCollectionView() {
        let deletedMessages = UserData.shared().deletedMessages
        if deletedMessages.count > 0 {
            var newMessage: [Message] = []
            for item in messages {
                if let id = item.id {
                    if !deletedMessages.contains(id) {
                        newMessage.append(item)
                    }
                } else {
                    newMessage.append(item)
                }
            }
            messages = newMessage
        }
        messages.sort()
        messagesCollectionView.reloadData()
    }
    
    func updateSeenChannels(_ channel: Channel) {
        let user = UserData.shared()
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

// MARK: - Private Methods Chat
private extension ChatViewController {
    
    func subscribeToMessages() {
        view.makeToastActivity()
        messageListener = database.getMessageForChannel(channel, completion: { (querySnapshot, error) in
            self.view.hideLoading()
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        })
    }
    
    func handleFirstMessages(_ items: [Message]) {
        let group = DispatchGroup()
        for var item in items {
            if let url = item.downloadURL {
                group.enter()
                storage.downloadImage(at: url) { (image) in
                    item.image = image
                    self.messages.append(item)
                    group.leave()
                }
            } else {
                messages.append(item)
            }
        }
        group.notify(queue: .main) {
            self.view.hideLoading()
            self.reloadCollectionView()
            if let searchMessage = self.searchMessage, let index = self.messages.index(of: searchMessage) {
                self.messagesCollectionView.scrollToItem(at: IndexPath.init(row: 0, section: index), at: .top, animated: false)
            } else {
                self.messagesCollectionView.scrollToLastItem(animated: true)
            }
            self.subscribeToMessages()
        }
    }
    
    func handleDocumentChange(_ change: DocumentChange) {
        guard var message = Message(document: change.document) else { return }
        switch change.type {
        case .added:
            if let url = message.downloadURL {
                storage.downloadImage(at: url) { image in
                    guard let image = image else { return }
                    
                    message.image = image
                    self.insertNewMessage(message)
                }
            } else {
                insertNewMessage(message)
            }
        case .modified:
            if let url = message.downloadURL {
                storage.downloadImage(at: url) { (image) in
                    guard let image = image else { return }
                    message.image = image
                    self.updateMessage(message)
                }
            } else {
                updateMessage(message)
            }
        case .removed:
            removeMessage(message)
        }
    }
    
    func insertNewMessage(_ message: Message) {
        guard !messages.contains(message) else { return }
        updateSeenChannels(channel)
        let deletedMessages = UserData.shared().deletedMessages
        if let id = message.id, !deletedMessages.contains(id) {
            messages.append(message)
            messages.sort()
            
            let isLatestMessage = messages.index(of: message) == (messages.count - 1)
            let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
            
            messagesCollectionView.reloadData()
            
            if shouldScrollToBottom {
                DispatchQueue.main.async() {
                    self.messagesCollectionView.scrollToLastItem(animated: true)
                }
            }
        }
    }
    
    func updateMessage(_ message: Message) {
        guard let index = messages.index(of: message) else { return }
        messages[index] = message
        messages.sort()
        
        messagesCollectionView.reloadData()
    }
    
    func removeMessage(_ message: Message) {
        guard let index = messages.index(of: message) else { return }
        messages.remove(at: index)
        messagesCollectionView.reloadData()
    }
    
    func save(_ message: Message) {
        database.saveMessage(message) { (error) in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }
            
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
    func deleteMessage(_ message: Message, forAll: Bool) {
        database.deleteMessage(message, forAll: forAll)
    }
}

// MARK: - Private Methods Images
private extension ChatViewController {
    func sendPhoto(_ image: UIImage) {
        view.makeToastActivity()
        storage.uploadImage(image, channelID: channel.id) { (url) in
            self.view.hideLoading()
            guard let url = url else { return }
            var message = Message.init(userID: self.userID, chatID: self.channel.id, username: self.username, image: image)
            message.downloadURL = url
            
            self.save(message)
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
    func addFromGalleryAction() {
        let picker = AssetsPickerViewController()
        let pickerConfig = AssetsPickerConfig()
        pickerConfig.albumIsShowEmptyAlbum = false
        picker.pickerConfig = pickerConfig
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func takePhotoAction() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    func addImagesToAlbum(_ assets: [PHAsset]) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        for item in assets {
            let size = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(for: item, targetSize: size, contentMode: .aspectFit, options: options) { result, info in
                if let image = result {
                    self.sendPhoto(image)
                }
            }
        }
    }
    
    func openImageViewer(_ message: Message) {
        view.makeToastActivity()
        var images: [MWPhoto] = []
        var index: Int = 0
        var imageIndex: Int = 0
        for item in messages {
            if let image = item.image {
                if let model = MWPhoto.init(image: image) {
                    images.append(model)
                    if message.id == item.id {
                        imageIndex = index
                    }
                    index += 1
                }
            }
        }
        if let browser = MWPhotoBrowser.init(photos: images) {
            print("KK: image index \(imageIndex)")
            browser.setCurrentPhotoIndex(imageIndex.uInt)
            browser.displayActionButton = false
            let navController = BaseNavigationController.init(rootViewController: browser)
            self.present(navController, animated: true) {
                self.view.hideLoading()
            }
        }
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message.init(userID: userID, chatID: channel.id, username: username, content: text)
        save(message)
        inputBar.inputTextView.text = ""
    }
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = getFormattedDateString(message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1), .foregroundColor: UIColor(white: 0.3, alpha: 1)]
        )
    }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        let section = indexPath.section
        let model = messages[section]
        let dateString = getFormattedDateString(model.sentDate)
        if section - 1 >= 0 {
            let prevModel = messages[section - 1]
            let prevDateString = getFormattedDateString(prevModel.sentDate)
            return dateString == prevDateString ? 0 : 20
        }
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        let isMyMessage = isFromCurrentSender(message: message)
        return isMyMessage ? 0 : 20
    }
}

// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primary : .incomingMessage
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
}

// MARK: - MessageCellDelegate
extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let model = messages[indexPath.section]
        if model.image != nil {
            openImageViewer(model)
        }
    }
}

// MARK: - Date
private extension ChatViewController {
    func getFormattedDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        if date.isInToday {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMMM, HH:mm"
        }
        return formatter.string(from: date)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if #available(iOS 11.0, *) {
            if let asset = info[.phAsset] as? PHAsset {
                let size = CGSize(width: 500, height: 500)
                PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil) { result, info in
                    guard let image = result else {
                        return
                    }
                    self.sendPhoto(image)
                }
            } else if let image = info[.originalImage] as? UIImage {
                sendPhoto(image)
            }
        } else if let image = info[.originalImage] as? UIImage {
            sendPhoto(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - AssetsPickerViewControllerDelegate
extension ChatViewController: AssetsPickerViewControllerDelegate {
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        addImagesToAlbum(assets)
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return controller.selectedAssets.count < 10 && asset.mediaType != .video
    }
}

// MARK: - MessageCollectionViewCell
extension MessageCollectionViewCell {
    override open func delete(_ sender: Any?) {
        if let collectionView = self.superview as? UICollectionView {
            if let indexPath = collectionView.indexPath(for: self) {
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("delete:"), forItemAt: indexPath, withSender: sender)
            }
        }
    }
}
