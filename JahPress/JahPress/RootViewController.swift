//
//  ViewController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 11.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import GoogleMobileAds
import SwiftEventBus
import AVFoundation
import Anchorage

class RootViewController: UIViewController, AppDependencyInjectable {

    let backgroundAnimationKey = "BackgroundAnimationKey.Color"

    var backgroundListener: Any?
    var activeListener: Any?

    var dependencies: AppDependencies!
    var bannerView: GADBannerView!

    @IBOutlet weak var backgroundContainer: UIView!
    @IBOutlet weak var bannerViewContainer: UIView!
    @IBOutlet weak var bannerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var unicornImageView: UIImageView!

    var unicornOn: Bool = false {
        didSet {
            guard unicornOn != oldValue else { return }

            if unicornOn {

                // start image shizzle
                unicornImageView.isHidden = false
                unicornImageView.animationImages = [
                    UIImage(named: "unicorn")!,
                    UIImage(named: "unicorn_2")!,
                    UIImage(named: "unicorn_3")!
                ]
                unicornImageView.animationDuration = 0.5
                unicornImageView.animationRepeatCount = -1
                unicornImageView.startAnimating()

                // play sound
                let url = Bundle.main.url(forResource: "unicorn", withExtension: "mp3")!
                var soundId: SystemSoundID = 0
                AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
                AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { soundId, _ -> Void in
                    AudioServicesDisposeSystemSoundID(soundId)
                }, nil)
                AudioServicesPlaySystemSound(soundId)

//                NSString *path = [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] pathForResource:@"Tock" ofType:@"aiff"];
//                SystemSoundID soundID;
//                AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &soundID);
//                AudioServicesPlaySystemSound(soundID);
//                AudioServicesDisposeSystemSoundID(soundID);

            } else {
                unicornImageView.stopAnimating()
                unicornImageView.isHidden = true
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        dependencies.inject(into: segue.destination)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        SwiftEventBus.onMainThread(self, name: EventIdentifiers.Unicorn) { _ in
            self.unicornOn = true
        }

        unicornImageView.isHidden = true

//        let v = GradientView(frame: backgroundContainer.bounds, colors: [UIColor.rastaGreenPastell, UIColor.white])
//        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        backgroundContainer.addSubview(v)
        backgroundContainer.backgroundColor = UIColor.rastaGreenPastell

        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerViewContainer.addSubview(bannerView)

        // test
        bannerView.adUnitID = BuildConfiguration.adMobBannerId
        bannerView.rootViewController = self

        let request = GADRequest()
        request.testDevices = ["3e6cf5427b582f996854906a2bec679e"]
        request.keywords = ["Dancehall", "Ragga", "Reggae", "Reagge", "Roots", "Ska", "Rocksteady",
                            "Radio", "Jah", "Riddim Fire", "Bob Marley", "JahPress", "Root boy", "Jamaica", "air horn",
                            "wicked", "Sound effects", "Beat", "Zion", "Ganja", "Rasta",
                            "Inner Circle", "Peter Tosh", "Israel Vibration", "Jah Roots", "Sean Paul", "The Rastafarians",
                            "Roots Radics", "Sean Kingston", "Jimmy Cliff", "Collie Buddz", "US40", "Capleton", "Burning Spear",
                            "Yellowman", "Gyptian", "The Ethiopians", "Sizzla", "Junior Reid", "Ragga Twins", "Buju Banton",
                            "Matthew Mcanuff", "Gregory Isaacs", "Lee Scratch Perry"]

        bannerView.load(request)
        bannerView.delegate = self

        backgroundListener = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.stopBackgroundAnimation()
        }

        activeListener = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.startBackgroundAnimation()
        }

        startBackgroundAnimation()

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func applicationDidBecomeActive(note: Notification) {
        checkPrivacyPolicy()
    }

    override func viewDidAppear(_ animated: Bool) {
        checkPrivacyPolicy()
    }

    private func checkPrivacyPolicy() {
        if !JahUserDefaults.privacyPolicyAccepted {

            let alertController = UIAlertController(title: "Privacy Policy", message: "To use JahPress, you must accept the privacy policy.", preferredStyle: .alert)
            let privacyPolicyAction = UIAlertAction(title: "View Privacy Policy", style: .default) { [weak self] _ in
//                guard let url = URL(string: "http://www.jahpress.de/privacy_policy.html") else { return }
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                guard let vc = self?.storyboard?.instantiateViewController(withIdentifier: "PrivacyPolicyViewController") else { return }
                self?.present(vc, animated: true, completion: nil)
            }
            alertController.addAction(privacyPolicyAction)

            self.present(alertController, animated: true, completion: nil)
        }
    }

    func startBackgroundAnimation() {
        return

//        let animation = CAKeyframeAnimation(keyPath: "backgroundColor")
//
//        animation.values = [UIColor.rastaGreenPastell.cgColor, UIColor.rastaYellowPastell.cgColor, UIColor.rastaRedPastell.cgColor]
//        animation.keyTimes = [Float(1.0/3.0) as NSNumber, Float(2.0/3.0) as NSNumber, Float(1.0) as NSNumber]
//        animation.calculationMode = kCAAnimationPaced
//        animation.isRemovedOnCompletion = false
//        animation.duration = 15
//        animation.fillMode = kCAFillModeForwards
//        animation.autoreverses = true
//        animation.repeatCount = Float.infinity
//
//        self.backgroundContainer.layer.add(animation, forKey: backgroundAnimationKey)
    }

    func stopBackgroundAnimation() {
        self.backgroundContainer.layer.removeAnimation(forKey: backgroundAnimationKey)
    }
}

extension RootViewController: GADBannerViewDelegate {

    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerHeightConstraint.constant = kGADAdSizeBanner.size.height
        self.bannerView.centerXAnchor == bannerViewContainer.centerXAnchor
        self.bannerView.topAnchor == bannerViewContainer.topAnchor
        self.bannerView.bottomAnchor == bannerViewContainer.bottomAnchor
        bannerViewContainer.setNeedsLayout()
        bannerViewContainer.layoutIfNeeded()
    }
}
