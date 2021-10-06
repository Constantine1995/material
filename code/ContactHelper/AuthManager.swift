//
//  AuthManager.swift
//  ContactsHelper
//
//  Created by constantine on 20.02.2021.
//

import UIKit
import FirebaseAuth

class AuthManager: NSObject {

    private let databaseManager = DatabaseManager.shared()

    func createUser(fullName: String, email: String, password: String, completionHandler: @escaping CompletionHandler) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard error == nil else {
                completionHandler(.failure(.unknown(message: error!.localizedDescription))); return
            }
            guard let user = authResult?.user.createProfileChangeRequest else { return }
            user().displayName = fullName
            user().commitChanges { (error) in
                if let error = error {
                    completionHandler(.failure(.unknown(message: error.localizedDescription))); return
                } else {
                    guard let userID = Auth.auth().currentUser?.uid else { return }
                    let user = UserData.shared()
                    user.userID = userID
                    user.fullName = fullName
                    user.email = email
                    user.save()
                    DatabaseManager.shared().updatePushToken()
                    self?.databaseManager.createUser(fullname: fullName, email: email, userID: userID)
                    completionHandler(.success(()))
                }
            }
        }
    }
    
    func login(email: String, password: String, completionHandler: @escaping CompletionHandler) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard error == nil else {
                completionHandler(.failure(.unknown(message: error!.localizedDescription))); return
            }
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let user = UserData.shared()
            user.email = email
            user.userID = userID
            user.save()
            DatabaseManager.shared().updatePushToken()
            completionHandler(.success(()))
        }
    }
    
    func logout(completion: @escaping CompletionHandler) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        }
        catch {
            completion(.failure(StatusMessage.custom(title: R.string.localizable.error(), message: error.localizedDescription)))
        }
    }
    
    func passwordReset(email: String, completionHandler: @escaping CompletionHandler) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            guard error == nil else {
                completionHandler(.failure(.unknown(message: error!.localizedDescription))); return
            }
            completionHandler(.success(()))
        }
    }
    
    func changePassword(newPassword: String, completionHandler: @escaping CompletionHandler) {
        Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
            guard error == nil else {
                completionHandler(.failure(.unknown(message: error!.localizedDescription))); return
            }
            completionHandler(.success(()))
        })
    }
}

// MARK: - Shared
extension AuthManager {
    private static let sharedInstance: AuthManager = {
        let instance = AuthManager()
        return instance
    }()
    
    static func shared() -> AuthManager {
        return sharedInstance
    }
}
