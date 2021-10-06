//
//  ConversationVC.swift
//  Linduu
//
//  Created by Constantine Likhachov on 17.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import UIKit
import GrowingTextView
import KRPullLoader
import RxSwift

class ChatVC: UIViewController, MVVMViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var giftButton: UIButton!
    @IBOutlet weak var messageCostLabel: UILabel!
    
    @IBAction func didTapSendButton(_ sender: Any) {
        viewModel.sendMessage(text: growingTextField.text)
        growingTextField.text = ""
    }
    
    @IBOutlet weak var growingTextField: GrowingTextView!
    private var noContentPlaceholderView: NoContentPlaceholderView?
    var loadMoreView = KRPullLoadView()
    let disposeBag = DisposeBag()
    var viewModel: ChatVMProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableNoInternetPlaceholder()
        setupPlaceholder()
        setupLayout()
        initObservables()
        setupNavigationBar(with: .title, viewModel.opponentName)
        viewModel.tableView = tableView
        viewModel.startConversationMonitoring()
        addObserderKeyboard(selectorWillShow: #selector(keyboardWillShow), selectorWillHide: #selector(keyboardWillHide))
    }
    
    deinit {
        removeNetworkObservers()
        removeObserderKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(Notification(name: NSNotification.Name(rawValue: Constants.NotificationCenterKey.didOpenConversation), object: nil, userInfo: ["conversationId": viewModel.getOpponentId()]))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.markConversationAsRead()
        
        NotificationCenter.default.post(Notification(name: NSNotification.Name(rawValue: Constants.NotificationCenterKey.didCloseConversation), object: nil, userInfo: nil))
    }
    
    func initObservables() {
        viewModel.statusMessageHandler.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] (statusMessage) in
            guard let strongSelf = self else {return}
            if statusMessage.code == -2 {
                strongSelf.viewModel.showChatPopup(type: .notEnaughtCoins)
            } else {
                strongSelf.viewModel.showChatPopup(type: .noNetworkConnection)
            }
        }).disposed(by: disposeBag)
    }
    
    private func setupLayout() {
        tableView.transform = CGAffineTransform(rotationAngle: (-.pi))
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: tableView.bounds.size.width + 10)
        growingTextField.layer.cornerRadius = 7.0
        growingTextField.layer.borderWidth = 1.0
        growingTextField.layer.borderColor = UIColor.AppColor.veryLightPinkTwo.cgColor
        growingTextField.tintColor = UIColor.AppColor.brightTeal
        growingTextField.maxLength = viewModel.getMessageLength()
        loadMoreView.delegate = self
        tableView.addPullLoadableView(loadMoreView, type: .loadMore)
        
        messageCostLabel.text = String(viewModel.getMessageCost())
        
        giftButton.rx.tap.bind { () in
            self.viewModel.showGiftScene()
        }.disposed(by: self.disposeBag)
        
    }
    
    private func setupPlaceholder() {
        
//        if viewModel.numberOfSections() == 0 {
//            if noContentPlaceholderView == nil  {
//                noContentPlaceholderView = NoContentPlaceholderView(frame: view.frame, contentType: .noMessage)
//                view.insertSubview(noContentPlaceholderView!, aboveSubview: tableView)
//                view.layoutIfNeeded()
//            }
//        } else {
//           noContentPlaceholderView?.removeFromSuperview()
//           noContentPlaceholderView = nil
//        }
        
    }
}

extension ChatVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = viewModel.getMessage(at: indexPath)
        switch cellVM.cellType {
        case .message(let message):
            let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageCell
            cell.message = message
            cell.chatMessage = cellVM as? MessageCellVM
            cell.transform = CGAffineTransform(rotationAngle: (-.pi))
            return cell
        case .image(let thumbImageURL):
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageCell
            cell.chatMessage = cellVM as? ImageCellVM
            cell.imageURL = thumbImageURL

            cell.transform = CGAffineTransform(rotationAngle: (-.pi))
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.AppColor.silver
        label.text = viewModel.title(for: section)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.AppFonts.sfuitTextRegular(with: 12)
        
        let containerView = UIView()
        containerView.addSubview(label)
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        label.transform = CGAffineTransform(rotationAngle: (-.pi))
        return containerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.inputViewBottomConstraint.constant = -keyboardRect.height + self.view.safeAreaInsets.bottom
        }
        view.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.inputViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
}

extension ChatVC: KRPullLoadViewDelegate {
    func pullLoadView(_ pullLoadView: KRPullLoadView, didChangeState state: KRPullLoaderState, viewType type: KRPullLoaderType) {
        switch state {
        case .loading(let completionHandler):
            viewModel.loadMoreMessages {
                completionHandler()
            }
        default:
            break
        }
    }
}
