//
//  Item.swift
//  Tonnage
//
//  Created by Matt Bolaños on 7/25/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
