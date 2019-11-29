//
//  PingBeaconManager.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-07.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import Foundation
import UIKit
import MTBeaconPlus

protocol PingBeaconManagerDelegate: class {
    func updateBeaconListing(beacons : [MTPeripheral]!)
}

protocol BeaconManager {
    
    func detectBeaconsinRange(scannedBeacons : [MTPeripheral]!, readFramesOnly : Bool)
    func checkBluetoothStatus() -> PowerState
    
}

enum CurrentState : String {
    case Scanning, Connected, IDLE
}

class PingBeaconManager : BeaconManager {
    
    var centralManager : MTCentralManager!
    var scannedDevices : Array<MTPeripheral>!
    var minewUrl : MinewURL?
    var lastScannedFrame : MinewFrame?
    static let sharedInstance = PingBeaconManager()
    var pingBeaconManagerDelegate : PingBeaconManagerDelegate?
    public var regionUUID : String?
    static let kRestartTime = 25.0
    
    internal func initializeBeaconDetection()  {
        if (centralManager == nil) {
            centralManager = MTCentralManager.sharedInstance()
        }
        
    }
    
    func detectBeaconsinRange(scannedBeacons : [MTPeripheral]!, readFramesOnly : Bool) {
        
        print("\n Beacons found : ", centralManager.scannedPeris as [MTPeripheral])
        
        scannedBeacons.forEach { (beacon) in
            self.readFrames(for: beacon)
        }
    }
    
    @objc  func readPackets () {
        print("Reading packets now")
        self.startScan(isReadingFrames: true)
    }
    
    public func startScan(isReadingFrames : Bool) -> Void {
        DispatchQueue.main.async {
            self.centralManager?.startScan { (devices) in
                //Traverse and get every beacon around you.
                self.scannedDevices = devices
                
                self.detectBeaconsinRange(scannedBeacons: devices, readFramesOnly: isReadingFrames)
            }
            self.scannedDevices = self.centralManager?.scannedPeris
        }
    }
    
    public func stopScan() -> Void {
        
        centralManager.stopScan()
        
        ViewControllerLoader.sharedInstance.getHomeVC().currentStatus = .IDLE
        
        //Restart scan after sometime.
        DispatchQueue.main.asyncAfter(deadline: .now() + PingBeaconManager.kRestartTime, execute: {
            print("Restart scanning beacons after \(PingBeaconManager.kRestartTime) seconds")
            self.lastScannedFrame = nil
            self.startScan(isReadingFrames: true)
            
        })
    }
    
    
    func checkBluetoothStatus() -> PowerState {
        return centralManager.state
    }
    
    func readSensorInfo(for peripheral : MTPeripheral) -> Void {
        peripheral.connector.sensorHandler.readSensorHistory { (sensorData) in
            print("Sensor Info == \(sensorData)")
        }
    }
    
    func readFrames(for peripheral : MTPeripheral) -> Void {
        
        print("Reading Frames \(peripheral.framer.advFrames as [MinewFrame]) for \(peripheral.framer.name ?? "") with RSSI \(peripheral.framer.rssi)")
        
        peripheral.framer.advFrames.forEach { (frame) in
            
            if frame.frameType == .FrameiBeacon {
                let minewBeacon = frame as! MinewiBeacon
                regionUUID = minewBeacon.uuid
                print("iBeacon frame with data = ",minewBeacon as Any)
                sendHelpRequest()
            }
        }
        
    }
    
    func sendHelpRequest() -> Void {
        
        PingLocationManager.sharedInstance.sendNotification(urlString: minewUrl?.urlString) {
            self.stopScan() //Stop scanning we got the packet.
        }
    }
}
