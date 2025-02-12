//
//  WaveChartView.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import SwiftUI

struct WaveChartView: View {
    @EnvironmentObject var store: Store
    var binding:Binding<AppState.Home>{
        $store.home
    }
    
    static let gradientStart = Color("spo2Color")
    static let gradientEnd = Color("prColor")
    
    func getPath(_ geo: GeometryProxy) -> CGMutablePath{
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: geo.size.height))
        path.addLines(between: self.binding.pointArray.wrappedValue)
        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
        path.closeSubpath()
        
        DataParser.shared.updateSize(size: geo.size)
        
        return path
    }
    
    var body: some View {
        GeometryReader{ geo in
            ZStack(alignment: .leading){
                
                Path(getPath(geo)).fill(LinearGradient(
                    gradient: .init(colors: [Self.gradientStart, Self.gradientEnd]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 0, y: 1)
                ))
                
                Spacer()
                    .frame(width: 10, height: geo.size.height)
                    .background(Color(.secondarySystemBackground))
                    .position(self.binding.spacerPosition.wrappedValue)
            }
            .clipped()
        }
    }
}

struct WaveChartView_Previews: PreviewProvider {
    static var previews: some View {
        WaveChartView().environmentObject(Store.shared)
    }
}

