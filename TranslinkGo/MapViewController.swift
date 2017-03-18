//
//  MapViewController.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-17.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: AddressSearchBar!
    @IBOutlet weak var tableView: CoverMapTableView!
    
    lazy var locationManager = CLLocationManager()
    var isMapLocCentered: Bool = false
    var lastContentOffsetY: CGFloat = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.edgesForExtendedLayout = []
        
        requestLocation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocation), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopUpdatingLocation), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.contentInset = UIEdgeInsets(top: self.mapView.frame.height, left: 0, bottom: 0, right: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.setContentOffset(CGPoint(x: 0, y:-(self.mapView.frame.height / 2))  , animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    func requestLocation() {
        locationManager.delegate = self
        
        // Request location authorization
        locationManager.requestWhenInUseAuthorization()
        
        // Request a location update
        locationManager.requestLocation()
        // Note: requestLocation may timeout and produce an error if authorization has not yet been granted by the user
    }
    

    
    func updateLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func invalidateMapCenter() {
        isMapLocCentered = false
    }
    
    func updateMapCenter(loc: CLLocation) {
        if isMapLocCentered {
            return
        }
        
        let center = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        mapView.region = MKCoordinateRegion(center: center, span: span)
        isMapLocCentered = true
    }
    
}

extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "translinkLineCell", for: indexPath) as? TranslinkLineCell
        
        return cell!
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location is updated.")
        
        // gets the latest loc
        if let newLoc = locations.last {
            _ = newLoc.coordinate.latitude
            _ = newLoc.coordinate.longitude
            
            updateMapCenter(loc: newLoc)
        }
        
        stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to aquire location.")
    }
}

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Searching \(searchBar.text!)...")
        
        invalidateMapCenter()
        updateLocation()
        
        
    }
}


extension MapViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollView.contentOffset.y is \(scrollView.contentOffset.y)")
        
        // check if tableview covers the whole screen
        if self.tableView.contentInset.top > 0 {
            
            // if smaller than screen, move tableView down if y < 0
            if scrollView.contentOffset.y < 0 && abs(scrollView.contentOffset.y) < self.mapView.frame.height {
                print("will move tableView DOWN...")
                
                // adjust height of mapView
                
                
            } else if scrollView.contentOffset.y > 0 {
                // moves tableView up
                print("will move tableView UP... \(scrollView.contentOffset.y)")

                let diffY = scrollView.contentOffset.y - lastContentOffsetY
                let tableViewFrame = self.tableView.frame
                //self.tableView.frame = CGRect(x: tableViewFrame.origin.x, y: tableViewFrame.origin.y - diffY, width: tableViewFrame.width, height: tableViewFrame.height + diffY)
                
                lastContentOffsetY = scrollView.contentOffset.y
                
                // also need to scroll down the content inside to prevent "double scrolling" effect
                
//                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: false)
//                self.tableView.setContentOffset(CGPoint(x:0, y:0)  , animated: true)
//                self.tableView.contentInset = UIEdgeInsets(top: scrollView.contentOffset.y * 4, left: 0, bottom: 0 , right: 0)
                
            }
        }
        
        
        
        
    }
}
