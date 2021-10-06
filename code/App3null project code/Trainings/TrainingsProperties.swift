//
//  TrainingProperties.swift
//  c4institut
//
//  Created by Constantine Likhachov on 25.06.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import Foundation

struct TrainingsProperties: Decodable {
    
    let usersTrainings: [TrainingProperties]
    let allTrainings: [TrainingProperties]
    
    private enum CodingKeys: String, CodingKey {
        case usersTrainings = "users_trainings"
        case allTrainings = "all_trainings"
    }
}

struct TrainingProperties: Decodable {
    let id: Int
    let title: String
    let description: String
    let previewFileURL: String?
    let fileURL: String?
    let startDate: Double
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description
        case startDate = "start_date"
        case previewFileURL = "preview_file_url"
        case fileURL = "file_url"
    }
    
    func dictionary(trainingType: TrainingType) -> [String: Any] {
        var dict: [String: Any] = ["id": id,
                                   "title": title ,
                                   "startDate": Date(timeIntervalSince1970: startDate),
                                   "descriptionText": description,
                                   "type": trainingType.rawValue]
        
        if let previewFileURL = previewFileURL?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            dict["previewFileURL"] = previewFileURL
        }
        
        if let fileURL = fileURL?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            dict["fileURL"] = fileURL
        }
        
        return dict
        
    }
}

enum TrainingType: Int {
    case all
    case my
}
