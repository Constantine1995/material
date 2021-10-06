//
//  DatabaseManager.swift
//  ContactsHelper
//
//  Created by constantine on 23.02.2021.
//

import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging

private let kCollectionUsers: String = "users"
private let kQueryFieldUserID: String = "user_id"
private let kQueryFieldFullName: String = "fullName"
private let kQueryFieldEmail: String = "email"
private let kQueryFieldPayments: String = "payments"
private let kQueryFieldPushTokens: String = "pushTokens"
private let kQueryFieldAmountOfContacts: String = "amountOfContacts"

class DatabaseManager: NSObject {
    
    private static let sharedInstance: DatabaseManager = {
        let instance = DatabaseManager()
        instance.database = Firestore.firestore()
        let settings = instance.database.settings
        instance.database.settings = settings
        return instance
    }()
    
    static func shared() -> DatabaseManager {
        return sharedInstance
    }
    
    private var database: Firestore!
}

// MARK: - User
extension DatabaseManager {
    func createUser(fullname: String, email: String, userID: String) {
        let countOfContacts = RemoteConfigManager.shared().fetchCountFreeContacts()
        var ref: DocumentReference? = nil
        ref = database.collection(kCollectionUsers).addDocument(data: [kQueryFieldFullName: fullname,
                                                                       kQueryFieldEmail: email,
                                                                       kQueryFieldUserID: userID,
                                                                       kQueryFieldAmountOfContacts: countOfContacts]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    func getUser(completion: @escaping (DBUser?) -> Void) {
        let userID = UserData.shared().userID
        let ref = database.collection(kCollectionUsers).whereField(kQueryFieldUserID, isEqualTo: userID)
        ref.getDocuments { (snapshot, error) in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let first = snapshot?.documents.first {
                let model = DBUser.init(dictionary: first.data(), documentID: first.documentID)
                completion(model)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - Push Token
extension DatabaseManager {
    
    func updatePushToken() {
        let user = UserData.shared()
        if user.userID.count > 0 {
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("Error reseive token from firebase: \(error.localizedDescription)")
                }
                if let token = token {
                    self.getUser(completion: { (model) in
                        if let model = model {
                            if model.pushToken.isEmpty {
                                var pushToken = model.pushToken
                                pushToken.append(token)
                                user.pushToken = token
                                user.save()
                                let ref = self.database.collection(kCollectionUsers).document(model.documentID)
                                let pushTokens = [user.deviceID : pushToken]
                                ref.setData([kQueryFieldPushTokens : pushTokens], merge: true)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func removePushToken(forUser userID: String, completion: @escaping ()->Void) {
        if userID.count > 0 {
            let user = UserData.shared()
            self.getUser(completion: { (model) in
                if let model = model {
                    if model.pushToken.isEmpty {
                        var dict = model.pushTokens
                        dict.removeValue(forKey: user.deviceID)
                        self.database.collection(kCollectionUsers).document(model.documentID).updateData([kQueryFieldPushTokens : dict])  { err in
                            completion()
                        }
                    }
                }
            })
        }
    }
}

// MARK: - Payments
extension DatabaseManager {
    
    func setBuyPayments(product: AcquireContacts, amount: Int) {
        getUser { (model) in
            if let model = model {
                let ref = self.database.collection(kCollectionUsers).document(model.documentID)
                let productDict = ["productID": product.productID , "name": product.title, "price": product.description]
                
                ref.setData([kQueryFieldPayments: FieldValue.arrayUnion([productDict])], merge: true) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    }
                }
            } else {
                guard let amountOfContacts = UserData.shared().amountOfContacts else { return }
                UserData.shared().amountOfContacts = amountOfContacts + amount
                UserData.shared().save()
            }
        }
    }
}

// MARK: - Amount
extension DatabaseManager {
    
    func setNewAmount(amountOfContacts: Int) {
        getUser { (model) in
            if let model = model {
                let limit = model.amountOfContacts
                self.updateAmountOfContacts(state: .update, amount: limit - amountOfContacts, completion: nil)
            } else {
                let limit = UserData.shared().amountOfContacts ?? 0
                if limit != 0 {
                    UserData.shared().amountOfContacts = (limit - 1)
                    UserData.shared().save()
                }
                NotificationCenter.default.post(name: NSNotification.Name(kNotificationUpdateAmount.rawValue), object: nil, userInfo: nil)
            }
        }
    }
    
    func updateAmountOfContacts(state: ContactState, amount: Int, completion: (()->Void)?) {
        self.getUser(completion: { (model) in
            if let model = model {
                switch state {
                case .increment:
                    let ref = self.database.collection(kCollectionUsers).document(model.documentID)
                    ref.updateData([kQueryFieldAmountOfContacts : FieldValue.increment(Int64(amount))])
                    NotificationCenter.default.post(name: NSNotification.Name(kNotificationUpdateAmount.rawValue), object: nil, userInfo: nil)
                    completion?()
                case .update:
                    let ref = self.database.collection(kCollectionUsers).document(model.documentID)
                    ref.updateData([kQueryFieldAmountOfContacts : amount])
                    NotificationCenter.default.post(name: NSNotification.Name(kNotificationUpdateAmount.rawValue), object: nil, userInfo: nil)
                    completion?()
                }
            } else {
                completion?()
                NotificationCenter.default.post(name: NSNotification.Name(kNotificationUpdateAmount.rawValue), object: nil, userInfo: nil)
            }
        })
    }
    
    func getAvailableCountOfContacts(completion: @escaping (Int) -> Void) {
        self.getUser(completion: { (model) in
            if let model = model {
                completion(model.amountOfContacts)
            } else {
                if UserData.shared().didSkipLogin {
                    completion(UserData.shared().amountOfContacts ?? 0)
                } else {
                    completion(RemoteConfigManager.shared().fetchCountFreeContacts())
                }
            }
        })
    }
}

