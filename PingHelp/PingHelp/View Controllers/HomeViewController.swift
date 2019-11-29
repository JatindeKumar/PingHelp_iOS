//
//  ViewController.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-03.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import UIKit
import MTBeaconPlus

class HomeViewController: UIViewController {
    
    @IBOutlet weak var buttonPing: UIButton!
    @IBOutlet weak var lblTitle_Status: UILabel!
    @IBOutlet weak var lblStatusValue: UILabel!
    
    
    public var currentStatus : CurrentState = CurrentState.IDLE {
        willSet {
            updateStatusLabel(state: newValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        PingManager.sharedInstance.initializeBeaconTracker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentStatus = CurrentState.IDLE
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let powerState = PingBeaconManager.sharedInstance.checkBluetoothStatus()
            
            if powerState == PowerState.poweredOn {
                PingBeaconManager.sharedInstance.startScan(isReadingFrames: true)
                self.currentStatus = CurrentState.Scanning
            }
            else {
                self.showBluetoothSettings()
            }
        }
    }
    
    func startLocation()  {
        PingManager.sharedInstance.startLocationTracking()
    }
    
    func updateStatusLabel( state: CurrentState) -> Void {
        if let statusLabel = lblStatusValue {
            statusLabel.text = state.rawValue
        }
        
    }
    
    //Start Location Tracking & search beacons
    @IBAction func buttonClickedPingHelp(_ sender: Any) {
        //        self.startLocation()
        
        let  helpAlert = UIAlertController(title: "Alert!", message: "Help is on the way!", preferredStyle: .actionSheet)
        helpAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            print("User confirmed help")
        }))
        self.present(helpAlert, animated: true)
    }
    
    @IBAction func buttonClickedPairDevices(_ sender: Any) {
        let pingBeaconVC:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PingBeaconPairing") as UIViewController
        self.navigationController?.pushViewController(pingBeaconVC, animated: true)
    }
    
    public  func showBluetoothSettings()  {
        let alertController = UIAlertController (title: "Alert!", message: "Please turn on the bluetooth for scanning", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
}

