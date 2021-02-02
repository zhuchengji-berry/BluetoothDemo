//
//  DataParser.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import Foundation
import CoreBluetooth
import Combine
import AVFoundation

class DataParser {
    
    static let shared = DataParser()
    private init(){}
    
    private let FLAG: Int = 0b10000000
    
    private var bufferArray = [Int]()
    
    private var pr: Int = 0
    private var spo2: Int = 0
    private var pi: Float = 0
    
    var protocolSelectIndex = 0
    var isSoundEnable = true
    private var audioPlayer: AVAudioPlayer?
    private let soundURL = Bundle.main.url(forResource: "heartBeat", withExtension: "wav")
    
    var maxIndex: Int = 499
    var waveIndex = 0
    
    var waveSize = CGSize(width: 0, height: 0)
    var spacerPosition = CGPoint.zero
    
    var waveArray: [CGPoint] = []
    
    private var waveTimer: AnyCancellable?
    private var recordTimer: AnyCancellable?
    
    private let queue = DispatchQueue(label: "DataParserQueue")
    private let audioQueue = DispatchQueue(label: "AudioQueue")
    
    var ifYouNeedVersionInfo = true
    
    var isSoftwareVersionReceiving = false
    var isHardwareVersionReceiving = false
    var isBluetoothVersionReceiving = false
    
    var softwareVersion = ""
    var hardwareVersion = ""
    var bluetoothVersion = ""
    
}

extension DataParser{
    
    func startTimer(){
        recordTimer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
            .sink{ _ in
                self.queue.async {
                    let spo2Txt = self.spo2 == 0 ? "--" : "\(self.spo2)"
                    let prTxt = self.pr == 0 ? "--" : "\(self.pr)"
                    let piTxt = self.pi == 0 ? "--" : String(format: "%.1f", self.pi)
                    
                    Store.shared.updateHomeParams(spo2Txt, prTxt, piTxt)
                }
            }
        
        waveTimer = Timer.publish(every: 0.033, on: .main, in: .default).autoconnect()
            .sink{ _ in
                self.queue.async {
                    if Store.shared.home.isRefreshWave{
                        Store.shared.updateHomeWave(self.waveArray, self.spacerPosition)
                    }
                }
            }
    }
    
    func stopTimer(){
        queue.async {
            self.recordTimer?.cancel()
            self.waveTimer?.cancel()
            
            self.recordTimer = nil
            self.waveTimer = nil
        }
    }
    
    func reset(protocolSelectIndex: Int){
        queue.async {
            var pointArray: [CGPoint] = []
            for i in 0...self.maxIndex{
                pointArray.append(CGPoint(x: (CGFloat(i) / CGFloat(self.maxIndex)) * self.waveSize.width,
                                          y: self.waveSize.height))
            }
            self.waveArray = pointArray
            
            self.pr = 0
            self.spo2 = 0
            self.pi = 0
            
            self.waveIndex = 0
            
            self.spacerPosition = .zero
            
            self.protocolSelectIndex = protocolSelectIndex
        }
    }
    
    func updateSize(size: CGSize){
        queue.async {
            self.waveSize = size
            self.maxIndex = Int(size.width)
            //if waveSize changed, reset waveArray to adapt waveChartView dynamic
            if self.waveArray.count != self.maxIndex + 1{
                var pointArray: [CGPoint] = []
                for i in 0...self.maxIndex{
                    pointArray.append(CGPoint(x: (CGFloat(i) / CGFloat(self.maxIndex)) * self.waveSize.width,
                                              y: self.waveSize.height))
                }
                self.spacerPosition = CGPoint(x: 0, y: self.waveSize.height / 2)
                self.waveArray = pointArray
                self.waveIndex = 0
                
                Store.shared.updateHomeWave(self.waveArray, self.spacerPosition)//刷新图表
            }
        }
    }
    
    func readData(_ data:Data){
        //notice the current thread
        queue.async {
            //print("thread = \(Thread.current)")
            if self.protocolSelectIndex == 0{
                self.parseWithBCIProtocol(data)
            }else{
                self.parseWithBerryProtocol(data)
            }
        }
    }
    
    func parseWithBerryProtocol(_ data:Data){
        bufferArray += data.toIntArray()
        
        var i = 0
        var validIndex = 0
        let maxCount = bufferArray.count - 20
        
        while i <= maxCount{
            
            if bufferArray[i] == 0xFF && bufferArray[i + 1] == 0xAA{
                
                let checkSum = bufferArray[i + 19]
                
                var sum = 0
                for j in 0...18{
                    sum += bufferArray[i + j]
                }
                
                //check fail
                if sum % 256 != checkSum{
                    i += 2
                    validIndex = i
                    continue
                }
                
                //check success
                let type = bufferArray[i + 2]
                let versionFlag = bufferArray[i + 3]
                
                if versionFlag == 0x56 && (type == 0x53 || type == 0x48 || type == 0x42){
                    switch type {
                    case 0x53:
                        let array = Array(bufferArray.suffix(bufferArray.count - (i + 4)).prefix(15))
                        saveSoftwareVersion(array)
                    case 0x48:
                        let array = Array(bufferArray.suffix(bufferArray.count - (i + 4)).prefix(15))
                        saveHardwareVersion(array)
                    case 0x42:
                        let array = Array(bufferArray.suffix(bufferArray.count - (i + 4)).prefix(15))
                        saveBluetoothVersion(array)
                    default:
                        break
                    }
                }else{
                    let isWavePeak = bufferArray[i + 3] == 0x08
                    let spo2 = bufferArray[i + 4]
                    let pr = bufferArray[i + 6]
                    let pi = Float(bufferArray[i + 10]) / 10//this is different with the BCI Protocol
                    let wave = bufferArray[i + 12]
                    
                    saveData(spo2, pr, pi, wave, isWavePeak)
                }
                i += 19
            }else{
                i += 1
            }
            validIndex = i
            continue
        }
        
        bufferArray = Array(bufferArray.suffix(bufferArray.count - validIndex))
    }
    
    func saveSoftwareVersion(_ array: [Int]){
        let version = array
            .map({String(UnicodeScalar($0)!)})
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Store.shared.updateSoftwareVersion("V" + version)
    }
    
    func saveHardwareVersion(_ array: [Int]){
        let version = array
            .map({String(UnicodeScalar($0)!)})
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Store.shared.updateHardwareVersion("V" + version)
    }
    
    func saveBluetoothVersion(_ array: [Int]){
        let version = array
            .map({String(UnicodeScalar($0)!)})
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Store.shared.updateBluetoothVersion("V" + version)
    }
    
    func parseWithBCIProtocol(_ data:Data){
        bufferArray += data.toIntArray()
        
        var i = 0
        var validIndex = 0
        let maxCount = bufferArray.count - 5
        
        while i <= maxCount{
            if bufferArray[i] >= FLAG &&
                bufferArray[i + 1] < FLAG &&
                bufferArray[i + 2] < FLAG &&
                bufferArray[i + 3] < FLAG &&
                bufferArray[i + 4] < FLAG {
                
                if ifYouNeedVersionInfo{
                    parseDataWithVersion(i)
                }else{
                    parseDataWithoutVersion(i)
                }
                
                i += 5
            }else{
                i += 1
            }
            validIndex = i
            continue
        }
        bufferArray = Array(bufferArray.suffix(bufferArray.count - validIndex))
    }
    
    func parseDataWithVersion(_ i: Int){
        
        switch (bufferArray[i], bufferArray[i + 1]) {
        case (0xFF, 0x56):
            isSoftwareVersionReceiving = true
        case (0xFE, 0x56):
            isHardwareVersionReceiving = true
        case (0xFD, 0x56):
            isBluetoothVersionReceiving = true
        default:
            break
        }
        
        if isSoftwareVersionReceiving || isHardwareVersionReceiving || isBluetoothVersionReceiving{
            if isSoftwareVersionReceiving{
                if softwareVersion.count < 11{
                    for index in 1...4{
                        softwareVersion.append(String(UnicodeScalar(bufferArray[i + index])!))
                    }
                }else{
                    isSoftwareVersionReceiving = false
                    softwareVersion.removeLast()//delete the last byte 0x00
                    Store.shared.updateSoftwareVersion(softwareVersion)
                    softwareVersion = ""
                }
            }
            
            if isHardwareVersionReceiving{
                if hardwareVersion.count < 4{
                    for index in 1...4{
                        hardwareVersion.append(String(UnicodeScalar(bufferArray[i + index])!))
                    }
                }else{
                    isHardwareVersionReceiving = false
                    Store.shared.updateHardwareVersion(hardwareVersion)
                    hardwareVersion = ""
                }
            }
            
            if isBluetoothVersionReceiving{
                if bluetoothVersion.count < 11{
                    for index in 1...4{
                        bluetoothVersion.append(String(UnicodeScalar(bufferArray[i + index])!))
                    }
                }else{
                    isBluetoothVersionReceiving = false
                    bluetoothVersion.removeLast()//delete the last byte 0x00
                    Store.shared.updateBluetoothVersion(bluetoothVersion)
                    bluetoothVersion = ""
                }
            }
            
        }else{
            parseDataWithoutVersion(i)
        }
    }
    
    
    func parseDataWithoutVersion(_ i: Int){
        let spo2 = bufferArray[i + 4]
        let pr = bufferArray[i + 2] >= 0b01000000 ? bufferArray[i + 3] + FLAG : bufferArray[i + 3]
        let pi = getPI(bufferArray[i])
        let wave = bufferArray[i + 1]
        let isWavePeak = bufferArray[i] >= 0b11000000
        
        saveData(spo2, pr, pi, wave, isWavePeak)
    }
    
    
    func saveData(_ spo2: Int, _ pr: Int, _ pi: Float, _ wave: Int, _ isWavePeak: Bool){
        if spo2 >= 35 && spo2 < 100{
            self.spo2 = spo2
        }else if spo2 == 100{
            self.spo2 = 99
        }else{
            self.spo2 = 0
        }
        
        if pr >= 25 && pr <= 250{
            self.pr = pr
        }else{
            self.pr = 0
        }
        
        self.pi = pi
        
        self.updateWave(wave)
        
        if isWavePeak{
            self.playSound()
        }
    }
    
    func updateWave(_ value: Int){
        let point = CGPoint(x: (CGFloat(self.waveIndex) / CGFloat(self.maxIndex)) * self.waveSize.width,
                            y: (CGFloat(128 - value) / 128) * self.waveSize.height)
        
        if self.waveIndex < self.maxIndex{
            self.waveArray[self.waveIndex] = point
            self.waveIndex += 1
        }else if self.waveIndex == self.maxIndex{
            self.waveArray[self.waveIndex] = point
            self.waveIndex = 0
        }else{
            self.waveIndex = 0
            self.waveArray[self.waveIndex] = point
        }
        self.spacerPosition = CGPoint(x: point.x, y: self.waveSize.height / 2)
    }
    
    func getPI(_ value: Int) -> Float{
        switch (value & 0b00001111) {
        case 0: return 0.1
        case 1: return 0.2
        case 2: return 0.4
        case 3: return 0.7
        case 4: return 1.4
        case 5: return 2.7
        case 6: return 5.3
        case 7: return 10.3
        case 8: return 20.0
        default: return 0
        }
    }
    
    func playSound(){
        guard isSoundEnable, let url = soundURL else{
            return
        }
        
        audioQueue.async {
            do{
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.play()
            }catch{
                print(error)
            }
        }
    }
    
}

