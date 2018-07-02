//
//  SharedPinInformation.swift
//  Virtual Tourist
//
//  Created by Tony Buckner on 5/21/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

//pin information singleton
class SharedPinInformation {
    static let sharedInstance = SharedPinInformation()
    var info = pinInfo()
}

//picture array singleton
class FlickrArray {
    static let sharedInstance = FlickrArray()
    var array = [UIImage]()
}

struct pinInfo {
    var locationName = String()
    var latitude = Double()
    var longitude = Double()
    
    init() {
        locationName = ""
        latitude = 0.0
        longitude = 0.0
    }
}



