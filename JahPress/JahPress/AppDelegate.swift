//
//  AppDelegate.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 11.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import AVFoundation

import GoogleMobileAds
//import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppDependencyInjectable {

    var dependencies: AppDependencies!
    var window: UIWindow?

    override init() {

        JahUserDefaults.loadDefaults()

        let globalLogger = ROLogger(category: "global")
        globalLogger.info("global logger initialized")

        let dataStore = DataStore()

        dependencies = AppDependencies(
            globalLogger: globalLogger,
            shoutcastAPI: ShoutcastAPI(dataStore: dataStore, networkService: NetworkService(logger: globalLogger), logger: globalLogger),
            dataStore: dataStore)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        GADMobileAds.sharedInstance().start(completionHandler: nil)

        if BuildConfiguration.environemt == .prod {

            // Init FireBase
            //FirebaseApp.configure()
        }

        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(.playback, mode: .default)
            // , options: [.allowAirPlay, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            try session.setActive(true, options: .notifyOthersOnDeactivation)
//
//            try session.setCategory(
//                AVAudioSession.Category.ambient,
//                mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.default)),
//                options: )
//            try session.setActive(true)
        } catch {
            ErrorReporter().reportError(error: error)
        }

        if let rootViewController = self.window?.rootViewController as? RootViewController {
            dependencies.inject(into: rootViewController)
        }

        self.window?.makeKeyAndVisible()

        setUpAppearance()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if BuildConfiguration.environemt == .prod { }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }

    private func setUpAppearance() {

        UITabBar.appearance().backgroundImage = UIImage(color: UIColor.black)
        UITabBar.appearance().shadowImage = UIImage(color: UIColor.black, size: CGSize(width: 1000, height: 0.25))
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().tintColor = UIColor.white
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 1, alpha: 0.4)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .normal)

        if #available(iOS 13, *) {

        } else {
            UIView.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.black
            UISearchBar.appearance().backgroundColor = UIColor.clear
            UISearchBar.appearance().tintColor = UIColor.clear
            UISearchBar.appearance().isTranslucent = true
            UISearchBar.appearance().backgroundImage = UIImage(color: UIColor.clear)
        }
    }
}


// Helper function inserted by Swift 4.2 migrator.
private func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
