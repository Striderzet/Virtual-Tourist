//
//  MemeCollectionViewCell.swift
//  Meme Me
//
//  Created by Tony Buckner on 10/26/17.
//  Copyright © 2017 Tony Buckner. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellImage: UIImageView!
    
    //code for activity indicator
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = contentView.center
        contentView.addSubview(activityIndicator)
        return activityIndicator
    }()
}


