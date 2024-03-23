/*
 Maps For OSM
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import UIKit

protocol PlaceLayerDelegate{
    func showPlaceDetails(place: Place)
    func deletePlace(place: Place)
    func showGroupDetails(group: PlaceGroup)
    func mergeGroup(group: PlaceGroup)
}

class PlaceLayerView: UIView {
    
    var delegate: PlaceLayerDelegate? = nil
    
    func setupMarkers(zoom: Int, offset: CGPoint, scale: CGFloat){
        //Log.debug("setupMarkers, zoom=\(zoom),offset=\(offset),scale=\(scale)")
        for subview in subviews {
            subview.removeFromSuperview()
        }
        if zoom == World.maxZoom{
            for place in PlacePool.places{
                let marker = PlaceMarker(place: place)
                marker.addAction(UIAction{ action in
                    self.delegate?.showPlaceDetails(place: marker.place)
                }, for: .touchDown)
                addSubview(marker)
                //marker.menu = getMarkerMenu(marker: marker)
                //marker.showsMenuAsPrimaryAction = true
            }
        }
        else{
            let planetDist = World.zoomScaleToWorld(from: zoom) * 10 // 10m at full zoom
            var groups = Array<PlaceGroup>()
            for place in PlacePool.places{
                var grouped = false
                for group in groups{
                    if group.isWithinRadius(place: place, radius: planetDist){
                        group.addPlace(place: place)
                        group.setCenter()
                        grouped = true
                    }
                }
                if !grouped{
                    let group = PlaceGroup()
                    group.addPlace(place: place)
                    group.setCenter()
                    groups.append(group)
                }
            }
            for group in groups{
                if group.places.count > 1{
                    let marker = PlaceGroupMarker(placeGroup: group)
                    marker.addAction(UIAction{ action in
                        self.delegate?.showGroupDetails(group: group)
                    }, for: .touchDown)
                    addSubview(marker)
                }
                else if let place = group.places.first{
                    let marker = PlaceMarker(place: place)
                    marker.addAction(UIAction{ action in
                        self.delegate?.showPlaceDetails(place: place)
                    }, for: .touchDown)
                    addSubview(marker)
                }
            }
            
        }
        updatePosition(offset: offset, scale: scale)
    }
    
    func getMarker(location: Place) -> Marker?{
        for subview in subviews{
            if let marker = subview as? PlaceMarker, marker.place == location{
                return marker
            }
            if let marker = subview as? PlaceGroupMarker, marker.placeGroup.hasLocation(location: location){
                return marker
            }
        }
        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.contains(where: {
            $0 is Marker && $0.point(inside: self.convert(point, to: $0), with: event)
        })
    }
    
    func updatePosition(offset: CGPoint, scale: CGFloat){
        let offset = MapPoint(x: offset.x/scale, y: offset.y/scale).normalizedPoint.cgPoint
        for subview in subviews{
            if let marker = subview as? PlaceMarker{
                marker.updatePosition(to: CGPoint(x: (marker.place.mapPoint.x - offset.x)*scale , y: (marker.place.mapPoint.y - offset.y)*scale))
            }
            else if let groupMarker = subview as? PlaceGroupMarker, let center = groupMarker.placeGroup.centerPlanetPosition{
                groupMarker.updatePosition(to: CGPoint(x: (center.x - offset.x)*scale , y: (center.y - offset.y)*scale))
            }
        }
    }
    
    func updatePlaceStatus(_ place: Place){
        if let marker = getMarker(location: place){
            marker.updateImage()
        }
    }
    
}



