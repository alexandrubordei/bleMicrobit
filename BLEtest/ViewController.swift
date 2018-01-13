//
//  ViewController.swift
//  BLEtest
//
//  Created by Alexandru Bordei on 1/11/18.
//  Copyright © 2018 Alexandru Bordei. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
  
    var centralManager: CBCentralManager!
    var microBit:CBPeripheral?
    var keepScanning: Bool = true
    var state: String = ""
    let timerScanInterval = 10
    var scanningTimer: Timer?
    
    let MB_ACCELEROMETER   =    CBUUID(string:"E95D0753-251D-470A-A062-FA1922DFA9A8")
    let MB_MAGNETOMETER    =    CBUUID(string:"E95DF2D8-251D-470A-A062-FA1922DFA9A8")
    let MB_ACCELEROMETER_DATA = CBUUID(string:"E95DCA4B-251D-470A-A062-FA1922DFA9A8")
    let MB_NAME = "BBC micro:bit"
    
    var microbit: CBPeripheral!

    
    @IBOutlet weak var lblX: UILabel!
    @IBOutlet weak var lblY: UILabel!
    @IBOutlet weak var lblZ: UILabel!
    @IBOutlet weak var lblRSSI: UILabel!
    
    
    
    //peripherial found
     func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        let deviceName = peripheral.name != nil ? peripheral.name! : "unknown"
        log("Discovered "+deviceName+"\n")
        
        
        if(deviceName==MB_NAME){
            log("Connecting to "+deviceName)
            self.microBit = peripheral
            self.microBit?.delegate = self
            self.centralManager.connect(self.microBit!, options:nil)
        }
    }
    
    //peripherial connected
    func centralManager(_ central: CBCentralManager,
        didConnect peripheral: CBPeripheral) {
        
            let deviceName = peripheral.name != nil ? peripheral.name! : "unknown"
            log("connected to "+deviceName)
            peripheral.discoverServices(nil)
            stopScan()
        
            startReadRSSI()
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?)
    {
        log("Error while connecting to "+peripheral.name!+" "+error.debugDescription)
    }
    
    //services discovered
     func peripheral(_ peripheral: CBPeripheral, didDiscoverServices: Error?){
        
        for service in peripheral.services! {
            
            let accelCharUUID = [MB_ACCELEROMETER_DATA]
            if service.uuid == MB_ACCELEROMETER {
                log("Discovered accelerometer service")
                peripheral.discoverCharacteristics(accelCharUUID, for: service)
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            log("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        
        log("[DEBUG] Found characteristics for peripheral: \(peripheral.identifier.uuidString)")
       
        for characteristic in service.characteristics!
        {
            self.microBit?.setNotifyValue(true, for: characteristic)
        }
       
    }
    
   
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            
            print("[ERROR] Error updating value. \(error!.localizedDescription)")
            return
        }
        
        if characteristic.uuid == MB_ACCELEROMETER_DATA {
            var data = characteristic.value!
        

            data.withUnsafeMutableBytes { (bytes:UnsafeMutablePointer<UInt8>)->Void in
               
                let x = Int16(bitPattern: UInt16(bytes[1]) << 8 | UInt16(bytes[0]))
                let y = Int16(bitPattern: UInt16(bytes[3]) << 8 | UInt16(bytes[2]))
                let z = Int16(bitPattern: UInt16(bytes[5]) << 8 | UInt16(bytes[4]))
                
                /*
                let x = Double(bytes[0].byteSwapped)/1000.0
                let y = Double(bytes[1].byteSwapped)/1000.0
                let z = Double(bytes[2].byteSwapped)/1000.0
                */
              //  if(abs(x)>10 || abs(y)>10 || abs(z)>10 )
               // {
                    lblX.text = "\(x)"
                    lblY.text = "\(y)"
                    lblZ.text = "\(z)"
                    
                    log("Received x=\(x) y=\(y) z=\(z)")
                //}
            }
            
        }
    }
    
    //on rssi update
    func peripheral(_ peripheral: CBPeripheral,
                    didReadRSSI RSSI: NSNumber,
                    error: Error?)
    {
        
        updateRSSIReading(RSSI)
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
    
    func startReadRSSI()
    {
        log("Starting to request RSSI")
         self.scanningTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(readRSSI), userInfo: nil, repeats: true)
    }
    
    @objc func readRSSI()
    {
        self.microBit?.readRSSI()
    }
    
    func stopReadRSSI()
    {
        self.scanningTimer?.invalidate()
        self.scanningTimer=nil
        log("Stopped RSSI scanning")
    }
    /*
     Transmisson Power
     Eight user configurable settings from 0 (-30dbm) to 7 (+4dbm).
     Distance = 10^((TP - RSSI)/(10*N))
     https://lancaster-university.github.io/microbit-docs/ubit/radio/
     https://iotandelectronics.wordpress.com/2016/10/07/how-to-calculate-distance-from-the-rssi-value-of-the-ble-beacon/
    */
    func updateRSSIReading(_ RSSI: NSNumber)
    {
         let rssi = RSSI.intValue
         let MP = -65 //at one meter distance
         let N = 2
         let pw = Double(MP - rssi)/(10.0*Double(N))
         let distance = pow(10,pw)
         self.lblRSSI.text = "RSSI=\(rssi)Db est. \(distance)m"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.centralManager = CBCentralManager(delegate: self,
                                     queue: DispatchQueue.main)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func log(_ text:String)
    {
        print(text+"\r\n")
        
    }
    
    


}

