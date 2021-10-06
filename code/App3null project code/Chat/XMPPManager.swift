//
//  XMPPManager.swift
//  Linduu
//
//  Created by Constantine Likhachov on 2/16/20.
//  Copyright © 2020 app3null. All rights reserved.
//

import Foundation
import XMPPFramework
import RxSwift
import KeychainAccess

protocol XMPPManagerProtocol {
    init(dataManager: DataManagerProtocol) 
    func connect(username: String)
    func disconnect()
    func goOnline()
    func goOffline()
    var didRecieveNewMessage: PublishSubject<Message> { get set }
    var didRecieveLocalNotification: PublishSubject<LocalNotification> { get set }
}

class XMPPManager: NSObject, XMPPManagerProtocol {
    var didRecieveLocalNotification: PublishSubject<LocalNotification> = PublishSubject<LocalNotification>()
    
    var xmppStream: XMPPStream
    var xmppReconect: XMPPReconnect
    var dataManager: DataManagerProtocol
    var didRecieveNewMessage: PublishSubject<Message> = PublishSubject<Message>.init()
    
    required init(dataManager: DataManagerProtocol) {
        self.dataManager = dataManager
        xmppStream = XMPPStream()
        xmppStream.hostName = Constants.XMPP.ip
        xmppStream.hostPort = Constants.XMPP.port
        xmppReconect = XMPPReconnect()
        xmppReconect.autoReconnect = true
        xmppReconect.activate(xmppStream)
        super.init()
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func connect(username: String) {
        if !self.xmppStream.isDisconnected {
            return
        }
        
        xmppStream.myJID = XMPPJID(string: "\(username)\(Constants.XMPP.service)")
        
        do {
            try self.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
        } catch {
            
        }
    }
    
    func disconnect() {
        xmppStream.disconnectAfterSending()
    }
    
    func goOnline() {
        let presence = XMPPPresence()
        let element = DDXMLElement(name: "priority", stringValue: "8")
        presence.addChild(element)
        xmppStream.send(presence)
        
    }
    
    func goOffline() {
        
    }
    
    private func parseChatMessage(message: XMPPMessage, contentType: NotificationType) {
        do {
            let messageModel = try Message(model: message, type: .text)
            didRecieveNewMessage.onNext(messageModel)
        } catch {
            return
        }
    }
    
    private func parseGiftMessage(message: XMPPMessage, contentType: NotificationType) {
        do {
            let messageModel = try Message(model: message, type: .gift)
            didRecieveNewMessage.onNext(messageModel)
        } catch {
            return
        }
    }
    
    
    
    private func parseNotification(message: XMPPMessage, contentType: NotificationType) {
        do {
            let notification: LocalNotification = try LocalNotification(message: message, contentType: contentType)
            didRecieveLocalNotification.onNext(notification)
        } catch {
            return
        }
    }
    
}

extension XMPPManager: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ stream: XMPPStream) {
        print("Stream: Connected")
        guard let user = dataManager.getAuthProfile(), let hash = user.passwordHash else {
            return
        }
        try! stream.authenticate(withPassword: hash)
        
    }
    
    func xmppStreamConnectDidTimeout(_ sender: XMPPStream) {
        print(sender)
        
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        print(error)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.xmppStream.send(XMPPPresence())
        print("Stream: Authenticated")
        self.goOnline()
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print(error)
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        if let _ = message.element(forName: "chat") {
            parseChatMessage(message: message, contentType: .message)
            parseNotification(message: message, contentType: .message)
        } else if let _ = message.element(forName: "gift") {
            parseGiftMessage(message: message, contentType: .gift)
            parseNotification(message: message, contentType: .gift)
        } else if let _ = message.element(forName: "visit") {
            parseNotification(message: message, contentType: .visit)
        } else if let _ = message.element(forName: "friendship") {
            parseNotification(message: message, contentType: .friendship)
        }else if let _ = message.element(forName: "poke") {
            parseNotification(message: message, contentType: .poke)
        }
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
    }
    
    func xmppStream(_ sender: XMPPStream, didNotRegister error: DDXMLElement) {
        print(error)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend iq: XMPPIQ) {
        print(iq)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        print(message)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend presence: XMPPPresence) {
        print(presence)
    }
    
}

enum NotificationType {
    case gift
    case visit
    case friendship
    case poke
    case message
}
