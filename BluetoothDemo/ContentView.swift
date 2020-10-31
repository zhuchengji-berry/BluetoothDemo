//
//  ContentView.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView().environmentObject(Store.shared)
            .onAppear {
                Store.shared.run()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
