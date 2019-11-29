//
//  AppDelegate.swift
//  PingHelp
//
//  Created by Jatinder on 2019-11-03.
//  Copyright © 2019 PingHelp. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundTaskIdentifier : UIBackgroundTaskIdentifier?
    static let kFetchIntervalInSeconds : TimeInterval = 120
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        clearNotificationBadge()
        
        // Fetch data once every 2 minutes.
        UIApplication.shared.setMinimumBackgroundFetchInterval(AppDelegate.kFetchIntervalInSeconds)
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        clearNotificationBadge()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Start Monitoring beacons when app is killed //
        PingLocationManager.sharedInstance.locationManager.startMonitoring(for: PingLocationManager.sharedInstance.pingRegion)
    }
    
    
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void) {
        // Check for new data.
        print("Scanning beacons from background fetch")
        PingBeaconManager.sharedInstance.startScan(isReadingFrames: true)
        completionHandler(.noData)
    }
    
    func clearNotificationBadge()  {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

