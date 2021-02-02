//
//  AppError.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//


import Foundation
import SwiftUI

enum AppError: Error, Identifiable{
    var id: String{
        localizedDescription
    }
    
    case deviceConnectFail
    case unknown
}


extension AppError: LocalizedError{
    var localizedDescription: LocalizedStringKey{
        switch self {
        case .deviceConnectFail: return "Device connect fail"
        default:                 return "Unknown error"
        }
    }
}

