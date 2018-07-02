//
//  GDCBlackBox.swift
//  Virtual Tourist
//
//  Created by Tony Buckner on 5/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
