//
//  DeviceView.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//

import SwiftUI
import CoreBluetooth

struct DeviceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: Store
    var binding: Binding<AppState.Device>{
        $store.device
    }
    
    var body: some View {
        NavigationView{
            List(self.binding.deviceArray.wrappedValue, id: \.self) { device in
                DeviceCell(peripheral: device)
            }
            .onReceive(self.binding.isConnected.wrappedValue) { _ in
                self.presentationMode.wrappedValue.dismiss()
            }
            .alert(item: self.binding.error) { error in
                Alert(title: Text("Notice"),
                      message: Text(error.localizedDescription))
            }
            .navigationBarTitle("Bluetooth", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(.white))
                        .cornerRadius(12)
                        .padding(10)
                        .colorMultiply(.blue)
                },
                trailing: Button(action: {
                    Bluetooth.shared.refresh()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .imageScale(.large)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(.white))
                        .padding(10)
                        .colorMultiply(.blue)
                })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear{
            print("停止刷新波形")
            Store.shared.home.isRefreshWave = false
            Bluetooth.shared.scan()
        }
        .onDisappear {
            print("刷新波形")
            Store.shared.home.isRefreshWave = true
            Bluetooth.shared.stopScan()
        }
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView().environmentObject(Store.shared)
    }
}


private struct DeviceCell: View {
    var peripheral: CBPeripheral
    var body: some View {
        Button(action: {
            Bluetooth.shared.connect(self.peripheral)
        }) {
            HStack{
                Text(self.peripheral.name ?? "").font(.system(size: 15))
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 8, height: 14)
            }.frame(height: 44)
        }.foregroundColor(Color(.label))
    }
}
