//
//  AppState.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import Foundation
import SwiftUI
import CoreBluetooth
import Combine

struct AppState {
    
    struct Home {
        
        var spo2Txt = "--"
        var prTxt = "--"
        var piTxt = "--"
        
        var pointArray = [CGPoint]()
        var spacerPosition = CGPoint.zero
        
        var isSoundEnable = true
        var isRefreshWave = true
        
        var mPeripheral: CBPeripheral?
        var mCentralState: Bluetooth.CentralState = .poweredOn
        var mPeripheralState: Bluetooth.PeripheralState = .unconnected
        
        var protocolSelectIndex = 0{
            didSet{
                DataParser.shared.reset(protocolSelectIndex: protocolSelectIndex)
            }
        }
        
        var frequencySelectIndex = 1{
            didSet{
                Bluetooth.shared.setFrequence(frequencySelectIndex)
            }
        }
        
        var filterSelectIndex = 1{
            didSet{
                Bluetooth.shared.setFilter(filterSelectIndex)
            }
        }
        
        var newName = ""
        var softwareVersion = "--"
        var hardwareVersion = "--"
        var bluetoothVersion = "--"
        
        var error: AppError?
    }
    
    struct Device {
        var deviceArray = [CBPeripheral]()
        var isConnected = PassthroughSubject<Bool,Never>()
        var error: AppError?
    }
    
}
