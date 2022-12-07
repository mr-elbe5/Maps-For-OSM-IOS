/*
 SwiftyMaps
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import Foundation
import UIKit

protocol LocationViewDelegate{
    func updateMarkerLayer()
}

class LocationDetailViewController: PopupScrollViewController{
    
    let editButton = UIButton().asIconButton("pencil.circle", color: .white)
    let deleteButton = UIButton().asIconButton("trash", color: .white)
    
    let descriptionContainerView = UIView()
    var descriptionView : TextEditArea? = nil
    let photoStackView = UIStackView()
    
    var editMode = false
    
    var location: Location? = nil
    var hadPhotos = false
    
    var delegate: LocationViewDelegate? = nil
    
    override func loadView() {
        title = "location".localize()
        super.loadView()
        scrollView.setupVertical()
        setupContent()
        setupKeyboard()
    }
    
    override func setupHeaderView(){
        super.setupHeaderView()
        
        let addPhotoButton = UIButton().asIconButton("photo", color: .white)
        headerView.addSubviewWithAnchors(addPhotoButton, top: headerView.topAnchor, leading: headerView.leadingAnchor, bottom: headerView.bottomAnchor, insets: defaultInsets)
        addPhotoButton.addTarget(self, action: #selector(addPhoto), for: .touchDown)
        
        headerView.addSubviewWithAnchors(editButton, top: headerView.topAnchor, leading: addPhotoButton.trailingAnchor, bottom: headerView.bottomAnchor, insets: wideInsets)
        editButton.addTarget(self, action: #selector(toggleEditMode), for: .touchDown)
        
        headerView.addSubviewWithAnchors(deleteButton, top: headerView.topAnchor, leading: editButton.trailingAnchor, bottom: headerView.bottomAnchor, insets: wideInsets)
        deleteButton.addTarget(self, action: #selector(deleteLocation), for: .touchDown)
    }
    
    func setupContent(){
        if let location = location{
            hadPhotos = location.hasPhotos
            var header = UILabel(header: "locationData".localize())
            contentView.addSubviewWithAnchors(header, top: contentView.topAnchor, leading: contentView.leadingAnchor, insets: defaultInsets)
            
            let locationLabel = UILabel(text: location.address)
            contentView.addSubviewWithAnchors(locationLabel, top: header.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor, insets: defaultInsets)
            
            let coordinateLabel = UILabel(text: location.coordinateString)
            contentView.addSubviewWithAnchors(coordinateLabel, top: locationLabel.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor, insets: flatInsets)
            
            header = UILabel(header: "description".localize())
            contentView.addSubviewWithAnchors(header, top: coordinateLabel.bottomAnchor, leading: contentView.leadingAnchor, insets: defaultInsets)
            contentView.addSubviewWithAnchors(descriptionContainerView, top: header.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor)
            setupDescriptionContainerView()
            
            header = UILabel(header: "photos".localize())
            contentView.addSubviewWithAnchors(header, top: descriptionContainerView.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor, insets: defaultInsets)
            
            photoStackView.setupVertical()
            setupPhotoStackView()
            contentView.addSubviewWithAnchors(photoStackView, top: header.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor, insets: UIEdgeInsets(top: defaultInset, left: defaultInset, bottom: 0, right: defaultInset))
            
            header = UILabel(header: "tracks".localize())
            contentView.addSubviewWithAnchors(header, top: photoStackView.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor, bottom: contentView.bottomAnchor, insets: defaultInsets)
        }
    }
    
    func setupDescriptionContainerView(){
        descriptionContainerView.removeAllSubviews()
        guard let location = location else {return}
        if editMode{
            descriptionView = TextEditArea()
            descriptionView!.text = location.description
            descriptionView?.setGrayRoundedBorders()
            descriptionView?.setDefaults()
            descriptionView?.isScrollEnabled = false
            descriptionView?.setKeyboardToolbar(doneTitle: "done".localize())
            descriptionContainerView.addSubviewWithAnchors(descriptionView!, top: descriptionContainerView.topAnchor, leading: descriptionContainerView.leadingAnchor, trailing: descriptionContainerView.trailingAnchor, insets: defaultInsets)
            
            let saveButton = UIButton()
            saveButton.setTitle("save".localize(), for: .normal)
            saveButton.setTitleColor(.systemBlue, for: .normal)
            saveButton.addTarget(self, action: #selector(save), for: .touchDown)
            descriptionContainerView.addSubviewWithAnchors(saveButton, top: descriptionView!.bottomAnchor, bottom: descriptionContainerView.bottomAnchor, insets: defaultInsets)
                .centerX(descriptionContainerView.centerXAnchor)
        }
        else{
            descriptionView = nil
            let descriptionLabel = UILabel(text: location.description)
            descriptionContainerView.addSubviewWithAnchors(descriptionLabel, top: descriptionContainerView.topAnchor, leading: descriptionContainerView.leadingAnchor, trailing: descriptionContainerView.trailingAnchor, bottom: descriptionContainerView.bottomAnchor, insets: defaultInsets)
        }
    }
    
    func setupPhotoStackView(){
        photoStackView.removeAllArrangedSubviews()
        photoStackView.removeAllSubviews()
        guard let location = location else {return}
        for photo in location.photos{
            let photoView = PhotoListItemView(data: photo)
            photoView.delegate = self
            photoStackView.addArrangedSubview(photoView)
        }
    }
    
    @objc func addPhoto(){
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.mediaTypes = ["public.image"]
        pickerController.sourceType = .photoLibrary
        pickerController.modalPresentationStyle = .fullScreen
        self.present(pickerController, animated: true, completion: nil)
    }
    
    @objc func toggleEditMode(){
        if editMode{
            editButton.tintColor = .white
            editMode = false
        }
        else{
            editButton.tintColor = .systemBlue
            editMode = true
        }
        setupDescriptionContainerView()
        setupPhotoStackView()
    }
    
    @objc func deleteLocation(){
        if let location = location{
            showDestructiveApprove(title: "confirmDeleteLocation".localize(), text: "deleteLocationHint".localize()){
                Locations.deleteLocation(location)
                self.dismiss(animated: true){
                    self.delegate?.updateMarkerLayer()
                }
            }
        }
    }
    
    @objc func save(){
        var needsUpdate = false
        if let location = location{
            location.note = descriptionView?.text ?? ""
            Locations.save()
            needsUpdate = location.hasPhotos != hadPhotos
        }
        self.dismiss(animated: true){
            if needsUpdate{
                self.delegate?.updateMarkerLayer()
            }
        }
    }
    
}

extension LocationDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let imageURL = info[.imageURL] as? URL else {return}
        let photo = PhotoData()
        if FileController.copyFile(fromURL: imageURL, toURL: photo.fileURL){
            location?.addPhoto(photo: photo)
            Locations.save()
            delegate?.updateMarkerLayer()
            let photoView = PhotoListItemView(data: photo)
            photoView.delegate = self
            photoStackView.addArrangedSubview(photoView)
        }
        picker.dismiss(animated: false)
    }
    
}

extension LocationDetailViewController: PhotoListItemDelegate{
    
    func viewPhoto(sender: PhotoListItemView) {
        let photoViewController = PhotoViewController()
        photoViewController.uiImage = sender.photoData.getImage()
        photoViewController.modalPresentationStyle = .fullScreen
        self.present(photoViewController, animated: true)
    }
    
    func sharePhoto(sender: PhotoListItemView) {
        let alertController = UIAlertController(title: title, message: "shareImage".localize(), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "imageLibrary".localize(), style: .default) { action in
            FileController.copyImageToLibrary(name: sender.photoData.fileName, fromDir: FileController.privateURL){ result in
                DispatchQueue.main.async {
                    switch result{
                    case .success:
                        self.showAlert(title: "success".localize(), text: "photoShared".localize())
                    case .failure(let err):
                        self.showAlert(title: "error".localize(), text: err.errorDescription!)
                    }
                }
            }
        })
        alertController.addAction(UIAlertAction(title: "cancel".localize(), style: .cancel))
        self.present(alertController, animated: true)
    }
    
    func deletePhoto(sender: PhotoListItemView) {
        showDestructiveApprove(title: "confirmDeletePhoto".localize(), text: "deletePhotoHint".localize()){
            if let location = self.location{
                location.deletePhoto(photo: sender.photoData)
                Locations.save()
                self.delegate?.updateMarkerLayer()
                for subView in self.photoStackView.subviews{
                    if subView == sender{
                        self.photoStackView.removeArrangedSubview(subView)
                        self.photoStackView.removeSubview(subView)
                        break
                    }
                }
            }
        }
    }
    
}

