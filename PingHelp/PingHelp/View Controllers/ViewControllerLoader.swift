//
//  UIStoryboardLoader.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-24.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import UIKit

class ViewControllerLoader: NSObject {
    static let sharedInstance = ViewControllerLoader()
    private var storyboard = UIStoryboard.init(name: "Main", bundle: nil)
    
    public  func getHomeVC() -> HomeViewController {
        let homeVC = HomeViewController.init()
        return homeVC
    }
    
    public func getBeaconsPairingVC() -> PingBeaconPairing {
        let beaconPairingVC = PingBeaconPairing.init()
        return beaconPairingVC
    }
    
}
