//
//  ConversationVM.swift
//  Linduu
//
//  Created by Constantine Likhachov on 17.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import RxSwift
import RxCocoa

// MARK:- Protocol

protocol ChatVMProtocol {
    func startConversationMonitoring()
    var opponentName: String { get set }
    func getMessage(at index: IndexPath) -> GeneralCellsType
    func getMessageCount() -> Int
    func sendMessage(text: String?)
    func title(for section: Int) -> String
    func numberOfRows(in section: Int) -> Int
    func numberOfSections() -> Int
    func loadMoreMessages(completion: (() -> Void)?)
    func getMessageCost() -> Int
    func getMessageLength() -> Int
    func showGiftScene()
    func showChatPopup(type: ChatPopupType)
    func markConversationAsRead()
    var tableView: UITableView? { get set }
    var didFinishLoad: PublishSubject<Void> { get set }
    var statusMessageHandler: PublishSubject<StatusMessage> { get set }
    func getOpponentId() -> Int
}

class ChatVM: NSObject, MVVMViewModel {
    
    let router: MVVMRouter
    
    var chatModel: Chat
    var conversationManager: ConversationManagerProtocol
    var opponentName: String
    var didFinishLoad: PublishSubject<Void> = PublishSubject<Void>()
    var tableView: UITableView?
    var statusMessageHandler = PublishSubject<StatusMessage>()
    private let chatFetchController: NSFetchedResultsController<NSFetchRequestResult>

    //==============================================================================
    
    init(with router: MVVMRouter, chatModel: Chat, conversationManager: ConversationManagerProtocol) {
        self.router = router
        self.chatModel = chatModel
        self.conversationManager = conversationManager
        opponentName = chatModel.opponentName
        self.chatFetchController = conversationManager.chatFetchController(for: chatModel.opponentID)
        conversationManager.loadMessages(for: chatModel.opponentID, completion: nil)
        conversationManager.markConversationAsRead(for: chatModel.opponentID)
        super.init()
        initObservables()
        
    }
    
    //==============================================================================
    
    func initObservables() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkReconnection), name: NSNotification.Name(rawValue: Constants.NotificationCenterKey.networkReachable), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func handleNetworkReconnection() {
        conversationManager.loadMessages(for: chatModel.opponentID, new: true, completion: nil)
    }
    
    @objc func handleAppTerminate() {
        markConversationAsRead()
    }
    
    //==============================================================================
    
    deinit {
        tableView = nil
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension ChatVM: ChatVMProtocol {
    
    func getOpponentId() -> Int {
        return chatModel.opponentID
    }
    
    func markConversationAsRead() {
        conversationManager.markConversationAsRead(for: chatModel.opponentID)
    }
    
    func showChatPopup(type: ChatPopupType) {
        router.enqueueRoute(with: ChatRouter.RouteType.showChatPopup(type: type), animated: false, completion: nil)
    }
    
    func showGiftScene() {
        let gift = Gift()
        gift.receiveId = chatModel.opponentID
        router.enqueueRoute(with: ChatRouter.RouteType.showGiftCategories(receiverId: chatModel.opponentID), animated: true, completion: nil)
    }
    
    func loadMoreMessages(completion: (() -> Void)?) {
        conversationManager.loadMessages(for: chatModel.opponentID, new: false, completion: completion)
    }
    
    func numberOfSections() -> Int {
        guard let sections = chatFetchController.sections else {
            return 0
        }
        return sections.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        guard let sections = chatFetchController.sections else {
            return 0
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func title(for section: Int) -> String {
        let date = Date()
        if let sectionName = chatFetchController.sections?[section].name, let date = date.groupDateFormater(dateType: .timeZone, dateString: sectionName) {
            return String.groupTimeChat(for: date)
        }
        return ""
    }
    
    
    func sendMessage(text: String?) {
        guard let messageText = text, messageText.count > 0 else {
            return
        }
        conversationManager.sendMessage(userId: chatModel.opponentID, text: messageText) { (error) in
            if let statusMessage = error {
                self.statusMessageHandler.onNext(statusMessage)
            }
        }
    }
    
    func startConversationMonitoring() {
        do{
            try self.chatFetchController.performFetch()
            self.chatFetchController.delegate = self
        } catch { }
    }
    
    func getMessage(at index: IndexPath) -> GeneralCellsType {
        let message = chatFetchController.object(at: index) as! MessageMO
        let dateString = Date().setDateFormatter(dateType: .fullDate, date: message.date ?? Date())
        let defaultMessageCellVM = MessageCellVM(own: false, date: "", cellType: .image(URL.init(string: "")), lastMessageCursor: false)
        guard let type = message.type else { return  defaultMessageCellVM }
        switch MessageType(rawValue: type) {
        case .gift:
            return ImageCellVM(own: message.isMy, date: dateString, cellType: .image(URL(string: Constants.baseURL + (message.imageUrl ?? "")) ), lastMessageCursor: true)
        case .text:
            return MessageCellVM(own: message.isMy, date: dateString, cellType: .message(message.text ?? ""), lastMessageCursor: true)
            
        case .none:
            return MessageCellVM(own: message.isMy, date: dateString, cellType: .message(message.text ?? ""), lastMessageCursor: true)
        }
    }
    
    func getMessageCount() -> Int {
        guard let sections = chatFetchController.sections else {
            return 0
        }
        return sections.first?.numberOfObjects ?? 0
    }
    
    func getMessageCost() -> Int {
        return conversationManager.getMessageCost()
    }
    
    func getMessageLength() -> Int {
        return conversationManager.getMessageLength()
    }
    
}

extension ChatVM: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView?.insertSections(IndexSet(integer: sectionIndex), with: .none)
            break
        case .delete:
            self.tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .none)
            break
        case .move:
            break
        case .update:
            self.tableView?.reloadSections(IndexSet(integer: sectionIndex), with: .none)
            break
        @unknown default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        markConversationAsRead()
        switch (type) {
        case .insert:
            if let newIndexPath = newIndexPath {
                self.tableView?.insertRows(at: [newIndexPath], with: .none)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                self.tableView?.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case .move:
            if let indexPath = indexPath {
                self.tableView?.deleteRows(at: [indexPath], with: .none)
            }
            
            if let newIndexPath = newIndexPath {
                self.tableView?.insertRows(at: [newIndexPath], with: .none)
            }
            break
        case .update:
            break
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.endUpdates()
    }
}
