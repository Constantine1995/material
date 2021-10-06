//
//  StatusMessage.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import Foundation

enum StatusMessage: Error {
    case error(message: String)
    case networkError(message: String)
    case parsError
    case unknown(message: String)
    case serverError(message: String)
    case serverSuccess(message: String)
    case warning(message: String)
    
    var title: String {
        switch self {
        case .networkError:
            return "networkError"
        case .parsError:
            return "parsError"
        case .unknown:
            return "unknownError"
        case .serverError, .serverSuccess, .warning, .error:
            return ""
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .error(let message):
            return message
        case .networkError(let message):
            return message
        case .parsError:
            return "incorrectServerResponse"
        case .unknown(let message):
            return message
        case .serverError(let message):
            return message
        case .serverSuccess(let message):
            return message
        case .warning(let message):
            return message
        }
    }
}
