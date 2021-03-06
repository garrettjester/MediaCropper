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
    
    
    public var selection: NumberedSelection?
    
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
    
    lazy var button: UIButton = {
        let bttn = UIButton()
        bttn.setTitle("Select", for: .normal)
        bttn.setTitleColor(.selectionBlue, for: .normal)
        bttn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        bttn.addTarget(self, action: #selector(selectionTapped), for: .touchUpInside)
        return bttn
    }()
    
    
    public init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.image = image
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .background
        self.cropView.frame = frameForCropViewWithVerticalLayout()
        self.addToolbar()
        imageView.image = self.image
        self.title = "Edit"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
       // print("Frame of Right Nav Item \(selectionView.frame)")
        
        // Do any additional setup after loading the view.
    }

    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cropView.setBottomImageViewHidden(hidden: true, animated: false)
        
        if self.cropRatio != nil {
            setAspectRatioPreset(ratio: cropRatio, animated: false)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
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
        return
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.cropView.frame = self.frameForCropViewWithVerticalLayout()
        self.adjustCropViewInsets()
        self.cropView.centerCropContent(animated: false)
        
        if self.firstTime {
            self.cropView.performInitialSetup()
            self.firstTime = false
        }
    }
    
    
    
    private func setAspectRatioPreset(ratio: CropRatio, animated: Bool) {
        self.cropRatio = ratio
        self.cropView.setAspectRatio(ratio: ratio.size, animated: animated)
    }
    

    
    private func frameForCropViewWithVerticalLayout() -> CGRect {
        
        let view = self.parent == nil ? self.view : self.parent!.view
        var frame = CGRect.zero
        
        let insets = self.safeInsets
        let bounds = view?.bounds
        
        frame.size = CGSize(width: bounds!.width, height: (bounds!.width * 5)/4)
        frame.origin.y = insets.top
        return frame
    }
    
    
    private func addToolbar() {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)
        separator.topAnchor.constraint(equalTo: cropView.bottomAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return
    }
    
    
    @objc func selectionTapped() {
        
        self.button.setTitle(self.selection?.0 ?? false ? "Deselect" : "Select", for: .normal)
        self.button.setTitleColor(self.selection?.0 ?? false ? .grayText : .selectionBlue, for: .normal)
        
            //if self.selection {
            
        //}
            
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
