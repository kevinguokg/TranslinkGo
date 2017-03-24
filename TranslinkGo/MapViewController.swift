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
    
    @IBOutlet weak var backBtn: UIButton!
    
    @IBAction func backBtnTapped(_ sender: Any) {
        backBtn.isHidden = true
        // switch states
        self.mapViewState = .atStopList
        
        // bring up stops tableview
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            self.transitEstimateTableView.transform = CGAffineTransform(translationX: 0, y: self.mapView.frame.height + self.transitEstimateTableView.contentOffset.y)
            self.transitStopTableView.transform = CGAffineTransform.identity
        }, completion: { (success) in
            self.transitEstimateTableView.isHidden = true
            self.transitStopTableView.setContentOffset(CGPoint(x:0, y: self.lastStopTableContentOffsetY)  , animated: true)
        })
        
        getNearByStopInfo()
    }
    
    lazy var locationManager = CLLocationManager()
    var isMapLocCentered: Bool = false
    var lastLineTableContentOffsetY: CGFloat = 0;
    var lastStopTableContentOffsetY: CGFloat = 0
    var currLoc: CLLocation?
    var pinnedLoc: CLLocation?
    
    var stopsList: [TransitStop]?
    var transitLineList: [TransitLine]?
    var transitVehicleList: [TransitVehicle]?
    var mapViewState: MapViewState = .atStopList
    
    let lat = 49.279667
    let long = -123.125316
    
    var expandedTransitStopRows = Set<Int>()
    var expandedTransitLineRows = Set<Int>()
    var expandedTransitLineRowsContentOffsetY: Float = 0
    
    var transitLineRefreshTimer: Timer = Timer()
    
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

        // not working..
//        transitLineRefreshTimer = Timer(fireAt: Date() , interval: 10, target: self, selector: #selector(refreshTransiLineStatus), userInfo: nil, repeats: true)
        
        transitLineRefreshTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(refreshTransiLineStatus), userInfo: nil, repeats: true)
        
//        let userLocationBtn = MKUserTrackingBarButtonItem(mapView: self.mapView)
//        self.navigationItem.rightBarButtonItem = userLocationBtn
        
        let button = UIButton()
        button.setTitle("Back", for: UIControlState.normal)
        self.mapView.addSubview(button)
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
    
    // MARK: Timer Calls
    
    func refreshTransiLineStatus() {
        guard let index = self.expandedTransitStopRows.first else {return}
        if mapViewState == .atTransitLineList {
            guard let busStop = self.stopsList?[index] as? BusStop else { return }
            getNextbusInfo(stopNo: busStop.stopNo)
        }
    }
    
    // MARK: API Calls
    func getNearByStopInfo() {
        if let pinnedLoc = self.pinnedLoc {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // works for simulator
            APIManager.sharedInstance.queryStopsNearLocation(latitude: "\(lat)", longitude: "\(long)", radius: 300, completion: { (response, error) in
            
            // works for device
            //APIManager.sharedInstance.queryStopsNearLocation(latitude: "\(trimDecimal(num: (self.pinnedLoc?.coordinate.latitude)!))", longitude: "\(trimDecimal(num: (self.pinnedLoc?.coordinate.longitude)!))", radius: 300, completion: { (response, error) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
    
    func getNextbusInfo(stopNo: Int?) {
        guard let stopNo = stopNo else { return }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        APIManager.sharedInstance.queryNextBusEstimate(stopNumber: stopNo, numOfServices: 3, minuteMeters: 60, completion: { (response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let err = error {
                print("Error: \(err)")
            } else if let responseData = response {
                self.transitLineList = [TransitLine]()
                let jsonResponse = JSON(responseData)
                
                guard let routesArr = jsonResponse.array else {
                    return
                }
                
                // TODO check state,
                if self.mapViewState == .atTransitLineList {
                }
                
                for transitLineItem in routesArr {
                    let transitLine = TransitLine(routeNo: transitLineItem["RouteNo"].stringValue, routeName: transitLineItem["RouteName"].stringValue, direction: transitLineItem["Direction"].stringValue)
                    
                    if let scheduleArr = transitLineItem["Schedules"].array {
                        transitLine.schedules = [TransitSchedule]()
                        for scheduleItem in scheduleArr {
                            let schedule = TransitSchedule(pattern: scheduleItem["Pattern"].stringValue, destination: scheduleItem["Destination"].stringValue)
                            schedule.expCountDown = scheduleItem["ExpectedCountdown"].intValue
                            // TODO: More fields
                            
                            transitLine.schedules?.append(schedule)
                        }
                    }
                    
                    self.transitLineList?.append(transitLine)
                }
                
                // sort the list
                
                let sortedList = self.transitLineList?.sorted(by: { ($0.schedules?[0].expCountDown)! < ($1.schedules?[0].expCountDown)! })
                self.transitLineList = sortedList
                
                self.expandedTransitLineRowsContentOffsetY = Float(self.transitEstimateTableView.contentOffset.y)
                self.transitEstimateTableView.reloadData()
                self.transitEstimateTableView.setContentOffset(CGPoint(x:0, y: Int(self.expandedTransitLineRowsContentOffsetY)), animated: false)
                
                if self.mapViewState == .atStopList {
                    self.backBtn.isHidden = false
                    
                    // switch states
                    self.mapViewState = .atTransitLineList
                    
                    // bring up tableview
                    
                    self.transitEstimateTableView.isHidden = false
                    UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        self.transitEstimateTableView.transform = CGAffineTransform.identity
                        self.transitStopTableView.transform = CGAffineTransform(translationX: 0, y: self.mapView.frame.height + self.transitStopTableView.contentOffset.y)
                    }, completion: nil)
                }
                
            }
        })
    }
    
    func getBusInfo(stopNo: String?, routeNo: String?) {
        guard let stopNo = stopNo, let routeNo = routeNo else { return }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        APIManager.sharedInstance.queryBusInfo(stopNumber: stopNo, routeNumber: routeNo) { (response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let err = error {
                print("Error: \(err)")
            } else if let responseData = response {
                self.transitVehicleList = [TransitVehicle]()
                let jsonResponse = JSON(responseData)
                
                guard let transitVehicleArr = jsonResponse.array else {
                    return
                }
                
                for transitVehicle in transitVehicleArr {
                    let transitBus = TransitBus(vehicleNo: transitVehicle["VehicleNo"].stringValue, tripId: transitVehicle["TripId"].stringValue, routeNo: transitVehicle["RouteNo"].stringValue)
                    transitBus.destination = transitVehicle["Destination"].stringValue
                    transitBus.direction = transitVehicle["Direction"].stringValue
                    transitBus.pattern = transitVehicle["Pattern"].stringValue
                    transitBus.latitude = transitVehicle["Latitude"].doubleValue
                    transitBus.longitude = transitVehicle["Longitude"].doubleValue
                    
                    self.transitVehicleList?.append(transitBus)
                }
                
                self.addAnnotationsforVehicles()
            }
        }
        
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
        
        var center = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        #endif
        
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        mapView.region = MKCoordinateRegion(center: center, span: span)
        isMapLocCentered = true
        
        //self.mapView.userTrackingMode = .followWithHeading
    }
    
    func clearAllMapAnnotations() {
        self.mapView.removeAnnotations(self.mapView.annotations)
    }
    
    func addAnnotationsForStops() {
        guard let stopsList = self.stopsList else {return}
        clearAllMapAnnotations()
        
        for stop in stopsList  {
            let busStop = stop as! BusStop
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: busStop.latitude , longitude: busStop.longitude)
            annotation.title = "\(busStop.stopNo)"
            annotation.subtitle = busStop.name
    
            // turned off custom annotation
//            let annotation = BusStopLocAnnotation(title: "\(busStop.stopNo)", coordinate: CLLocationCoordinate2D(latitude: busStop.latitude , longitude: busStop.longitude), info: busStop.name)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func addAnnotationsforVehicles() {
        guard let transitVehicleList = self.transitVehicleList else {return}
        clearAllMapAnnotations()
        
        for transitVehicle in transitVehicleList  {
            let bus = transitVehicle as! TransitBus
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: bus.latitude! , longitude: bus.longitude!)
            annotation.title = "\(bus.routeNo)"
            annotation.subtitle = bus.destination
            self.mapView.addAnnotation(annotation)
        }
        
        
    }
    
    
    // MARK: Utils
    
    func trimDecimal(num: CLLocationDegrees) -> Double {
        return Double(round(Double(num) * 1000000)/1000000)
    }
}

// MARK: UITableView Delegates
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
            
            cell?.stopNoLabel.text = "\(busStop.stopNo)"
            cell?.stopLocLabel.text = "\(busStop.onStreet!)/\(busStop.atStreet!)"
            cell?.transitLineLabel.text = busStop.routes! == "" ? "Routes info not available" : busStop.routes!
            cell?.distanceLabel.text = "\(busStop.distance!)m"
            cell?.wheelChairImageLabel.isHidden = busStop.wheelchairAccess! == 0
            // rounded corner for wheelchair
            cell?.wheelChairImageLabel.layer.cornerRadius = (cell?.wheelChairImageLabel.bounds.width)! / 2
            cell?.wheelChairImageLabel.clipsToBounds = true
            cell?.isExpanded = self.expandedTransitStopRows.contains(indexPath.row)
            
            cell?.transitDetailBtn.tag = indexPath.row
            cell?.transitDetailBtn.addTarget(self, action: #selector(transitDetailBtnTapped(sender:)), for: UIControlEvents.touchUpInside)
            
            return cell!
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "transitEstimateCell", for: indexPath) as? TransitEstimateCell
            
            let transitLine = self.transitLineList?[indexPath.row]
            
            if let routeNo = transitLine?.routeNo {
                cell?.transitLineNoLabel.text = Int(routeNo) != nil ? ("\(Int(routeNo)!)") : (routeNo)
            } else {
                cell?.transitLineNoLabel.text = "N/A"
            }
            
            
            if let schedules = transitLine?.schedules {
                cell?.transitDestinationLabel.text = schedules[0].destination
                if let expCountDown = schedules[0].expCountDown {
                    
                    cell?.recentScheduleLabel.isHidden = expCountDown <= 0
                    cell?.recentScheduleUnitLabel.isHidden = expCountDown <= 0
                    cell?.departingStatusLabel.isHidden = expCountDown > 0
                    
                    if expCountDown > 0 {
                        cell?.recentScheduleLabel.text = "\(expCountDown)"
                    } else if expCountDown == 0 {
                        cell?.departingStatusLabel.text = "Arriving Now"
                    } else if expCountDown < 0 {
                        cell?.departingStatusLabel.text = "Departured"
                    }
                }
                
                
            } else {
                cell?.transitDestinationLabel.text = transitLine?.routeName
                cell?.recentScheduleLabel.text = "N/A"
            }
            
            if let index = self.expandedTransitStopRows.first {
                cell?.transitLocationLabel.text = self.stopsList?[index].name
            } else {
                // TODO: look for item iteratively...
                
            }
            
            
            cell?.isExpanded = self.expandedTransitLineRows.contains(indexPath.row)
            
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == transitStopTableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? TranslinkLineCell else { return }
            
            switch cell.isExpanded {
            case true:
                self.expandedTransitStopRows.remove(indexPath.row)
                break
            case false:
                self.expandedTransitStopRows.insert(indexPath.row)
                break
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.transitStopTableView.beginUpdates()
            self.transitStopTableView.endUpdates()
            
        } else {
            guard let cell = tableView.cellForRow(at: indexPath) as? TransitEstimateCell else { return }
            
            switch cell.isExpanded {
            case true:
                self.expandedTransitLineRows.remove(indexPath.row)
                break
            case false:
                self.expandedTransitLineRows.insert(indexPath.row)
                
                // TODO: retrieve bus info and display onto map
                
                guard let index = self.expandedTransitStopRows.first else {return}
                if let stop = self.stopsList?[index] as? BusStop {
                    self.getBusInfo(stopNo:String(stop.stopNo), routeNo: self.transitLineList?[indexPath.row].routeNo)
                }
                
                break
            }
            
            cell.isExpanded = !cell.isExpanded
            
            self.transitEstimateTableView.beginUpdates()
            self.transitEstimateTableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == transitStopTableView {
            guard let cell = tableView.cellForRow(at: indexPath) as? TranslinkLineCell else { return }
            self.expandedTransitStopRows.remove(indexPath.row)
            cell.isExpanded = false
            self.transitStopTableView.beginUpdates()
            self.transitStopTableView.endUpdates()
        } else {
            guard let cell = tableView.cellForRow(at: indexPath) as? TransitEstimateCell else { return }
            self.expandedTransitLineRows.remove(indexPath.row)
            cell.isExpanded = false
            self.transitEstimateTableView.beginUpdates()
            self.transitEstimateTableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == transitStopTableView {
            if self.expandedTransitStopRows.contains(indexPath.row) {
                return 120.0
            } else {
                return 90.0
            }
        } else {
            if self.expandedTransitLineRows.contains(indexPath.row) {
                return 120.0
            } else {
                return 90.0
            }
        }
    }
    
    func transitDetailBtnTapped(sender: UIButton) {
        let row = sender.tag
        if let busStop = self.stopsList?[row] as? BusStop {
            self.getNextbusInfo(stopNo: busStop.stopNo)
            self.lastStopTableContentOffsetY = self.transitStopTableView.contentOffset.y
            
            //if let cell = self.transitStopTableView.cellForRow(at: IndexPath(row: row, section: 0)) as? TranslinkLineCell {
            //   cell.isExpanded = !cell.isExpanded
                
            //    self.transitStopTableView.beginUpdates()
            //    self.transitStopTableView.endUpdates()
            //}
        }
    }
}


// MARK: MKMapView Delegates
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

// MARK: CLLocationManager Delegates
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

// MARK: UISearchBar Delegates
extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Searching \(searchBar.text!)...")
        
        invalidateMapCenter()
        updateLocation()

    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
}


// MARK: ScrollView Delegates
extension MapViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollView.contentOffset.y is \(scrollView.contentOffset.y)")
        if scrollView == self.transitStopTableView {
            lastStopTableContentOffsetY = scrollView.contentOffset.y
        } else {
            lastLineTableContentOffsetY = scrollView.contentOffset.y
        }
        
        // check if tableview covers the whole screen
        if self.transitStopTableView.contentInset.top > 0 {
            
            // if smaller than screen, move tableView down if y < 0
            if scrollView.contentOffset.y < 0 && abs(scrollView.contentOffset.y) < self.mapView.frame.height {
                print("will move tableView DOWN...")
                
                // adjust height of mapView
                
                
            } else if scrollView.contentOffset.y > 0 {
                // moves tableView up
                print("will move tableView UP... \(scrollView.contentOffset.y)")

                let diffY = scrollView.contentOffset.y - lastLineTableContentOffsetY
                let tableViewFrame = self.transitStopTableView.frame
                //self.tableView.frame = CGRect(x: tableViewFrame.origin.x, y: tableViewFrame.origin.y - diffY, width: tableViewFrame.width, height: tableViewFrame.height + diffY)
                
                lastLineTableContentOffsetY = scrollView.contentOffset.y
                
                // also need to scroll down the content inside to prevent "double scrolling" effect
                
//                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: false)
//                self.tableView.setContentOffset(CGPoint(x:0, y:0)  , animated: true)
//                self.tableView.contentInset = UIEdgeInsets(top: scrollView.contentOffset.y * 4, left: 0, bottom: 0 , right: 0)
                
            }
        }
        
        
        
        
    }
}
