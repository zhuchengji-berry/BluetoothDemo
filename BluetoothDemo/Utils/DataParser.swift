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
    
    private var queue = DispatchQueue(label: "DataParserQueue")
    private var audioQueue = DispatchQueue(label: "AudioQueue")
    
}

extension DataParser{
    
    func startTimer(){
        recordTimer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
            .sink(receiveValue: { (_) in
                self.queue.async {
                    let spo2Txt = self.spo2 == 0 ? "--" : "\(self.spo2)"
                    let prTxt = self.pr == 0 ? "--" : "\(self.pr)"
                    let piTxt = self.pi == 0 ? "--" : String(format: "%.1f", self.pi)
                    
                    Store.shared.updateHomeParams(spo2Txt, prTxt, piTxt)
                }
            })
        
        waveTimer = Timer.publish(every: 0.033, on: .main, in: .default).autoconnect()
            .sink(receiveValue: { (_) in
                self.queue.async {
                    if Store.shared.home.isRefreshWave{
                        Store.shared.updateHomeWave(self.waveArray, self.spacerPosition)
                    }
                }
            })
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
            print("thread = \(Thread.current)")
            if self.protocolSelectIndex == 0{
                self.parseWithBCIProtocol(data)
            }else{
                self.parseWithBerryProtocol(data)
            }
        }
    }
    
    func parseWithBerryProtocol(_ data:Data){
        self.bufferArray += data.toIntArray()
        
        var i = 0
        var validIndex = 0
        let maxCount = self.bufferArray.count - 20
        
        while i <= maxCount{
            
            if self.bufferArray[i] == 0xFF && self.bufferArray[i + 1] == 0xAA{
                
                let checkSum = self.bufferArray[i + 19]
                
                var sum = 0
                for j in 0...18{
                    sum += self.bufferArray[i + j]
                }
                
                //check fail
                if sum % 256 != checkSum{
                    i += 2
                    validIndex = i
                    continue
                }
                
                //check success
                let type = self.bufferArray[i + 2]
                let versionFlag = self.bufferArray[i + 3]
                
                if versionFlag == 0x56 && (type == 0x53 || type == 0x48 || type == 0x42){
                    switch type {
                    case 0x53:
                        let array = Array(self.bufferArray.suffix(self.bufferArray.count - (i + 4)).prefix(15))
                        self.saveSoftwareVersion(array)
                    case 0x48:
                        let array = Array(self.bufferArray.suffix(self.bufferArray.count - (i + 4)).prefix(15))
                        self.saveHardwareVersion(array)
                    case 0x42:
                        let array = Array(self.bufferArray.suffix(self.bufferArray.count - (i + 4)).prefix(15))
                        self.saveBluetoothVersion(array)
                    default:
                        break
                    }
                }else{
                    let isWavePeak = self.bufferArray[i + 3] == 0x08
                    let spo2 = self.bufferArray[i + 4]
                    let pr = self.bufferArray[i + 6]
                    let pi = Float(self.bufferArray[i + 10]) / 10//this is different with the BCI Protocol
                    let wave = self.bufferArray[i + 12]
                    
                    self.saveData(spo2, pr, pi, wave, isWavePeak)
                }
                i += 19
            }else{
                i += 1
            }
            validIndex = i
            continue
        }
        
        self.bufferArray = Array(self.bufferArray.suffix(self.bufferArray.count - validIndex))
    }
    
    func saveSoftwareVersion(_ array: [Int]){
        let version = array
            .map({String(UnicodeScalar($0)!)})
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Store.shared.updateSoftwareVersion(version)
    }
    
    func saveHardwareVersion(_ array: [Int]){
        let version = array
            .map({String(UnicodeScalar($0)!)})
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Store.shared.updateHardwareVersion(version)
    }
    
    func saveBluetoothVersion(_ array: [Int]){
        let version = array
            .map({String(UnicodeScalar($0)!)})
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Store.shared.updateBluetoothVersion(version)
    }
    
    func parseWithBCIProtocol(_ data:Data){
        self.bufferArray += data.toIntArray()
        
        var i = 0
        var validIndex = 0
        let maxCount = self.bufferArray.count - 5
        
        while i <= maxCount{
            if self.bufferArray[i] >= self.FLAG &&
                self.bufferArray[i + 1] < self.FLAG &&
                self.bufferArray[i + 2] < self.FLAG &&
                self.bufferArray[i + 3] < self.FLAG &&
                self.bufferArray[i + 4] < self.FLAG {
                
                let spo2 = self.bufferArray[i + 4]
                let pr = self.bufferArray[i + 2] >= 0b01000000 ? self.bufferArray[i + 3] + self.FLAG : self.bufferArray[i + 3]
                let pi = self.getPI(self.bufferArray[i])
                let wave = self.bufferArray[i + 1]
                let isWavePeak = self.bufferArray[i] >= 0b11000000
                
                self.saveData(spo2, pr, pi, wave, isWavePeak)
                
                i += 5
            }else{
                i += 1
            }
            validIndex = i
            continue
        }
        self.bufferArray = Array(self.bufferArray.suffix(self.bufferArray.count - validIndex))
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

