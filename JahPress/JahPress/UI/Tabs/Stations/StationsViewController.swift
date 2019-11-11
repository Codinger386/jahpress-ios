//
//  StationsViewController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 24.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import SwiftEventBus

class StationsViewController: UIViewController, AppDependencyInjectable {

    var dependencies: AppDependencies!
    var stationList: StationList?
    var stations: [Station] = []
    var imageCache: [String: UIImage] = [:]

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var searchBarShadow: UIView!

    override func viewDidLoad() {
        tableView.backgroundView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor.clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadStations()

        super.viewDidAppear(animated)
        if !JahUserDefaults.disclaimerShown && JahUserDefaults.privacyPolicyAccepted {
            JahUserDefaults.disclaimerShown = true
            self.present(DisclaimerPopup.popUp(), animated: true, completion: nil)
        }

    }

    @IBAction func segmentedControl(_ sender: Any) {
        filterAndSortStations(searchPhrase: searchBar.text)
    }

    private func loadStations() {

        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        dependencies.shoutcastAPI.getReggaeStations().map { stationList in
            self.stationList = stationList
            self.filterAndSortStations(searchPhrase: self.searchBar.text)
        }.catch { error in

            let alert = UIAlertController(title: "Failed to load Stations", message: "Please activate internet connection and try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Try again!", style: .default) { _ in
                self.loadStations()
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)

            self.dependencies.globalLogger.error(error)
        }.finally {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }

    private func loadCover(forIndexPath indexPath: IndexPath) {
        let station = stations[indexPath.row]
        if let logoURLString = station.logo, let logoURL = URL(string: logoURLString) {
            dependencies.shoutcastAPI.getCoverArt(withURL: logoURL).map { [weak self] image -> Void in
                guard self != nil else { return () }
                if let cell = self!.tableView.cellForRow(at: indexPath) as? StationCell {
                    cell.coverImageView.image = image
                }
            }.catch { error in
                self.dependencies.globalLogger.warning("couldn't load cover: \(error)")
            }
        }
    }

    private func loadOnScreenCovers() {
        tableView.indexPathsForVisibleRows?.forEach({ indexPath in
            loadCover(forIndexPath: indexPath)
        })
    }

    private func filterAndSortStations(searchPhrase: String? = nil) {
        guard let stationList = stationList else {
            self.stations = []
            return
        }
        var stations = stationList.stations.sorted { station1, station2 -> Bool in
            if station1.listenerCount != station2.listenerCount {
                return station1.listenerCount > station2.listenerCount
            }
            return station1.name?.lowercased() ?? "" < station2.name?.lowercased() ?? ""
        }
        // var stations = stationList.stations.sorted { $0.lc > $1.lc }
        if let searchPhrase = searchPhrase, searchPhrase.count > 0 {
            stations = stations.filter({ station -> Bool in
                guard let name = station.name else { return false }
                return name.lowercased().contains(searchPhrase.lowercased())
            })
        }
        if self.segmentedControl.selectedSegmentIndex == 1 {
            stations = stations.filter { $0.isFavorite }
        }
        self.stations = stations
        tableView.reloadData()
    }
}

extension StationsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let station = stations[indexPath.row]
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationCell
        cell.station = station
        cell.favoriteButtonHandler = { [weak self] station in
            guard let strongSelf = self, var station = station else { return }
            station.isFavorite = !station.isFavorite
            strongSelf.tableView.reloadRows(at: [indexPath], with: .none)
        }
        cell.backgroundColor = UIColor.clear
        cell.backgroundView = UIView(frame: CGRect.zero)
        cell.selectionStyle = .gray
        cell.titleLabel.text = station.name
        cell.bitrateLabel.text = station.br != nil ? "\(station.br!) kb" : nil
        cell.genreLabel.text = station.displayGenres.joined(separator: " | ")
        cell.listenersLabel.text = station.listenerCount > 0 ? "\(station.listenerCount) listeners" : "currently no listeners"
        cell.coverImageView.image = UIImage(named: "placeholder")
        cell.favoriteButton.setImage(station.isFavorite ? UIImage(named: "icon-isFavorite") : UIImage(named: "icon-isNoFavorite"), for: .normal)

        if !tableView.isDragging && !tableView.isDecelerating {
            loadCover(forIndexPath: indexPath)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tuneIn = stationList?.tuneIn else { return }
        SwiftEventBus.post(EventIdentifiers.StationSelected, userInfo: ["tunein": tuneIn, "station": stations[indexPath.row]])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension StationsViewController: UIScrollViewDelegate {

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadOnScreenCovers()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadOnScreenCovers()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}

extension StationsViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        guard let allStations = stationList?.stations else { return }
        if (searchBar.text == "" || searchBar.text == nil) && allStations.count > stations.count {
            filterAndSortStations()
        }
        searchBar.showsCancelButton = true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (((searchBar.text ?? "") as NSString).replacingCharacters(in: range, with: text) as String).replacingOccurrences(of: "\n", with: "")

        if newText.lowercased() == "unicorn" {
            SwiftEventBus.post(EventIdentifiers.Unicorn, sender: self)
        }

        filterAndSortStations(searchPhrase: (newText.count > 0 ? newText : nil))
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filterAndSortStations()
        searchBar.resignFirstResponder()
    }
}
