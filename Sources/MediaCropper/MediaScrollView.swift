//
//  File.swift
//  
//
//  Created by Garrett Jester on 1/14/21.
//

import UIKit

typealias TouchBlock = () -> Void

class MediaScrollView: UIScrollView {
    
    var touchesEnded: TouchBlock?
    var touchesBegan: TouchBlock?
    var touchesCancelled: TouchBlock?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchesBegan = touchesBegan else {return}
        touchesBegan()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchesEnded = touchesEnded else {return}
        touchesEnded()
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchesCancelled = touchesCancelled else {return}
        touchesCancelled()
        super.touchesCancelled(touches, with: event)
    }
}
