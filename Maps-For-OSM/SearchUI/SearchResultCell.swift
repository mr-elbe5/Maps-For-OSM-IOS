/*
 Maps For OSM
 App for display and use of OSM maps without MapKit
 Copyright: Michael Rönnau mr@elbe5.de
 */

import UIKit
import CoreLocation

protocol SearchResultCellDelegate{
    func showResult(location: NominatimLocation)
}

class SearchResultCell: UITableViewCell{
    
    static let CELL_IDENT = "searchResultCell"
    
    var location : NominatimLocation? = nil
    
    var delegate: SearchResultCellDelegate? = nil
    
    var cellBody = UIControl()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        isUserInteractionEnabled = true
        backgroundColor = .clear
        cellBody.setBackground(.white).setRoundedBorders()
        cellBody.addTarget(self, action: #selector(showLocation), for: .touchDown)
        contentView.addSubviewFilling(cellBody, insets: defaultInsets)
        accessoryType = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCell(isEditing: Bool = false){
        cellBody.removeAllSubviews()
        if let location = location{
            let placeLabel = UILabel(text: location.name)
            cellBody.addSubviewWithAnchors(placeLabel, top: cellBody.topAnchor, leading: cellBody.leadingAnchor, trailing: cellBody.trailingAnchor, bottom: cellBody.bottomAnchor, insets: defaultInsets)
        }
    }
    
    @objc func showLocation(){
        if let location = location{
            self.delegate?.showResult(location: location)
        }
    }

}


