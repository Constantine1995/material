//
//  VC+Extension.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import UIKit

extension UIViewController {
    
    class func instantiateFromStoryboard(storyboardName: String, storyboardId: String) -> Self {
        return instantiateFromStoryboardHelper(storyboardName: storyboardName, storyboardId: storyboardId)
    }
    
    private class func instantiateFromStoryboardHelper<T>(storyboardName: String, storyboardId: String) -> T {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: storyboardId) as! T
        return controller
    }
    
    func handleStatusMessage(_ message: StatusMessage, handler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: message.title, message: message.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        switch message {
        default:
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                if let handler = handler {
                    handler()
                }
            }))
            break
        }
        self.present(alert, animated: true, completion: nil)
    }
    
}
