/*
 SwiftyMaps
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import Foundation
import UIKit
import UniformTypeIdentifiers
import CoreLocation

protocol PlaceListDelegate: PlaceViewDelegate{
    func showPlaceOnMap(place: Place)
    func deletePlace(place: Place)
    func deleteAllPlaces()
}

class PlaceListViewController: PopupTableViewController{

    private static let CELL_IDENT = "placeCell"
    
    var delegate: PlaceListDelegate? = nil
    
    override func loadView() {
        title = "placeList".localize()
        super.loadView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlaceCell.self, forCellReuseIdentifier: PlaceListViewController.CELL_IDENT)
    }
    
    override func setupHeaderView(){
        super.setupHeaderView()
        let deleteButton = IconButton(icon: "trash", tintColor: .red)
        headerView.addSubview(deleteButton)
        deleteButton.addTarget(self, action: #selector(deleteAllPlaces), for: .touchDown)
        deleteButton.setAnchors(top: headerView.topAnchor, leading: headerView.leadingAnchor, bottom: headerView.bottomAnchor, insets: defaultInsets)
    }
    
    @objc func deleteAllPlaces(){
        showDestructiveApprove(title: "confirmDeletePlaces".localize(), text: "deletePlacesHint".localize()){
            self.delegate?.deleteAllPlaces()
            self.tableView.reloadData()
        }
    }
    
}

extension PlaceListViewController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Places.size
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceListViewController.CELL_IDENT, for: indexPath) as! PlaceCell
        let track = Places.place(at: indexPath.row)
        cell.place = track
        cell.delegate = self
        cell.updateCell(isEditing: tableView.isEditing)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}

extension PlaceListViewController : PlaceCellDelegate{
    
    func showPlaceOnMap(place: Place) {
        self.dismiss(animated: true){
            self.delegate?.showPlaceOnMap(place: place)
        }
    }
    
    func deletePlace(place: Place, approved: Bool) {
        if approved{
            deletePlace(place: place)
        }
        else{
            showDestructiveApprove(title: "confirmDeletePlace".localize(), text: "deletePlaceInfo".localize()){
                self.deletePlace(place: place)
            }
        }
    }
    
    private func deletePlace(place: Place){
        delegate?.deletePlace(place: place)
        self.tableView.reloadData()
    }
    
    func viewPlace(place: Place) {
        let placeController = PlaceDetailViewController()
        placeController.delegate = self
        placeController.place = place
        placeController.modalPresentationStyle = .fullScreen
        self.present(placeController, animated: true)
    }
    
}

extension PlaceListViewController: PlaceViewDelegate{
    
    func updatePlaceLayer() {
        delegate?.updatePlaceLayer()
    }
    
}

