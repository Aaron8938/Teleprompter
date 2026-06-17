//
//  Item.swift
//  Teleprompter
//
//  Created by Aaron Deng on 2026/6/17.
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
