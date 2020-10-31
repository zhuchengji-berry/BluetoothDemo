//
//  Extensions.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import Foundation

extension Data {
    func toIntArray() -> [Int]{
        return self.map{ Int($0) }
    }
}
