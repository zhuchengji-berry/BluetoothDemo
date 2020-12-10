//
//  Store.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import Foundation
import Combine
import SwiftUI
import CoreBluetooth

class Store: ObservableObject{
    
    static let shared = Store()
    private init(){}
    
    private let queue = DispatchQueue(label: "StoreQueue", attributes: .concurrent)
    
    @Published var home = AppState.Home()
    @Published var device = AppState.Device()
    
}


extension Store{
    
    func run(){
        Bluetooth.shared.run()
    }
    
    func reset(){
        DispatchQueue.main.async {
            let protocolSelectIndex = self.home.protocolSelectIndex
            var tempHome = AppState.Home()
            tempHome.protocolSelectIndex = protocolSelectIndex
            
            self.home = tempHome
            self.device = AppState.Device()
            DataParser.shared.reset(protocolSelectIndex: protocolSelectIndex)
        }
    }
    
    func soundSwitch(){
        DispatchQueue.main.async {
            let isEnable = !self.home.isSoundEnable
            
            self.home.isSoundEnable = isEnable
            DataParser.shared.isSoundEnable = isEnable
        }
    }
    
    func updateHomeParams(_ spo2Txt: String, _ prTxt: String, _ piTxt: String){
        queue.async {
            var obj = self.home
            obj.spo2Txt = spo2Txt
            obj.prTxt = prTxt
            obj.piTxt = piTxt
            
            DispatchQueue.main.async {
                self.home = obj
            }
        }
    }
    
    func updateHomeWave(_ pointArray: [CGPoint], _ position: CGPoint){
        queue.async {
            var obj = self.home
            obj.pointArray = pointArray
            obj.spacerPosition = position
            
            DispatchQueue.main.async {
                self.home = obj
            }
        }
    }
    
    func updateSoftwareVersion(_ version: String){
        DispatchQueue.main.async {
            self.home.softwareVersion = "V" + version
        }
    }
    
    func updateHardwareVersion(_ version: String){
        DispatchQueue.main.async {
            self.home.hardwareVersion = "V" + version
        }
    }
    
    func updateBluetoothVersion(_ version: String){
        DispatchQueue.main.async {
            self.home.bluetoothVersion = "V" + version
        }
    }
    
}
