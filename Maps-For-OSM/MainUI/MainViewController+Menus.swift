/*
 Maps For OSM
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import UIKit
import CoreLocation
import AVFoundation
import Photos
import PhotosUI

extension MainViewController: MainMenuDelegate{
    
    func refreshMap() {
        mapView.refresh()
    }
    
    func openPreloadTiles() {
        let region = mapView.scrollView.tileRegion
        let controller = PreloadViewController()
        controller.mapRegion = region
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func changeTileSource() {
        let controller = TileSourceViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func deleteAllTiles(){
        showDestructiveApprove(title: "confirmDeleteTiles".localize(), text: "deleteTilesHint".localize()){
            TileProvider.shared.deleteAllTiles()
            self.mapView.clearTiles()
        }
    }
    
    func openLocationList() {
        let controller = PlaceListViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func showLocations(_ show: Bool) {
        AppState.shared.showLocations = show
        mapView.placeLayerView.isHidden = !AppState.shared.showLocations
    }
    
    func deleteAllLocations(){
        showDestructiveApprove(title: "confirmDeletePlaces".localize(), text: "deletePlacesHint".localize()){
            PlacePool.deleteAllPlaces()
            PlacePool.save()
            self.placesChanged()
        }
    }
    
    func openPreferences(){
        let controller = PreferencesViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func openTrackList() {
        let controller = TrackListViewController()
        controller.tracks = PlacePool.tracks
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func importTrack(){
        let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "gpx")!])
        filePicker.directoryURL = FileController.exportGpxDirURL
        filePicker.allowsMultipleSelection = false
        filePicker.delegate = self
        filePicker.modalPresentationStyle = .fullScreen
        self.present(filePicker, animated: true)
    }
    
    func hideTrack() {
        TrackItem.visibleTrack = nil
        trackChanged()
    }
    
    func openImageList() {
        let controller = ImageListViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func importImages() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.any(of: [.images, .videos])
        configuration.preferredAssetRepresentationMode = .automatic
        configuration.selection = .ordered
        configuration.selectionLimit = 0
        configuration.disabledCapabilities = [.search, .stagingArea]
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func focusUserLocation() {
        mapView.focusUserLocation()
    }
    
    func openInfo() {
        let controller = MainInfoViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func openSearch() {
        let controller = SearchViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    func createBackup(){
        let fileName = "maps4osm_backup_\(Date().shortFileDate()).zip"
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        view.addSubview(spinner)
        spinner.setAnchors(centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        DispatchQueue.main.async {
            if let _ = Backup.createBackupFile(name: fileName){
                self.showDone(title: "success".localize(), text: "backupSaved".localize())
            }
            spinner.stopAnimating()
            self.view.removeSubview(spinner)
        }
    }
    
    func restoreBackup(){
        showDestructiveApprove(title: "restoreBackup".localize(), text: "restoreBackupHint".localize()){
            let types = UTType.types(tag: "zip", tagClass: UTTagClass.filenameExtension, conformingTo: nil)
            let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPickerController.directoryURL = FileController.backupDirURL
            documentPickerController.delegate = self
            self.present(documentPickerController, animated: true, completion: nil)
        }
    }
    
}

extension MainViewController: PHPickerViewControllerDelegate{
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        for result in results{
            var location: CLLocation? = nil
            if let ident = result.assetIdentifier{
                if let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [ident], options: nil).firstObject{
                    location = fetchResult.location
                }
            }
            let itemProvider = result.itemProvider
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) {  image, error in
                    if let image = image {
                        Log.debug("got image \(image.description) at location \(location?.coordinate ?? CLLocationCoordinate2D())")
                    }
                }
            }
            else{
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, err in
                    if let url = url {
                        Log.debug("got video url: \(url) at location \(location?.coordinate ?? CLLocationCoordinate2D())")
                    }
                }
            }
        }
        picker.dismiss(animated: false)
    }
    
}

extension MainViewController : UIDocumentPickerDelegate{
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first{
            if url.pathExtension == "gpx"{
                importGPXFile(url: url)
            }
            if url.pathExtension == "zip"{
                importBackupFile(url: url)
            }
        }
    }
    
    private func importGPXFile(url: URL){
        if let gpxData = GPXParser.parseFile(url: url), !gpxData.isEmpty{
            let track = TrackItem()
            track.name = gpxData.name
            for segment in gpxData.segments{
                for point in segment.points{
                    track.trackpoints.append(Trackpoint(location: point.location))
                }
            }
            if track.name.isEmpty{
                let ext = url.pathExtension
                var name = url.lastPathComponent
                name = String(name[name.startIndex...name.index(name.endIndex, offsetBy: -ext.count)])
                Log.debug(name)
                track.name = name
            }
            track.evaluateImportedTrackpoints()
            let place = PlacePool.assertPlace(coordinate: track.startCoordinate!)
            place.addItem(item: track)
            PlacePool.save()
            placeChanged(place: place)
        }
    }
    
    private func importBackupFile(url: URL){
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        view.addSubview(spinner)
        spinner.setAnchors(centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        DispatchQueue.main.async {
            if Backup.unzipBackupFile(zipFileURL: url){
                if Backup.restoreBackupFile(){
                    self.showDone(title: "success".localize(), text: "restoreDone".localize())
                    self.mapView.updatePlaceLayer()
                }
            }
            spinner.stopAnimating()
            self.view.removeSubview(spinner)
        }
    }
    
}

extension MainViewController: MapMenuDelegate{
    
    func updateCross() {
        mapView.crossLocationView.isHidden = !AppState.shared.showCross
    }
    
    func zoomIn() {
        if mapView.zoom < World.maxZoom{
            mapView.zoomTo(zoom: mapView.zoom + 1, animated: true)
        }
    }
    
    func zoomOut() {
        if mapView.zoom > World.minZoom{
            mapView.zoomTo(zoom: mapView.zoom - 1, animated: true)
        }
    }
    
}

extension MainViewController: TrackStatusDelegate{
    
    func togglePauseTracking() {
        TrackRecorder.isRecording = !TrackRecorder.isRecording
    }
    
}

