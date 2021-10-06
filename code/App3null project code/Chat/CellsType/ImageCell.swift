//
//  ImageCell.swift
//  Linduu
//
//  Created by Oksana Bolibok on 19.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import UIKit

class ImageCell: UITableViewCell {
    
    
    @IBOutlet weak var bubbleImageView: UIImageView!
    
    
    var chatMessage: ImageCellVM? {
        didSet {
            guard let chatMessage = chatMessage else { return }
            UIView.performWithoutAnimation {
                contentView.transform = chatMessage.own ? CGAffineTransform(scaleX: -1, y: 1) : .identity
                bubbleImageView.transform = chatMessage.own ? CGAffineTransform(scaleX: -1, y: 1) : .identity
            }
        }
    }
    
    var imageURL: URL? {
        didSet {
            if let image = bubbleImageView.image  {
                bubbleImageView.sd_setImage(with: imageURL, placeholderImage: image, options: .retryFailed, completed: nil)
                bubbleImageView.image = image
            } else {
                bubbleImageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "noImagePlaceholder"), options: .retryFailed, completed: nil)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
