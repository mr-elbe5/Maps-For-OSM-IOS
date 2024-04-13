/*
 Maps For OSM
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import UIKit

class PlaceListInfoViewController: PopupScrollViewController {
    
    var stackView = UIStackView()
    
    var subInset : CGFloat = 40
    
    override func loadView() {
        title = "Info"
        super.loadView()
        contentView.addSubviewFilling(stackView, insets: defaultInsets)
        stackView.setupVertical()
        
        stackView.addArrangedSubview(InfoHeader(key: "placeListInfoHeader"))
        
        stackView.addSpacer()
        stackView.addArrangedSubview(InfoHeader(key: "topMenuInfoHeader"))
        stackView.addArrangedSubview(IconInfoText(icon: "pencil", key: "startEditingIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "pencil.slash", key: "endEditingIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "checkmark.square", key: "selectAllIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "trash.square", key: "deleteSelectedPlacesInfoText", iconColor: .red))
        stackView.addSpacer()
        stackView.addArrangedSubview(IconInfoText(icon: "info", key: "infoIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "xmark", key: "closeIconInfoText"))
        
        stackView.addSpacer()
        stackView.addArrangedSubview(InfoHeader(key: "placeCellInfoHeader"))
        stackView.addSpacer()
        stackView.addArrangedSubview(IconInfoText(icon: "magnifyingglass", key: "placeDetailIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "map", key: "showOnMapIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "square", key: "selectIconInfoText"))
        stackView.addArrangedSubview(IconInfoText(icon: "checkmark.square", key: "selectedIconInfoText"))
        
    }
    
}
