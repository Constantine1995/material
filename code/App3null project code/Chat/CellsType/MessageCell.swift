//
//  MessageCell.swift
//  Linduu
//
//  Created by Oksana Bolibok on 18.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var bubbleBackgroundView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!

    //weak var delegate: ChatCellDelegate?
    
    static let leftBubbleImageCorner = UIImage(named: "left_chat_bubble_corner")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    static let rightBubbleImageCorner = UIImage(named: "right_chat_bubble_corner")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    
    static let leftBubbleImageRounded = UIImage(named: "left_chat_bubble_rounded")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    static let rightBubbleImageRounded = UIImage(named: "right_chat_bubble_rounded")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26))
    
    
    var chatMessage: MessageCellVM? {
        didSet {
            guard let chatMessage = chatMessage else { return }
            
            if chatMessage.lastMessageCursor {
                bubbleBackgroundView.image = chatMessage.own ? MessageCell.rightBubbleImageCorner : MessageCell.leftBubbleImageCorner
            } else {
                bubbleBackgroundView.image = chatMessage.own ? MessageCell.rightBubbleImageRounded : MessageCell.leftBubbleImageRounded
            }
            
            messageLabel.textColor = chatMessage.own ? .white : UIColor.AppColor.greyishBrown
            
            dateLabel.text = chatMessage.date

            
        
            UIView.performWithoutAnimation {
                contentView.transform = chatMessage.own ? CGAffineTransform(scaleX: -1, y: 1) : .identity
                bubbleBackgroundView.transform = chatMessage.own ? CGAffineTransform(scaleX: -1, y: 1) : .identity
            }
        }
    }
    
    var message: String? {
        didSet {
            messageLabel.text = message
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        backgroundColor = .clear
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.AppFonts.sfuitTextRegular(with: 16)
        messageLabel.textAlignment = .left
    
        dateLabel.textAlignment = .right
        dateLabel.textColor = .white
        bubbleBackgroundView.backgroundColor = .clear
    }
    
}

