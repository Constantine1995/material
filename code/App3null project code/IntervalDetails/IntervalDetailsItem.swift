//
//  IntervalDetailsItem.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

enum IntervalDetailsItem: String, CaseIterable {
    case time
    case left
    case right

    var title: String {
        switch self {
        case .time:
            return Localizations.IntervalDetailsItem.intervalDetailsItem_time
        case .left:
            return Localizations.IntervalDetailsItem.intervalDetailsItem_left
        case .right:
            return Localizations.IntervalDetailsItem.intervalDetailsItem_right
        }
    }

    var color: UIColor {
        switch self {
        case .time:
            return .systemWhite
        case .left:
            return .deepSkyBlue
        case .right:
            return .systemMagenta
        }
    }
}
