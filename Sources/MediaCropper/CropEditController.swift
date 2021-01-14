//
//  ViewController.swift
//  WRLDS
//
//  Created by Garrett Jester on 1/12/21.
//  Copyright © 2021 WRLDS. All rights reserved.
//

import UIKit


public class CropEditController: UIViewController {

    // The image to be cropped.
    public var image: UIImage!
    
    // The selected aspect ratio of the crop box
    public var cropRatio: CropRatio!
    
    // The region that is highlighted by the cropbox.
    public var imageCropFrame: CGRect = CGRect.zero
    
    // Indictor for performing initial setup
    private var firstTime: Bool = true
    
    ///--------------
    /// Views
    ///--------------
    
    // Lazy load the crop view (to prevent accessing it
    // before presentation).
    lazy var cropView: CropView = {
        let cv = CropView(image: self.image)
        cv.delegate = self
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(cv)
        if self.cropRatio != nil { cv.aspectRatio = cropRatio.size }
        return cv
    }()
    
    private var statusBarHidden: Bool {
        false
    }
    
    
    // Get the appropriate status bar height, accounting for hardware insets
    // if they exists (for iPhone models >= X)
    public var statusBarHeight: CGFloat {
        var statusBarHeight: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            statusBarHeight = self.view.safeAreaInsets.top
            let hardwareInset = self.view.safeAreaInsets.bottom > CGFloat.ulpOfOne && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone
            if statusBarHidden && !hardwareInset {
                statusBarHeight = 0.0
            }
        } else {
            if statusBarHidden { statusBarHeight = 0.0 }
            else { statusBarHeight = self.topLayoutGuide.length }
        }
        return statusBarHeight
    }
    
    
    public var safeInsets: UIEdgeInsets {
        var insets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
            insets.top = self.statusBarHeight
        } else {
            insets.top = self.statusBarHeight
        }
        return insets
    }
    
    
    public init(with cropRatio: CropRatio, image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.image = image
        self.cropRatio = cropRatio
        
        self.modalTransitionStyle = .coverVertical
        self.modalPresentationStyle = .fullScreen
        
    }
    
    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    
    public init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.image = image
    }
    
    public override func viewDidLoad() {
        print("VIEW DID LOAD")
        super.viewDidLoad()
        self.view.backgroundColor = .white
     
        
        self.cropView.frame = frameForCropView()
        imageView.image = self.image
        // Do any additional setup after loading the view.
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        print("VIEW WILL APPEAR")
        super.viewWillAppear(animated)
        self.cropView.setBottomImageViewHidden(hidden: true, animated: false)
        if self.cropRatio != nil {
            setAspectRatioPreset(ratio: cropRatio, animated: false)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        print("VIEW WILL APPEAR")
        super.viewDidAppear(animated)
        self.cropView.setBottomImageViewHidden(hidden: false, animated: animated)
    }
    
    
    public override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
        } 
        adjustCropViewInsets()
    }
    
    func adjustCropViewInsets() {
        self.cropView.cropRegionInsets = UIEdgeInsets(top: safeInsets.top, left: 0, bottom: 0, right: 0)
        self.cropView.cropRegionInsets = UIEdgeInsets(top: self.statusBarHeight, left: 0, bottom: safeInsets.bottom, right: 0)
        return
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.cropView.frame = self.frameForCropView()
        self.adjustCropViewInsets()
        self.cropView.centerCropContent(animated: false)
        
        if self.firstTime {
            self.cropView.performInitialSetup()
            self.firstTime = false
        }
    
        //UIView.performWithoutAnimation {
            // ANY TOOL BAR ADDITIONS
        //}
    }
    
    
    
    private func setAspectRatioPreset(ratio: CropRatio, animated: Bool) {
        self.cropRatio = ratio
        self.cropView.setAspectRatio(ratio: ratio.size, animated: animated)
    }
    
    
    private func frameForCropView() -> CGRect {
        
        let view = self.parent == nil ? self.view : self.parent!.view
        let bounds = view!.bounds
        var frame = CGRect.zero
        
        frame.size.height = bounds.height
        frame.size.width = bounds.width
        
        // TO-DO: Make adjustments for toolbar here.
        return frame
    }
    
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
}



extension CropEditController: CropViewDelegate {
    public func resetEnabled() { print("RESET IS ENABLED") }
    public func resetDisabled() { print("RESET IS DISABLED") }
}



public enum CropRatio {
    case portrait
    case square
    case landscape
}

public extension CropRatio {
    var size: CGSize {
        switch self {
        case .portrait:
            return CGSize(width: 4.0, height: 5.0)
        case .square:
            return CGSize(width: 1.0, height: 1.0)
        case .landscape:
            return CGSize(width: 1.91, height: 1.0)
        }
    }
}
