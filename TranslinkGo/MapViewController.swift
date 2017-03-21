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
import SwiftyJSON

class MapViewController: UIViewController {
    
    enum MapViewState {
        case atStopList
        case atTransitLineList
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: AddressSearchBar!
    @IBOutlet weak var transitStopTableView: CoverMapTableView!
    @IBOutlet weak var transitEstimateTableView: CoverMapTableView!
    
    lazy var locationManager = CLLocationManager()
    var isMapLocCentered: Bool = false
    var lastContentOffsetY: CGFloat = 0;
    var currLoc: CLLocation?
    var pinnedLoc: CLLocation?
    
    var stopsList: [TransitStop]?
    var transitLineList: [TransitLine]?
    var mapViewState: MapViewState = .atStopList
    
    let lat = 49.279667
    let long = -123.125316
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestLocation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocation), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopUpdatingLocation), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        let yTransForm = (self.mapView.frame.height / 2)
        self.transitStopTableView.transform = CGAffineTransform(translationX: 0, y: yTransForm)
        self.transitStopTableView.contentInset = UIEdgeInsets(top: self.mapView.frame.height, left: 0, bottom: 0, right: 0)
        self.transitStopTableView.setContentOffset(CGPoint(x: 0, y:-(self.mapView.frame.height / 2))  , animated: false)
        
        
        self.transitEstimateTableView.transform = CGAffineTransform(translationX: 0, y: yTransForm)
        self.transitEstimateTableView.contentInset = UIEdgeInsets(top: self.mapView.frame.height, left: 0, bottom: 0, right: 0)
        self.transitEstimateTableView.setContentOffset(CGPoint(x: 0, y:-(self.mapView.frame.height / 2))  , animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            self.transitStopTableView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    
    // MARK: API Calls
    func getNearByStopInfo() {
        if let pinnedLoc = self.pinnedLoc {
            APIManager.sharedInstance.queryStopsNearLocation(latitude: "\(lat)", longitude: "\(long)", radius: 500, completion: { (response, error) in
                if let err = error {
                    print("Error: \(err)")
                } else if let responseData = response {
                    self.stopsList = [TransitStop]()
                    let jsonResponse = JSON(responseData)
                    
                    guard let stopArr = jsonResponse.array else {
                        return
                    }
                    
                    for transitStop in stopArr {
                        let stop = BusStop(name: transitStop["Name"].stringValue, stopNo: transitStop["StopNo"].intValue, city: transitStop["City"].stringValue, lat: transitStop["Latitude"].doubleValue, long: transitStop["Longitude"].doubleValue)
                        
                        stop.distance = transitStop["Distance"].intValue
                        stop.atStreet = transitStop["AtStreet"].stringValue
                        stop.onStreet = transitStop["OnStreet"].stringValue
                        stop.routes = transitStop["Routes"].stringValue
                        stop.wheelchairAccess = transitStop["WheelchairAccess"].intValue
                        
                        self.stopsList?.append(stop)
                    }
                    
                    self.transitStopTableView.reloadData()
                    self.addAnnotationsForStops()
                    
                }
            })
        }
        
    }
    
    func getNextbusInfo(stopNo: Int) {
        APIManager.sharedInstance.queryNextBusEstimate(stopNumber: stopNo, numOfServices: 3, minuteMeters: 60, completion: { (response, error) in
            if let err = error {
                print("Error: \(err)")
            } else if let responseData = response {
                self.transitLineList = [TransitLine]()
                let jsonResponse = JSON(responseData)
                
                guard let routesArr = jsonResponse.array else {
                    return
                }
                
                for transitLineItem in routesArr {
                    let transitLine = TransitLine(routeNo: transitLineItem["RouteNo"].stringValue, routeName: transitLineItem["RouteName"].stringValue, direction: transitLineItem["Direction"].stringValue)
                    
                    if let scheduleArr = transitLineItem["Schedules"].array {
                        transitLine.schedules = [TransitSchedule]()
                        for scheduleItem in scheduleArr {
                            let schedule = TransitSchedule(pattern: scheduleItem["Pattern"].stringValue, destination: scheduleItem["Destination"].stringValue)
                            transitLine.schedules?.append(schedule)
                            
                            // TODO: More fields
                        }
                    }
                    
                    self.transitLineList?.append(transitLine)
                    self.transitEstimateTableView.reloadData()
                    
                    // switch states
                    self.mapViewState = .atTransitLineList
                    
                    // bring up tableview
                    
                    self.transitEstimateTableView.isHidden = false
                    UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        self.transitEstimateTableView.transform = CGAffineTransform.identity
                        self.transitStopTableView.transform = CGAffineTransform(translationX: 0, y: self.mapView.frame.height)
                    }, completion: nil)
                }
                
            }
        })
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
        
        //let center = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        mapView.region = MKCoordinateRegion(center: center, span: span)
        isMapLocCentered = true
    }
    
    func addAnnotationsForStops() {
        guard let stopsList = self.stopsList else {return}
        
        for stop in stopsList  {
            let busStop = stop as! BusStop
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = CLLocationCoordinate2D(latitude: busStop.latitude , longitude: busStop.longitude)
//            annotation.title = "\(busStop.stopNo)"
//            annotation.subtitle = busStop.name
            
            let annotation = BusStopLocAnnotation(title: "\(busStop.stopNo)", coordinate: CLLocationCoordinate2D(latitude: busStop.latitude , longitude: busStop.longitude), info: busStop.name)
            self.mapView.addAnnotation(annotation)
        }
    }
}

extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == transitStopTableView {
            return self.stopsList?.count ?? 0
        } else {
            return self.transitLineList?.count ?? 0
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == transitStopTableView {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "translinkLineCell", for: indexPath) as? TranslinkLineCell
            
            let busStop = self.stopsList?[indexPath.row] as! BusStop
            
            cell?.textLabel?.text = busStop.name
            cell?.detailTextLabel?.text = "\(busStop.stopNo)"
            
                return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "transitEstimateCell", for: indexPath) as? TransitEstimateCell
            
            let transitLine = self.transitLineList?[indexPath.row]

            cell?.textLabel?.text = transitLine?.routeNo
            cell?.detailTextLabel?.text = transitLine?.routename
            
            return cell!
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annoId = "LocationAnnotation"
        
        if annotation is BusStopLocAnnotation {
            var annoView = mapView.dequeueReusableAnnotationView(withIdentifier: annoId)
            
            if annoView == nil {
                annoView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annoId)
                annoView?.canShowCallout = true
                annoView?.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
            }
            
            return annoView
        }
        return nil
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("calloutAccessoryControlTapped")
        
        let annotation = view.annotation as! BusStopLocAnnotation
        guard let title = annotation.title else {return}
        
        getNextbusInfo(stopNo: Int(title)!)        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("didSelect MKAnnotationView")
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location is updated.")
        
        // gets the latest loc
        if let newLoc = locations.last {
            self.currLoc = newLoc
            self.pinnedLoc = newLoc
            
            updateMapCenter(loc: newLoc)
            getNearByStopInfo()
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
        if self.transitStopTableView.contentInset.top > 0 {
            
            // if smaller than screen, move tableView down if y < 0
            if scrollView.contentOffset.y < 0 && abs(scrollView.contentOffset.y) < self.mapView.frame.height {
                print("will move tableView DOWN...")
                
                // adjust height of mapView
                
                
            } else if scrollView.contentOffset.y > 0 {
                // moves tableView up
                print("will move tableView UP... \(scrollView.contentOffset.y)")

                let diffY = scrollView.contentOffset.y - lastContentOffsetY
                let tableViewFrame = self.transitStopTableView.frame
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
