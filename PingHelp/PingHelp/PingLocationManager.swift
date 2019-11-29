//
//  PingLocationManager.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-07.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation
import MTBeaconPlus

let kRegionIdentifier = "com.pingHelp.beaconRegion"
let kRegionUUID = "84BC72E4-B50F-43CD-884C-D4132D847E6D"

class PingLocationManager : NSObject, CLLocationManagerDelegate {
    
    fileprivate var currentLocation : CLLocation?
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    lazy var pingRegion : CLBeaconRegion = {
        var myBeaconRegion : CLBeaconRegion!
        //Save UUID if beacon is paired 
        if let regionUUID = PingBeaconManager.sharedInstance.regionUUID {
            let uuid = UUID(uuidString:regionUUID)
            myBeaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: kRegionIdentifier)
        }
        else {
            let uuid = UUID(uuidString:kRegionUUID)
             myBeaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: kRegionIdentifier)
        }
        myBeaconRegion.notifyOnEntry = true
        myBeaconRegion.notifyOnExit = true
        return myBeaconRegion
    }()
    
    lazy var locationManager : CLLocationManager = {
        
        let locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestAlwaysAuthorization()
        return locManager
        
    }()
    
    static let sharedInstance: PingLocationManager = {
        let instance = PingLocationManager()
        return instance
    }()
    
    func startLocationTracking()  {
        self.requestNotificationAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //MARK:- Notification functions
    func requestNotificationAuthorization() {
        // Auth options
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        
        self.userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
        
    }
    
    private func restartMonitoringFor(region : CLBeaconRegion) {
        locationManager.stopMonitoring(for: region)
        
        //Restart scan after sometime.
        DispatchQueue.main.asyncAfter(deadline: .now() + PingBeaconManager.kRestartTime, execute: {
            print("Restart monitoring beacons after \(PingBeaconManager.kRestartTime) seconds")
            self.locationManager.startMonitoring(for: region)
        })
    }
    
    public func sendNotification(urlString : String?, completion : () -> ()) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 0.5)
        notificationContent.title = "Pinged!"
        notificationContent.body = "Help is on the way!"
        notificationContent.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber+1)
        
        if let url = urlString {
            notificationContent.subtitle = url
        }
    
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "beaconNotification",
                                            content: notificationContent,
                                            trigger: trigger)
        
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
            else {
                print("Help Notification dropped")
            }
        }
        
        completion()
    }
    
    //MARK:- Location Delegates
    internal func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region == pingRegion {
            locationManager.startRangingBeacons(in: pingRegion)
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region == pingRegion {
            locationManager.stopRangingBeacons(in: pingRegion)
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("With in the beacons range")
            break
        case .outside:
            print("Outside the beacons range")
            break
            
        case .unknown:
            print("Uknown state")
            break
        
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if region == pingRegion {
            beacons.forEach { (beacon) in
                print("Beacon Ranged with Proximity \(beacon.proximity) and Accuracy \(beacon.accuracy)")
                if beacon.proximityUUID.uuidString == kRegionUUID {
                    manager.stopRangingBeacons(in: region)
                    self.sendNotification(urlString: "www.pinghelp.com") {
//                        self.restartMonitoringFor(region: region)
                        PingBeaconManager.sharedInstance.stopScan()

                    }
                }
                
            }
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if region == pingRegion {
            print("Failed to monitor region with \(error.localizedDescription)")
        }
    }
    
    internal func locationManager(_ manager:CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        print("locations = \(locations)")
        currentLocation = locations.last
        locationManager.stopUpdatingLocation()
    }
  
    internal  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse || status == CLAuthorizationStatus.authorizedAlways {
            manager.startUpdatingLocation()
        }
        
        if status == CLAuthorizationStatus.notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        else if status == CLAuthorizationStatus.denied {
            print("location access denied, go to settings to enable it.")
        }
        
    }
    
    
    
}
