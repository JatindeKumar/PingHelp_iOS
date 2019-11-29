//
//  PingManager.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-07.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import Foundation

class PingManager {
    
    static let sharedInstance = PingManager()
    
    init() { }
    
    func initializeBeaconTracker()   {
        PingBeaconManager.sharedInstance.initializeBeaconDetection()
        
    }
    
    func startLocationTracking()  {
        PingLocationManager.sharedInstance.startLocationTracking()
    }
    
}
