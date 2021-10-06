//
//  GeneralCellsType.swift
//  Linduu
//
//  Created by Oksana Bolibok on 19.12.2019.
//  Copyright © 2019 app3null. All rights reserved.
//

import Foundation

protocol GeneralCellsType {
    var cellType: CellType { get set }
    var own: Bool { get set }
}

enum CellType {
    case message(_ text: String)
    case image(_ thumbImageURL: URL?)
}

struct MessageCellVM: GeneralCellsType {
    var own: Bool
    let date: String
    var cellType: CellType
    let lastMessageCursor: Bool
}

struct ImageCellVM: GeneralCellsType {
    var own: Bool
    let date: String
    var cellType: CellType
    let lastMessageCursor: Bool
}
