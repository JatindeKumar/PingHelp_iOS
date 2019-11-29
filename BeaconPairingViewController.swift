//
//  PingBeaconPairing.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-24.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import UIKit
import MTBeaconPlus

class PingBeaconPairing: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var tableViewListing: UITableView!
    @IBOutlet weak var viewNoBeaconsFound: UIView!
    private let refreshControl = UIRefreshControl()
    static let kBroadcastTime = 20.0
    var value: Float = 1.0;
   
    
    var progStep: Float {
        set(newValue) {
            if newValue != value {
                value = newValue
            }
        }
        get {
            return value + 1.0
        }
    }
    
    lazy var loadingView : ALLoadingView = {
        let loader = ALLoadingView.manager
        loader.resetToDefaults()
        loader.blurredBackground = true
        loader.itemSpacing = 120
        loader.showLoadingView(ofType: .progress, windowMode: .fullscreen, completionBlock: nil)
        return loader
    }()
    
    lazy var beaconsinRange : [MTPeripheral] = {
        let beacons =  PingBeaconManager.sharedInstance.centralManager.scannedPeris
        return beacons ?? []
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showNoBeaconFoundView(hidden: true)
        
    }
    
    private func showNoBeaconFoundView (hidden : Bool) {
        viewNoBeaconsFound.isHidden = hidden
    }
    
    private func setupView () {
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationItem.hidesBackButton = false
        
        if #available(iOS 10.0, *) {
            tableViewListing.refreshControl = refreshControl
        } else {
            tableViewListing.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshBeaconListing), for: .valueChanged)
        tableViewListing.reloadData()
    }
    
    
    @objc func refreshBeaconListing() {
        PingBeaconManager.sharedInstance.readPackets()
        perform(#selector(fetchNewBeacons), with: nil, afterDelay: 5.0)
        
    }
    
    @objc func fetchNewBeacons () {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        tableViewListing.reloadData()
    }
    
    //MARK:- TableView Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if beaconsinRange.count == 0 {
            showNoBeaconFoundView(hidden: false)
            self.view.bringSubviewToFront(viewNoBeaconsFound)
        }
        else {
             showNoBeaconFoundView(hidden: true)
        }
       
        return beaconsinRange.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconCell", for: indexPath) as! BeaconsTableViewCell
        let beacon = beaconsinRange[indexPath.row]
        
        cell.lblValueTitle.text = beacon.framer.name
        cell.lblValueRSSI?.text = String(beacon.framer.rssi)
        cell.lblValueBattery.text = String("\(beacon.framer.battery) %")
        
        if beacon.framer.connectable == true {
            if #available(iOS 13.0, *) {
                cell.imageViewStatus.image = UIImage.init(systemName: "checkmark.seal.fill")
            } else {
                // TODO: Add Tick image here.
                cell.imageViewStatus.image = UIImage.init(named: "checked")
            }
        }
        else {
            if #available(iOS 13.0, *) {
                cell.imageViewStatus.image = UIImage.init(systemName: "exclamationmark.triangle")
            } else {
                // TODO: Add cross image here.
                cell.imageViewStatus.image = UIImage.init(named: "cancel")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBeacon = beaconsinRange[indexPath.row]
        
        if selectedBeacon.framer.connectable == true {
            self.connectToPeripheral(peripheral: selectedBeacon, passwordStatus: selectedBeacon.connector.passwordStatus)
        }
        else {
            let  nonConnectableAlert = UIAlertController(title: "Alert!", message: "Unable to connect with beacon at the moment.", preferredStyle: .alert)
            nonConnectableAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action) in
                print("User confirmed help")
            }))
            self.present(nonConnectableAlert, animated: true)
        }
        
    }
    
    
    
}

extension PingBeaconPairing {
    
    func connectToPeripheral(peripheral : MTPeripheral, passwordStatus : PasswordStatus) -> Void {
        
        peripheral.connector.statusChangedHandler = { (status, error) in
            
            if error != nil {
                print(error as Any)
                PingBeaconManager.sharedInstance.centralManager.disconnect(fromPeriperal: peripheral)
                self.showAlert(isConnected: false)
            }
            
            switch status {
                
            case .StatusConnected:
                print("Reading Beacon Info = ",peripheral.framer.name ?? "", peripheral.framer.battery, peripheral.framer.rssi as NSInteger)
                
                
                break
                
            case .StatusCompleted:
                
                self.loadingView.updateProgressLoadingView(withMessage: "Connected", forProgress: self.progStep)
                
                self.writeFrame(peripheral: peripheral) { (isSuccess) in
                    if isSuccess {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                            self.writeTrigger(peripheral: peripheral)
                        })
                    }
                    else {
                        print("Failed to write frames to beacons")
                    }
                }
                
                break
                
            case .StatusDisconnected:
                //                self.loadingView.updateMessageLabel(withText: "Disconnected")
                self.updateProgress(message: "Failed, Please try again later.", progress: 20)
                break
                
            case .StatusConnectFailed:
                self.updateProgress(message: "Failed, Please try again later.", progress: 20)
                print("connect failed")
                break
                
            case .StatusUndifined:
                self.updateProgress(message: "Undefined, please try again", progress: 20)
                break
                
            case .StatusConnecting:
                print("Connecting with beacon ",peripheral.identifier ?? "")
                self.updateProgress(message: "Connecting", progress: self.progStep)
                
                break
                
            case .StatusReadingInfo:
                //Try to connect with device.
                print("Reading Beacon Info = ",peripheral.framer.name ?? "", peripheral.framer.battery, peripheral.framer.rssi as NSInteger)
                self.updateProgress(message: "Reading Info", progress: self.progStep)
                
                break
                
            case .StatusReadingFrames:
                print("Reading frames")
                //Fetch battery info & range etc and display on pairing screen.
                self.updateProgress(message: "Reading Frames", progress: self.progStep)
                break
                
            case .StatusReadingSensorInfo:
                print("Reading sensors Info = ",peripheral.connector.sensorHandler.sensorDataDic)
                self.updateProgress(message: "Reading Sensors", progress: self.progStep)
                break
                
            case .StatusPasswordValidating:
                print("Validating password")
                self.updateProgress(message: "Validating Password", progress: self.progStep)
                break
            default:
                break
                
            }
        }
        
        //Connect with default password
        PingBeaconManager.sharedInstance.centralManager.connect(toPeriperal:peripheral, passwordRequire: { (pass) in
            pass!("minew123")
        })
    }
    
    func writeFrame(peripheral : MTPeripheral, completion:@escaping (Bool) -> Void) {
        
        self.loadingView.updateProgressLoadingView(withMessage: "Writing Frames", forProgress: self.progStep)
        
        let ib = MinewiBeacon.init()
        ib.slotNumber = 0
        ib.uuid = kRegionUUID
        ib.major = 9190 //Needs to be dynamic
        ib.minor = 33   //Needs to be dynamic
        ib.slotAdvInterval = 1000
        ib.slotAdvTxpower = 0
        ib.slotRadioTxpower = -4
        
        
        peripheral.connector.write(ib, completion: { (success, error) in
            if success {
                print("write success,%d",ib.slotRadioTxpower)
                print("battery is %d",ib.battery)
                completion(true)
            }
            else {
                print(error as Any)
                completion(false)
            }
        })
        
    }
    
    
    //Write beacon triggers to broadcast specific packets.
    func writeTrigger(peripheral : MTPeripheral) -> Void {
        
        self.loadingView.updateProgressLoadingView(withMessage: "Writing Triggers", forProgress: self.progStep)
        
        //Write this trigger to broadcast ibeacon packets.
        let triggerDataDoubleTap = MTTriggerData.init(slot: 0, paramSupport: true, triggerType: TriggerType.btnDtapLater, value: 20)
        
        peripheral.connector.writeTrigger(triggerDataDoubleTap) { (success) in
            if success {
                print("write Double Tap triggerData success")
                self.loadingView.updateProgressLoadingView(withMessage: "Pairing Successful", forProgress: 20)
                
            }
            else {
                print("write Double Tap triggerData failed")
            }
            
            self.disconnectAndStartMonitoring(connectedPeripheral: peripheral)
        }
        
    }
    
    func disconnectAndStartMonitoring (connectedPeripheral : MTPeripheral) {
        PingBeaconManager.sharedInstance.regionUUID = kRegionUUID
        self.showAlert(isConnected: true)
        PingBeaconManager.sharedInstance.centralManager.disconnect(fromPeriperal: connectedPeripheral)
        PingBeaconManager.sharedInstance.stopScan()
        PingLocationManager.sharedInstance.locationManager.startMonitoring(for: PingLocationManager.sharedInstance.pingRegion)
//        PingBeaconManager.sharedInstance.startScan(isReadingFrames: true)
       
    }
    
    func showAlert(isConnected:Bool) -> Void {
        var alert = UIAlertController()
        
        if isConnected {
            alert = UIAlertController(title: "Alert!", message: "Pairing successfull!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go back", style: .default, handler: { (action) in
                self.goBackToDashboard()
            }))
        }
        else {
            alert = UIAlertController(title: "Alert!", message: "Failed to pair with selected beacon", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .destructive, handler: { (action) in
                self.refreshBeaconListing()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                self.goBackToDashboard()
            }))
        }
        self.present(alert, animated: true)
    }
    
    private func goBackToDashboard () -> Void {
        self.navigationController?.popViewController(animated: true)
    }
    
  private func updateProgress(message: String, progress : Float) -> Void {
           let progressVal = 0.2 * progress
           self.loadingView.updateProgressLoadingView(withMessage: message, forProgress: progressVal)
           
           if progressVal >= 2.0 {
               self.loadingView.hideLoadingView()
           }
           
       }
}

