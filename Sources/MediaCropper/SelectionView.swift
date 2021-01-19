//
//  File.swift
//  
//
//  Created by Garrett Jester on 1/19/21.
//

import UIKit


class SelectionView: UIView {
    
    var isSelected: Bool? = false
    var position: Int?
    var label: UILabel?
    var selectionIndicator: SelectionIndicator?
    
    init() {
        super.init(frame: CGRect.zero)
        label = UILabel()
        layout()
    }
    
    private func layout() {
        label?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label?.text = "Select"
        label?.textColor = .grayText
        label?.translatesAutoresizingMaskIntoConstraints = false
        
        label?.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        label?.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        label?.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


///---------------------
/// SELECTION INDICATOR
///---------------------
/// A checkbox-style circle that indicates selection.
/// Optionally displays a position label to indicate
/// the selection's index in multiple selection
/// scenario.

class SelectionIndicator: UIView {
    
    var isSelected: Bool? = false
    var positionLabel: UILabel?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        self.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    private func setup() {
        positionLabel = UILabel()
        positionLabel?.font = .systemFont(ofSize: 10, weight: .heavy)
        positionLabel?.textColor = .white
        
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.cgColor
        
        self.addSubview(positionLabel!)
        positionLabel?.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        positionLabel?.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        positionLabel?.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8).isActive = true
        positionLabel?.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.8).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.width / 2
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
