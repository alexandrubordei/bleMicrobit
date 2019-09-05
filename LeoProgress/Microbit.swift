//
//  Microbit.swift
//  LeoProgress
//
//  Created by Alexandru Bordei on 9/5/19.
//  Copyright © 2019 Alexandru Bordei. All rights reserved.
//

import Foundation
import CoreBluetooth




class Microbit: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
    var centralManager: CBCentralManager!
    var microBit:CBPeripheral?
    
    var keepScanning: Bool = true
    var state: String = ""
    let timerScanInterval = 10
    var scanningTimer: Timer?
    
    weak var delegate:MicrobitDelegate?
    
    // UART SERVICE
    let UARTServiceUUID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    // RX - Send data to microbit
    // Write
    let UART_RX_CharacteristicUUID = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    var uartRXcharacteristic:CBCharacteristic?
    // TX - Receive data from the microbit
    // Notify, Read
    let UART_TX_CharacteristicUUID = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    var uartTXcharacteristic:CBCharacteristic?
    
    
    let MB_NAME = "BBC micro:bit"
    
    var microbit: CBPeripheral!
    
    override init() {
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self,
                                               queue: DispatchQueue.main)
    }
    
    func setStatus(status: String){
        if(self.delegate != nil)
        {
            self.delegate?.microbitDidUpdateStatus(status: status)
        }
    }
    
    //peripherial found
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        let deviceName = peripheral.name != nil ? peripheral.name! : "unknown"
        log("Discovered "+deviceName+"\n")
        
        
        if(deviceName.starts(with:MB_NAME)){
            log("Connecting to "+deviceName)
            self.microBit = peripheral
            self.microBit?.delegate = self
            stopScan()
            self.centralManager.connect(self.microBit!, options:nil)
        }
    }
    
    //peripherial connected
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        let deviceName = peripheral.name != nil ? peripheral.name! : "unknown"
        log("connected to "+deviceName)
        
        setStatus(status: "Connected to "+deviceName)
       
        
        peripheral.discoverServices(nil)
        
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?)
    {
        log("Error while connecting to "+peripheral.name!+" "+error.debugDescription)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log("Looking for peripheral services")
        for service in peripheral.services! {
            let thisService = service as CBService
            log("Service UUID = \(thisService.uuid)")
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?)
    {
        log("Peripherial was disconnected "+peripheral.name!)
        
        setStatus(status:"Disconnected")
        resumeScan();
    }
    
    
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log("Discovering Characteristics")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            log("Characteristic UUID = \(thisCharacteristic.uuid)")
            
            switch thisCharacteristic.uuid {
            case UART_RX_CharacteristicUUID :
                log("UART RX characteristic found")
                uartRXcharacteristic = thisCharacteristic
            case UART_TX_CharacteristicUUID :
                log("UART TX characteristic found")
                uartTXcharacteristic = thisCharacteristic
                peripheral.setNotifyValue(true, for: thisCharacteristic)
            default:
                break
            }
        }
    }
    
    
    var lastMessage="";
    public func uartSend(message:String) {
        guard let uartRXcharacteristic = uartRXcharacteristic else {return}
        if let messageData = message.data(using:String.Encoding.utf8) {
            
            if(lastMessage != message)
            {
                log("Sending to microbit:"+message);
                
                self.microBit?.writeValue(messageData, for: uartRXcharacteristic, type: CBCharacteristicWriteType.withResponse)
                
                lastMessage=message
            }
        }
    }
    
    //state updated
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            
            resumeScan()
            
        case .poweredOff:
            state = "Bluetooth on this device is currently powered off."
        case .unsupported:
            state = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            state = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            state = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            state = "The state of the BLE Manager is unknown."
        }
    }
    
    @objc func pauseScan()
    {
        self.keepScanning = false
        
        self.centralManager.stopScan()
        
        self.scanningTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
    }
    
    @objc func resumeScan()
    {
        
        self.keepScanning = true
        //  let services:[CBUUID] = [CBUUID(string: MB_ACCELEROMETER)]
        //   CBUUID(string: MB_MAGNETOMETER)]
        //CBUUID(string: MB_MAGNETOMETER)]
        
        self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        self.scanningTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
        
        log("scanning resumed\n")
    }
    
    func stopScan()
    {
        centralManager.stopScan()
        self.scanningTimer?.invalidate()
        self.scanningTimer = nil
    }
    
    func log(_ text:String)
    {
        print(text+"\r\n")
    }
}


protocol MicrobitDelegate: class{
    func microbitDidUpdateStatus(status:String)
}
