//
//  APIManager.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-20.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import Alamofire

class APIManager {
    
    static let sharedInstance = APIManager()
    
    private static let retryCount = 0
    private static let stopInfoEndPoint = "http://api.translink.ca/rttiapi/v1/stops"
    private static let nextBusEstiamteEndPoint = stopInfoEndPoint
    
//    http://api.translink.ca/rttiapi/v1/stops/60980/estimates?apikey=S6G4dnALExHaUQfgPIvG&count=3&timeframe=120
    
    private init() {}
    
    func queryStopsNearLocation(latitude: String, longitude: String, radius: Int, completion: @escaping (Any?, Error?) -> Void) {
        let urlStr = "\(APIManager.stopInfoEndPoint)?apiKey=\(kTranslink_API_KEY)&lat=\(latitude)&long=\(longitude)&radius=\(radius)"
        let escapedUrl = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        requestBy(escapedUrl: escapedUrl, defaultUrl: urlStr, method:.get, retryCount: APIManager.retryCount, completion: completion)
    }
    
    func queryNextBusEstimate(stopNumber: Int, numOfServices: Int, minuteMeters: Int, completion: @escaping (Any?, Error?) -> Void) {
        let urlStr = "\(APIManager.stopInfoEndPoint)/\(stopNumber)/estimates?apiKey=\(kTranslink_API_KEY)&count=\(numOfServices)&timeframe=\(minuteMeters)"
        let escapedUrl = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        requestBy(escapedUrl: escapedUrl, defaultUrl: urlStr, method:.get, retryCount: APIManager.retryCount, completion: completion)
    }
    
    private func requestBy(escapedUrl: String?, defaultUrl: String, method: HTTPMethod, retryCount: Int, completion: @escaping (Any?, Error?) -> Void ) {
        var retryNum = retryCount
        let headers: HTTPHeaders = ["Accept": "application/json"]
        
        #if DEBUG
            print(escapedUrl!)
        #endif

        Alamofire.request(escapedUrl ?? defaultUrl, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { (response) in
                if let err = response.error {
                    completion(nil, err)
                    if retryNum > 0 {
                        retryNum -= 1
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
                            self.requestBy(escapedUrl: escapedUrl, defaultUrl: defaultUrl, method: method, retryCount: retryNum, completion: completion)
                        })
                        
                    } else {
                        // retry too many times
                    }
                } else {
                    print(response.request!)  // original URL request
                    print(response.response!) // HTTP URL response
                    print(response.data! as Any)     // server data
                    print(response.result)   // result of response serialization
                    
                    if let json = response.result.value {
                        print("JSON: \(json)")
                        completion(json, response.error)
                    }
                }
                
        }
    }
}
