//
//  EffectViewController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 24.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import PromiseKit
import UIKit
import SwiftEventBus

class EffectViewController: UIViewController, AppDependencyInjectable {

    var dependencies: AppDependencies!

    private let defaultSpacing: CGFloat = 8
    private let defaultCellSize: CGSize = CGSize(width: 70, height: 70)

    @IBOutlet weak var effectsContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var crossFader: UISlider!
    @IBOutlet weak var muteFXButton: UIButton!
    @IBOutlet weak var muteMusicButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!

    var effects: [String: [EffectView]] = [:]
    var sectionNames: [String] = []

    override func viewDidLoad() {
        collectionView.backgroundView = UIView(frame: CGRect.zero)
        collectionView.backgroundColor = UIColor.black
        loadEffects().map { _ in
            self.collectionView.reloadData()
            self.pageControl.numberOfPages = self.pages
        }.catch { error in
            self.dependencies.globalLogger.error("\(error)")
        }.finally {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }

        crossFader.setThumbImage(UIImage(named: "Crossfader"), for: .normal)

        let fxImage = UIImage(named: "speaker")
        muteFXButton.setImage(fxImage, for: .normal)
        muteFXButton.tintColor = UIColor.white

        let musicImage = UIImage(named: "icon-sttaions")
        muteMusicButton.setImage(musicImage, for: .normal)
        muteMusicButton.tintColor = UIColor.white

        pageControl.numberOfPages = 0
    }

    var pages: Int {
        return Int(ceil(self.collectionView.contentSize.width / self.collectionView.frame.size.width))
    }

    var currentPage: Int {
        return Int(ceil(self.collectionView.contentOffset.x / self.collectionView.frame.size.width))
    }


    // MARK: UI Actions

    @IBAction func crossFader(_ sender: Any) {

        let value = crossFader.value

        var musicVolume: Float = 1
        var fxVolume: Float = 1

        if value > 0.5 {
            fxVolume = 1 - ((value - 0.5) * 2)
        }

        if value < 0.5 {
            musicVolume = value * 2
        }

        SwiftEventBus.post(EventIdentifiers.MusicVolumeChanged, userInfo: ["volume": musicVolume])
        EffectView.volume = fxVolume
    }

    @IBAction func muteFXOn(_ sender: Any) {
        SwiftEventBus.post(EventIdentifiers.EffectMuteOn)
    }

    @IBAction func muteFXOff(_ sender: Any) {
        SwiftEventBus.post(EventIdentifiers.EffectMuteOff)
    }

    @IBAction func muteMusicOn(_ sender: Any) {
        SwiftEventBus.post(EventIdentifiers.MusicMuteOn)
    }

    @IBAction func muteMusicOff(_ sender: Any) {
        SwiftEventBus.post(EventIdentifiers.MusicMuteOff)
    }

    // MARK: Private

    private func loadEffects() -> Promise<Void> {

        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false

        return Promise<Void> { resolvers in

            let bundle = Bundle(path: "\(Bundle.main.bundlePath)/Effects.bundle")!
            let plistPath = bundle.path(forResource: "effects", ofType: "plist")!
            let plistData = FileManager.default.contents(atPath: plistPath)!

            do {
                if let mapping = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainers, format: nil) as? [String: Any],
                    var effectList = mapping["effects"] as? [[String: Any]] {
                    effectList = effectList.sorted { ($0["order"] as? Int) ?? 0 < ($1["order"] as? Int) ?? 0 }

                    effectList.forEach({ dict in
                        if var fx = Effect(dict: dict), let effectView = Bundle.main.loadNibNamed("EffectView", owner: nil, options: nil)?.first as? EffectView {
                            fx.file = bundle.path(forResource: fx.file.components(separatedBy: ".").first, ofType: "mp3")!
                            effectView.effect = fx
                            effectView.logger = dependencies.globalLogger
                            var effectArray = effects[fx.type] ?? [EffectView]()
                            effectArray.append(effectView)
                            effects[fx.type] = effectArray
                        }
                    })
                }
            } catch {
                resolvers.reject(error)
            }

            sectionNames = ["SFX", "PAD", "VOC"]
//            effects.keys.enumerated().forEach { _, key in
//                sectionNames.append(key)
//            }

            resolvers.resolve(nil)
        }
    }
}

extension EffectViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return effects.keys.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return effects[sectionNames[section]]?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let effectView = effects[sectionNames[indexPath.section]]![indexPath.row]
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EffectCell", for: indexPath) as! EffectCell
        cell.effectView = effectView
        cell.effectView.titleLabel.text = effectView.effect.title.uppercased()

        switch indexPath.row % 9 {
        case let x where x == 0 || x == 3 || x == 6: cell.backgroundColor = UIColor.rastaGreenPastell
        case let x where x == 1 || x == 4 || x == 7: cell.backgroundColor = UIColor.rastaYellowPastell
        default: cell.backgroundColor = UIColor.rastaRedPastell
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        // if kind == UICollectionElementKindSectionHeader {
            // swiftlint:disable:next force_cast
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EffectHeader", for: indexPath) as! EffectHeader
            header.titleLabel.text = sectionNames[indexPath.section]
            return header
        // }

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

extension EffectViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageControl.currentPage = currentPage
    }
}

extension EffectViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth = UIScreen.main.bounds.width / 3
        return CGSize(width: maxWidth, height: maxWidth)
    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        let spacing = (self.view.frame.size.width - ((70 * 5) + (3 * 8))) / 2.0
//        return UIEdgeInsets(top: 8, left: spacing, bottom: 8, right: spacing)
//    }
}
