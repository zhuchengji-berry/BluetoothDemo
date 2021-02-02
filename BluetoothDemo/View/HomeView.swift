//
//  HomeView.swift
//  BluetoothDemo
//
//  Created by 沉寂 on 2020/10/28.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: Store
    var binding: Binding<AppState.Home>{
        $store.home
    }
    
    var body: some View {
        
        VStack(spacing: 0){
            
            NavView()
            
            Divider()
            
            InfoView()
            
            Divider()
            
            VStack(spacing: 10){
                HStack(spacing: 10){
                    ParamView(index: 0)
                    ParamView(index: 1)
                    ParamView(index: 2)
                }
                WaveChartView()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(10)
            .background(Color(.systemBackground))
            .onTapEndEditing()
        }
        .onAppear{
            Store.shared.home.isRefreshWave = true
        }
        .onDisappear{
            Store.shared.home.isRefreshWave = false
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(Store.shared)
            .environment(\.colorScheme, .light)
    }
}


struct NavView: View {
    @EnvironmentObject var store: Store
    var binding: Binding<AppState.Home>{
        $store.home
    }
    @State var isPresent = false
    
    var body: some View {
        
        HStack{
            Button(action: {
                self.store.soundSwitch()
            }) {
                Image(systemName: self.binding.isSoundEnable.wrappedValue ? "speaker.2" : "speaker.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(10)
                    .frame(width: 44, height: 44)
                    .foregroundColor(Color(.systemTeal))
            }
            
            Spacer()
            
            Picker(selection: self.binding.protocolSelectIndex, label: Text("Picker")){
                Text("BCI Protocol").tag(0)
                Text("Berry Protocol").tag(1)
            }.pickerStyle(SegmentedPickerStyle())
            .frame(width: 220)
            
            Spacer()
            
            Button(action: {
                self.isPresent.toggle()
            }) {
                Image(self.binding.mPeripheralState.wrappedValue == .connected ? "bluetooth_connect" : "bluetooth" )
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(10)
                    .frame(width: 44, height: 44)
                    .colorMultiply(Color(.systemTeal))
            }
            .sheet(isPresented: self.$isPresent) {
                DeviceView().environmentObject(Store.shared)
            }
        }.background(Color(.systemBackground))
    }
}

struct InfoView: View {
    @EnvironmentObject var store: Store
    var binding: Binding<AppState.Home>{
        $store.home
    }
    
    var body: some View {
        
        VStack(spacing: 10){
            VStack(spacing: 10){
                HStack{
                    Text("Device: ")
                        .foregroundColor(Color(.label))
                    Text(self.binding.mPeripheral.wrappedValue?.name ?? "--")
                    
                    Spacer()
                    
                    if let _ = self.binding.mPeripheral.wrappedValue?.name{
                        Button(action: {
                            Bluetooth.shared.disconnect()
                        }){
                            Text("Disconnect")
                                .font(.system(size: 12))
                                .frame(width: 80, height: 30)
                                .foregroundColor(Color.white)
                                .background(Color(.systemTeal))
                                .cornerRadius(6.0)
                        }
                    }
                }.frame(height: 30)
                .onTapEndEditing()
                
                HStack{
                    Text("New Name: ")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    TextField("", text: self.binding.newName)
                        .font(.system(size: 12))
                        .padding([.leading,.trailing],10)
                        .frame(height: 30)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6.0)
                    
                    Spacer()
                    Button(action: {
                        let name = self.binding.newName.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        Bluetooth.shared.setName(name)
                    }){
                        Text("Set")
                            .font(.system(size: 12))
                            .frame(width: 80, height: 30)
                            .foregroundColor(Color.white)
                            .background(Color(.systemTeal))
                            .cornerRadius(6.0)
                    }
                }
                
                VersionCell(title: "Software Version: ",content: self.binding.softwareVersion.wrappedValue){
                    Bluetooth.shared.getSoftwareVersion()
                }
                
                VersionCell(title: "Hardware Version: ",content: self.binding.hardwareVersion.wrappedValue){
                    Bluetooth.shared.getHardwareVersion()
                }
                
                VersionCell(title: "Bluetooth Version: ",content: self.binding.bluetoothVersion.wrappedValue){
                    Bluetooth.shared.getBluetoothVersion()
                }
            }.contentShape(Rectangle())
            .onTapEndEditing()
            
            VStack{
                Picker("", selection: self.binding.frequencySelectIndex) {
                    Text("50Hz").tag(0)
                    Text("100Hz").tag(1)
                    Text("200Hz").tag(2)
                    Text("1Hz").tag(3)
                }.pickerStyle(SegmentedPickerStyle())
                
                Picker("", selection: self.binding.filterSelectIndex) {
                    Text("Original").tag(0)
                    Text("Filtered").tag(1)
                    Text("Stop").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
            }
        }.padding(10)
        .background(Color(.systemBackground))
    }
}


struct ParamView: View {
    @EnvironmentObject var store: Store
    var binding: Binding<AppState.Home>{
        $store.home
    }
    var index: Int
    
    var body: some View {
        Group{
            switch index {
            case 0:
                ParamCell(value: binding.spo2Txt.wrappedValue, title: "SPO2", unit: "%", bgColor: Color("spo2Color"))
            case 1:
                ParamCell(value: binding.prTxt.wrappedValue, title: "PR", unit: "bpm", bgColor: Color("prColor"))
            default:
                ParamCell(value: binding.piTxt.wrappedValue, title: "PI", unit: "%", bgColor: Color("piColor"))
            }
        }
    }
}


struct ParamCell: View {
    var value: String
    var title: LocalizedStringKey
    var unit: String
    var bgColor: Color
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                VStack{
                    Text(title).font(.system(size: 17))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text(unit).font(.system(size: 17, weight: .thin))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Text(value).font(.system(size: min(geo.size.width, geo.size.height) / 2, weight: .thin))
            }
        }
        .padding(10)
        .foregroundColor(Color(.white))
        .background(bgColor)
        .cornerRadius(12)
    }
}

struct VersionCell: View {
    var title: String
    var content: String
    var action: () -> Void
    var body: some View {
        HStack{
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
            
            Text(content)
                .font(.system(size: 14))
            
            Spacer()
            
            Button(action: action){
                Text("Get")
                    .font(.system(size: 12))
                    .frame(width: 80, height: 30)
                    .foregroundColor(Color.white)
                    .background(Color(.systemTeal))
                    .cornerRadius(6.0)
            }
        }
    }
}
