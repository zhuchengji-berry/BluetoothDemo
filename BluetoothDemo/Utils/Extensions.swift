//
//  Extensions.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import Foundation
import SwiftUI

extension Data {
    func toIntArray() -> [Int]{
        self.map{ Int($0) }
    }
}



extension Spacer {
    public func onTapEndEditing() -> some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.000001)
                .onTapGesture(count: 1){
                    UIApplication.shared
                        .sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil)
                }
            self
        }
    }
}

extension View{
    public func onTapEndEditing() -> some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.000001)
                .onTapGesture(count: 1){
                    UIApplication.shared
                        .sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil)
                }
            self
        }
    }
    
    public func endEditing(){
        UIApplication.shared
            .sendAction(#selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil)
    }
}
