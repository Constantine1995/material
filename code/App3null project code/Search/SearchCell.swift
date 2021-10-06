//
//  SearchCell.swift
//  Linduu
//
//  Created by Constantine Likhachov on 04.02.2020.
//  Copyright © 2020 app3null. All rights reserved.
//

import SDWebImage
import SDWebImageWebPCoder

class SearchCell: UICollectionViewCell {
    
    static let cellIdentifire = "SearchCell"
    
    private let imageView = UIImageView(image: UIImage())
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: UIFont.AppFonts.HelveticaNeue, size: 16)
        label.textColor = .white
        label.shadowLabel()
        return label
    }()
    
    private var ageLabel: UILabel =  {
        let label = UILabel()
        label.font = UIFont(name: UIFont.AppFonts.SFUITextRegular, size: 12)
        label.textColor = .white
        label.shadowLabel()
        return label
    }()
    
    var image: UIImage? {
        return imageView.image
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    func config(with user: SearchFilterResult) {
        let strUrlImage = "\(Constants.baseURL)\(user.imageURL?.absoluteString ?? "")"
        let placeholderImage = UIImage(named: "avatar-placeholder")
        loadImage(imageView: imageView, placeholderImage: placeholderImage!, strUrlImage: strUrlImage)
        nameLabel.text = user.username
        ageLabel.text = String(user.age)
    }
    
    private func setupLayout() {
        
        self.setCornerRadius = 5
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let labelsStackView = UIStackView.init(arrangedSubviews: [nameLabel, ageLabel])
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        contentView.addSubview(labelsStackView)
        
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        imageView.contentMode = .scaleAspectFill
        
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 3.0
        labelsStackView.isLayoutMarginsRelativeArrangement = true
        labelsStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        labelsStackView.distribution = .fillProportionally
        
        labelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        labelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        labelsStackView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8).isActive = true
        
    }
    
}
