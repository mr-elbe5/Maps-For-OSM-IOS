/*
 SwiftyMaps
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import Foundation
import UIKit
import AVKit
import CoreLocation

class TrackPreferences: Identifiable, Codable{
    
    static var storeKey = "tilePreferences"
    
    static var instance = TrackPreferences()
    
    static var defaultMinTrackingDistance : CGFloat = 5 // [m]
    static var defaultMinTrackingInterval : CGFloat = 5 // [sec]
    
    static func loadInstance(){
        if let prefs : TrackPreferences = DataController.shared.load(forKey: TrackPreferences.storeKey){
            instance = prefs
        }
        else{
            instance = TrackPreferences()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case urlTemplate
        case minTrackingDistance
        case minTrackingInterval
    }

    var minTrackingDistance : CGFloat = TrackPreferences.defaultMinTrackingDistance
    var minTrackingInterval : CGFloat = TrackPreferences.defaultMinTrackingInterval
    
    init(){
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        minTrackingDistance = try values.decodeIfPresent(CLLocationDistance.self, forKey: .minTrackingDistance) ?? TrackPreferences.defaultMinTrackingDistance
        minTrackingInterval = try values.decodeIfPresent(CLLocationDistance.self, forKey: .minTrackingInterval) ?? TrackPreferences.defaultMinTrackingInterval
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minTrackingDistance, forKey: .minTrackingDistance)
        try container.encode(minTrackingInterval, forKey: .minTrackingInterval)
    }
    
    func save(){
        DataController.shared.save(forKey: TrackPreferences.storeKey, value: self)
    }
    
    
}
