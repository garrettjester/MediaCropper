//
//  CropView.swift
//  WRLDS
//
//  Created by Garrett Jester on 1/13/21.
//  Copyright © 2021 WRLDS. All rights reserved.
//
//  Attributions:
//  -------------
//  A simplified, purely Swift adaptation of Tom Oliver's TOCropView.
//

import UIKit

public protocol CropViewDelegate {
    func resetEnabled()
    func resetDisabled()
}

public class CropView: UIView {
    
    ///-----------
    /// Properties
    ///-----------
    // The image displayed by the view. Can only be set through initializer.
    private var image: UIImage!
    
    // Disable translucency for smooth relayout.
    public var simpleRenderMode: Bool = false
    
    // The aspect ratio that the crop box will fit.
    public var aspectRatio: CGSize?
    
    // The view's delegate (receives notifications about reset state).
    public var delegate: CropViewDelegate?
    
    // The frame of the crop box in the crop views coordinate plane.
    private var _cropBoxFrame: CGRect = .zero
    
    private lazy var _imageCropFrame = getImageCropFrame()
    
    private var _croppingViewsHidden: Bool = false
    
    var cropBoxFrame: CGRect {
        get {return self._cropBoxFrame}
        set {setCropBoxFrame(newValue)}
    }
    
    var imageCropFrame: CGRect {
        get {return self._imageCropFrame}
        set {setImageCropFrame(imageCropFrame: newValue)}
    }
    
    private var cropBoxLastEditedSize: CGSize!
    
    private var cropBoxLastEditedZoomScale: CGFloat = 0.0
    
    private var cropBoxLastEditedMinZoomScale: CGFloat = 0.0
    
    // The insets required for any accessory vies provided with the cropper.
    public var cropRegionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    // When the crop box is locked to the current aspect ratio.
    private var aspectRatioLocked: Bool!
    
    // Padding of the crop rectangle.
    public var cropViewPadding: CGFloat = 14.0
    
    // The largest factor by which the user can scale the image by pinching.
    public var maximumZoomScale: CGFloat = 12.0
    
    public var minimumBoxSize: CGFloat = 42.0
    
    // The original frame of the CropBox
    private var cropOriginFrame: CGRect?
    
    // Resets the view when the user stops interaction.
    private var resetTimer: Timer?
    // Indicates whether the user is actively modifying the crop settings.
    private var editing: Bool = false
    
    
    public var initialSetupPerformed = false
    
    // A storable crop frame used to restore crop settings between sessions.
    public var restoreImageCropFrame: CGRect!
    
    public var applyInitialCroppedImageFrame: Bool = false
    
    // When performing manual content layout, disable internal layout.
    private var internalLayoutDisabled: Bool = false
    
    private var disableForegroundMatching: Bool = false
    
    private var originalCropBoxSize: CGSize!
    
    private var originalContentOffset: CGPoint!
    
    private var canBeReset = false
    

    ///-------
    /// VIEWS
    ///-------
    // The scroll view at the base of the view. Controls panning/zooming gestures.
    private var scrollView: MediaScrollView!
    
    // The primary imageView (placed within the scrollView)
    private var bottomImageView: UIImageView!
    
    // Contains the bottom imageView (separates the backgroundImageView's transforms from the scroll view's
    private var bottomContainerView: UIView!
    
    // Contains the topImageView and inherets its size from the crop box.
    private var topContainerView: UIView!
    
    // The imageView the represent the cropped region of the image (placed above the dimming views).
    private var topImageView: UIImageView!
    
    // A gray view (semi-transparent) overlaid on top of the background image.
    private var overlay: UIView!
    
    // A blur view applied to the image when the user is not interacting with it.
    private var blurView: UIVisualEffectView!
    
    private var blurEffect: UIBlurEffect!
    
    
    
    init(image: UIImage) {
        super.init(frame: CGRect.zero)
        self.image = image
        configure()
    }
    
    
    // MARK: -- UI SETUP --
    ///-----------------------
    /// INITIALIZE COMPONENTS
    ///-----------------------
    private func configure() {
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.backgroundColor = .white
        self.aspectRatio = CropRatio.portrait.size
        self.restoreImageCropFrame = .zero
        
        self.scrollView = MediaScrollView(frame: self.bounds)
        self.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.alwaysBounceHorizontal = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.delegate = self
        
        self.addSubview(scrollView)
        
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        self.scrollView.touchesBegan = startEditing
        self.scrollView.touchesEnded = startResetTimer
        
        self.bottomImageView = UIImageView(image: self.image)
        self.bottomImageView.layer.minificationFilter = .trilinear
        
        self.bottomContainerView = UIView(frame: self.bottomImageView.frame)
        self.bottomContainerView.addSubview(self.bottomImageView)
        self.scrollView.addSubview((self.bottomContainerView))
        
        self.overlay = UIView(frame: self.bounds)
        self.overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.overlay.backgroundColor = self.backgroundColor?.withAlphaComponent(0.35)
        self.overlay.isHidden = false
        self.overlay.isUserInteractionEnabled = false
        self.addSubview(self.overlay)
        
        if #available(iOS 10.0, *) {
            self.blurEffect = UIBlurEffect(style: .regular)
        }
        
        self.blurView = UIVisualEffectView(effect: blurEffect)
        self.blurView.frame = self.bounds
        self.blurView.isUserInteractionEnabled = false
        self.blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.blurView)
        
        self.topContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        self.topContainerView.clipsToBounds = true
        self.topContainerView.isUserInteractionEnabled = false
        self.addSubview(self.topContainerView)
        
        self.topImageView = UIImageView(image: image)
        self.topImageView.layer.minificationFilter = .trilinear
        self.topContainerView.addSubview(topImageView)
        
        if #available(iOS 11.0, *) {
            self.topImageView.accessibilityIgnoresInvertColors = true
            self.bottomImageView.accessibilityIgnoresInvertColors = true
        }
    }
    
    ///--------------
    /// LAYOUT VIEWS
    ///--------------
    public func performInitialSetup() {
        print("PERFORMING INITIAL SETUP")
        if self.initialSetupPerformed { return }
        self.initialSetupPerformed = true
        layoutInitialImage()
        
        // Restore crop frame if one is saved:
        if !self.restoreImageCropFrame!.isEmpty {
            self.imageCropFrame = self.restoreImageCropFrame
            self.restoreImageCropFrame = CGRect.zero
        }
        
        self.checkCanReset()
    }
    
    
    ///---------------------
    /// LAYOUT INITIAL IMAGE
    ///---------------------
    private func layoutInitialImage() {
        print("LAYING OUT INITIAL IMAGE")
        let imageSize = self.image.size
        self.scrollView.contentSize = self.image.size
        let bounds = self.contentBounds
        let boundsSize = bounds.size
        
        // Set min. scale value.
        var scale: CGFloat = 0.0
        
        // Calculate the size of the image to fir into the content bounds.
        scale = min(bounds.width/imageSize.width, bounds.height/imageSize.height)
        
        var cropBoxSize = CGSize.zero
        
        // Adjust the minimum scale to fit the image, given the aspect ratio.
        if self.hasAspectRatio {
            let ratioScale = (self.aspectRatio!.width / self.aspectRatio!.height)
            let fullSizeRatio = CGSize(width: boundsSize.height * ratioScale, height: bounds.height)
            let fitScale = min(boundsSize.width/fullSizeRatio.width, boundsSize.height/fullSizeRatio.height)
            
            cropBoxSize = CGSize(width: fullSizeRatio.width * fitScale, height: fullSizeRatio.height * fitScale)
            scale = max(cropBoxSize.width/imageSize.width, cropBoxSize.height/imageSize.height);
        }
        
        // Set the final image size to use for the rest of the CropView's calculations.
        let scaledSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
        
        self.scrollView.minimumZoomScale = scale
        self.scrollView.maximumZoomScale = scale * self.maximumZoomScale
        
        
        // Pin the crop box to the size specified and center it in the screen.
        
        var frame = CGRect.zero
        frame.size = self.hasAspectRatio ? cropBoxSize : scaledSize
        frame.origin.x = floor((bounds.origin.x) + floor((bounds.width - frame.size.width) * 0.5))
        frame.origin.y = floor((bounds.origin.y) + floor((bounds.height - frame.size.height) * 0.5))
        self.cropBoxFrame = frame
        
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        self.scrollView.contentSize = scaledSize
        
        
        if frame.size.width < scaledSize.width - CGFloat.ulpOfOne || frame.size.height < scaledSize.height - CGFloat.ulpOfOne {
            var offset = CGPoint.zero
            offset.x = -floor(bounds.midX - (scaledSize.width * 0.5))
            offset.y = -floor(bounds.midY - (scaledSize.height * 0.5))
            self.scrollView.contentOffset = offset
        }
        
        // Set resetable values.
        self.originalCropBoxSize = self.cropBoxFrame.size
        self.originalContentOffset = self.scrollView.contentOffset
        
        self.checkCanReset()
        self.matchTopToBottom()
        
    }
    
    
    ///-------------------
    /// UPDATE CROP FRAME
    ///-------------------
    private func updateCropFrame(toMatch imageCropFrame: CGRect) {
        print("UPDATING CROP FRAME")
        //Convert the image crop frame's size from image space to the screen space
        let minSize = self.scrollView.minimumZoomScale
        let scaledOffset = CGPoint(x: imageCropFrame.origin.x * minSize, y: imageCropFrame.origin.y * minSize)
        let scaledCropSize = CGSize(width: imageCropFrame.size.width * minSize, height: imageCropFrame.size.height * minSize)
        
        let bounds = self.contentBounds
        let scale = min(bounds.size.width / scaledCropSize.width, bounds.size.height / scaledCropSize.height)
        
        // Zoom into the scroll view to the appropriate size
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale * scale;
        
        let contentSize = self.scrollView.contentSize;
        self.scrollView.contentSize = CGSize(width: floor(contentSize.width), height: floor(contentSize.height));
        
        
        var frame = CGRect(
            x: 0, y: 0,
            width: floor(scaledCropSize.width * scale),
            height: floor(scaledCropSize.height * scale))
        
        // Update the frame of the cropbox.
        let cropBoxFrame = CGRect(
            x: floor(bounds.midX - (frame.size.width * 0.5)),
            y: floor(bounds.midY - (frame.size.height * 0.5)),
            width: floor(scaledCropSize.width * scale),
            height: floor(scaledCropSize.height * scale))
        
        self.cropBoxFrame = cropBoxFrame;
        
        frame.origin.x = ceil((scaledOffset.x * scale) - self.scrollView.contentInset.left);
        frame.origin.y = ceil((scaledOffset.y * scale) - self.scrollView.contentInset.top);
        self.scrollView.contentOffset = frame.origin
    }
    
    
    
    func getImageCropFrame() -> CGRect {
        print("GETTIN CROP FRAME")
        let imageSize = self.imageSize
        let contentSize = self.scrollView.contentSize
        let cropBoxFrame = self.cropBoxFrame
        let contentOffset = self.scrollView.contentOffset
        
        let edgeInsets = self.scrollView.contentInset
        
        let scale = min(imageSize.width / contentSize.width, imageSize.height / contentSize.height)
        
        var frame = CGRect.zero
        
        frame.origin.x = floor((floor(contentOffset.x) + edgeInsets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((floor(contentOffset.y) + edgeInsets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(cropBoxFrame.size.width * scale)
        frame.size.width = min(imageSize.width, frame.size.width)
        
        if floor(cropBoxFrame.size.width) == floor(cropBoxFrame.size.height) {
            frame.size.height = frame.size.width
        } else {
            frame.size.height = ceil(cropBoxFrame.size.height * scale)
            frame.size.height = min(imageSize.height, frame.size.height)
        }
        frame.size.height = min(imageSize.height, frame.size.height)
        return frame
    }
    
    
    
    func setImageCropFrame(imageCropFrame: CGRect) {
        if !self.initialSetupPerformed {
            self.restoreImageCropFrame = imageCropFrame
            return
        }
        self.updateCropFrame(toMatch: imageCropFrame)
    }
    
    
    
    // MARK: -- TIMER MANAGEMENT --
    
    private func startResetTimer() {
        if self.resetTimer != nil { return }
        self.resetTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(timerTriggered), userInfo: nil, repeats: false)
    }
    
    private func cancelResetTimer() {
        self.resetTimer?.invalidate()
        self.resetTimer = nil
    }
    
    
    @objc func timerTriggered() {
        self.setEditing(false, resetCropBox: true, animated: true)
        self.cancelResetTimer()
    }
    
    
    ///------------------
    /// SET EDITING STATE
    ///------------------
    func startEditing() {
        cancelResetTimer()
        setEditing(true, resetCropBox: false, animated: true)
    }


    private func setEditing(_ editing: Bool, resetCropBox: Bool, animated: Bool) {
        if self.editing == editing { return }
       
        self.editing = editing
        
        if resetCropBox {
            self.centerCropContent(animated: animated)
        }
        
        if !animated {
            toggleTranslucencyViewVisible(!editing)
            return
        }
        
        let duration = editing ? 0.05 : 0.35
        let delay = editing ? 0 : 0.35
        
        UIView.animate(
            withDuration: duration,
            delay: delay, options: [],
            animations: { [unowned self] in self.toggleTranslucencyViewVisible(!editing)},
            completion: nil)
    }
    
    
    
    ///--------------------
    /// TOGGLE TRANSLUCENCY
    ///--------------------
    private func toggleTranslucencyViewVisible(_ visible: Bool) {
        self.blurView.alpha = visible ? 1.0 : 0.0
    }
    
    
    ///---------------------
    /// MATCH TOP TO BOTTOM
    ///---------------------
    private func matchTopToBottom() {
        if (self.disableForegroundMatching) {return}
        
        self.topImageView.frame = self.bottomContainerView.superview!.convert(
            self.bottomContainerView.frame, to: self.topContainerView)
    }
    

    ///----------------------------
    /// CENTER CROP CONTENT
    ///----------------------------
    // Recenters the crop content.
    public func centerCropContent(animated: Bool) {
        if self.internalLayoutDisabled { return }
        
        let contentRect = self.contentBounds
        var cropFrame = self.cropBoxFrame
        
        if (cropFrame.size.width < CGFloat.ulpOfOne || cropFrame.size.height < CGFloat.ulpOfOne) {return}
        
        let scale = min(contentRect.width/cropFrame.width, contentRect.height/cropFrame.height)
        let focusPoint = CGPoint(x: cropFrame.midX, y: cropFrame.midY)
        let midPoint = CGPoint(x: contentRect.midX, y: contentRect.midY)
        
        cropFrame.size.width = ceil(cropFrame.size.width * scale)
        cropFrame.size.height = ceil(cropFrame.size.height * scale)
        
        cropFrame.origin.x = contentRect.origin.x + ceil((contentRect.size.width - cropFrame.size.width) * 0.5)
        cropFrame.origin.y = contentRect.origin.y + ceil((contentRect.size.height - cropFrame.size.height) * 0.5)
        
        // This is the point on the scroll content where the focus point wants to be.
        let targetPoint = (
            x: ((focusPoint.x + self.scrollView.contentOffset.x) * scale),
            y: ((focusPoint.y + self.scrollView.contentOffset.y) * scale))
        
        var offsetPoint = CGPoint(
            x: -midPoint.x + targetPoint.x,
            y: -midPoint.y + targetPoint.y)
        
        // Clamp the content so there aren't any breaks in the grid.
        offsetPoint.x = max(-cropFrame.origin.x, offsetPoint.x)
        offsetPoint.y = max(-cropFrame.origin.y, offsetPoint.y)
        
        
        let translationBlock = { [unowned self] in
            self.disableForegroundMatching = true
            if (self.scrollView.zoomScale < self.scrollView.maximumZoomScale - CGFloat.ulpOfOne) {
                offsetPoint.x = min(-cropFrame.maxX + self.scrollView.contentSize.width, offsetPoint.x)
                offsetPoint.y = min(-cropFrame.maxY + self.scrollView.contentSize.height, offsetPoint.y)
                self.scrollView.contentOffset = offsetPoint
                return
            }
            
            self.disableForegroundMatching = false
            self.matchTopToBottom()
            return
        }
        
        // If not animated, call the translation block outright.
        if (!animated) {
            translationBlock()
            return
        }
        
        // Otherwise animate the recentering.
        self.matchTopToBottom()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIView.animate(
                withDuration: 0.5,
                delay: 0.0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: 1.0,
                options: .beginFromCurrentState,
                animations: translationBlock,
                completion: nil)
        }
    }
    
    
    
    ///------------------
    /// SET ASPECT RATIO
    ///------------------
    /// Sets a new aspect ratio for the CropView and
    /// optionally animates the change.
    public func setAspectRatio(ratio: CGSize, animated: Bool = false) {
        
        self.aspectRatio = ratio
        if !self.initialSetupPerformed { return }
        
        if ratio.width < CGFloat.ulpOfOne && ratio.height < CGFloat.ulpOfOne {
            self.aspectRatio = CGSize(width: self.imageSize.width, height: self.imageSize.height)
        }
        
        let boundsFrame = self.contentBounds
        var cropBoxFrame = self.cropBoxFrame
        var offset = self.scrollView.contentOffset
        var isPortrait = false
        
        if ratio.width == 1 && ratio.height == 1 {
            isPortrait = self.image.size.width > self.image.size.height
        } else {
            isPortrait = ratio.width < aspectRatio!.height
        }
        
        var zoomOut = false
        
        if isPortrait {
            
            // The new width of the cropbox, given the aspect ratio.
            let newWidth = floor(cropBoxFrame.size.height * ratio.width/ratio.height)
            
            // The difference between the cropbox frame and the selected aspect ratio.
            var delta = cropBoxFrame.size.width - newWidth
            
            cropBoxFrame.size.width = newWidth
            offset.x += (delta * 0.5)
            
            // Set the origin to 0 to avoid clamping from the crop frame sanitizer.
            if delta < CGFloat.ulpOfOne {
                cropBoxFrame.origin.x = self.contentBounds.origin.x
            }
            
            let boundsWidth = boundsFrame.width
            
            // Zoom the image out if the aspect ratio causes the new width go beyond the content width.
            if newWidth > boundsWidth {
                
                // Scale the height.
                let scale = boundsWidth / newWidth
                let newHeight = cropBoxFrame.size.height * scale
                delta = cropBoxFrame.size.height - newHeight
                cropBoxFrame.size.height = newHeight
                
                // Pin the y position to the middle.
                offset.y += (delta * 0.5)
                
                // Pin the width to the bounds width.
                cropBoxFrame.size.width = boundsWidth
                zoomOut = true
            }
        } else {
            
            let newHeight = floor(cropBoxFrame.size.width * (ratio.height/ratio.width))
            var delta = cropBoxFrame.size.height - newHeight
            cropBoxFrame.size.height = newHeight
            offset.y += (delta * 0.5)
            
            if delta < CGFloat.ulpOfOne {
                cropBoxFrame.origin.y = self.contentBounds.origin.y
            }
            
            let boundsHeight = boundsFrame.height
            
            if newHeight > boundsHeight {
                let scale = boundsHeight / newHeight
                
                let newWidth = cropBoxFrame.size.width * scale
                delta = cropBoxFrame.size.width - newWidth
                cropBoxFrame.size.width = newWidth
                
                // Pin the x position to the middle.
                offset.x += (delta * 0.5)
                
                // Pin the height to the bounds height.
                cropBoxFrame.size.height = bounds.height
                zoomOut = true
            }
        }
        
        self.cropBoxLastEditedSize = cropBoxFrame.size
        
        // Translate coordinate and size changes in block.
        let translationBlock = { [unowned self] in
            self.scrollView.contentOffset = offset
            self.cropBoxFrame = cropBoxFrame
            
            if zoomOut {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
            self.centerCropContent(animated: false)
        }
        if !animated {
            translationBlock()
            return
        }
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.7,
            options: .beginFromCurrentState,
            animations: translationBlock,
            completion: nil)
    }
    
    
    // Given changes in the view's components, determine if there's a resettable state.
    private func checkCanReset() {
        
        var canReset = false
        
        if self.scrollView.zoomScale > self.scrollView.minimumZoomScale + CGFloat.ulpOfOne {
            canReset = true
            
        } else if floor(self.scrollView.contentOffset.x) != floor(self.originalContentOffset.x) ||
                    floor(self.scrollView.contentOffset.y) != floor(self.originalContentOffset.y) {
            canReset = true
        }
        self.canBeReset = canReset
    }
    

    ///--------------------
    /// HIDE CROPPING VIEWS
    ///--------------------
    private func setCroppingViewsHidden(hidden: Bool, animated: Bool = false) {
        
        if _croppingViewsHidden == hidden {return}
        _croppingViewsHidden = hidden
        
        let alpha: CGFloat = hidden ? 0.0 : 1.0
        
        if !animated {
            self.bottomImageView.alpha = alpha
            self.topContainerView.alpha = alpha
            self.toggleTranslucencyViewVisible(!hidden)
            return
        }
        
        self.topContainerView.alpha = alpha
        self.bottomImageView.alpha = alpha
        
        UIView.animate(withDuration: 0.4) {
            self.toggleTranslucencyViewVisible(!hidden)
        }
    }
    
    

    public func setBottomImageViewHidden(hidden: Bool, animated: Bool) {
        
        if !animated {
            self.bottomImageView.isHidden = true
            return
        }
        
        let beforeAlpha: CGFloat = hidden ? 1.0 : 0.0
        let toAlpha: CGFloat = hidden ? 0.0 : 1.0
        
        self.bottomImageView.isHidden = false
        self.bottomImageView.alpha = beforeAlpha
        
        UIView.animate(withDuration: 0.5) {
            self.bottomImageView.alpha = toAlpha
        } completion: { (_) in
            if hidden {
                self.bottomImageView.isHidden = true
            }
        }
    }

    
    private func setCropBoxFrame(_ cropBoxFrame: CGRect) {
        
        if cropBoxFrame.equalTo(_cropBoxFrame) {return}
        
        var cropBoxFrame = cropBoxFrame
        
        let frameSize = cropBoxFrame.size
        if frameSize.width < CGFloat.ulpOfOne || frame.height < CGFloat.ulpOfOne {return}
        if frameSize.width.isNaN || frameSize.height.isNaN {return}
        
        let contentFrame = self.contentBounds
        let xOrigin = ceil(contentFrame.origin.x)
        let xDelta = cropBoxFrame.origin.x - xOrigin
        cropBoxFrame.origin.x = floor(max(cropBoxFrame.origin.x, xOrigin))
        
        if (xDelta < -CGFloat.ulpOfOne) {
            cropBoxFrame.size.width += xDelta
        }
        
        let yOrigin = ceil(contentFrame.origin.y)
        let yDelta = cropBoxFrame.origin.y - yOrigin
        cropBoxFrame.origin.y = floor(max(cropBoxFrame.origin.y, yOrigin))
        
        if yDelta < CGFloat.ulpOfOne {
            cropBoxFrame.size.height += yDelta
        }
        
        let maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x
        cropBoxFrame.size.width = floor(min(cropBoxFrame.size.width, maxWidth))
        
        let maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y
        cropBoxFrame.size.height = floor(min(cropBoxFrame.size.height, maxHeight))
        
        cropBoxFrame.size.width  = max(cropBoxFrame.size.width, minimumBoxSize);
        cropBoxFrame.size.height = max(cropBoxFrame.size.height, minimumBoxSize);
        
        _cropBoxFrame = cropBoxFrame
        
        self.topContainerView.frame = _cropBoxFrame
        
        // CIRCULAR ADJUSTMENTS:
        //CGFloat halfWidth = self.foregroundContainerView.frame.size.width * 0.5f;
        //self.foregroundContainerView.layer.cornerRadius = halfWidth;
        
        self.scrollView.contentInset = UIEdgeInsets(
            top: _cropBoxFrame.minY,
            left: _cropBoxFrame.minX,
            bottom: self.bounds.maxY - _cropBoxFrame.maxY,
            right: self.bounds.maxX - _cropBoxFrame.maxX)
        
        let imageSize = self.bottomContainerView.bounds.size
        let scale = max(cropBoxFrame.size.height/imageSize.height, cropBoxFrame.size.width/imageSize.width)
        self.scrollView.minimumZoomScale = scale
        
        var size = self.scrollView.contentSize
        size.width = floor(size.width)
        size.height = floor(size.height)
        self.scrollView.contentSize = size
        
        self.scrollView.zoomScale = self.scrollView.zoomScale
        
        matchTopToBottom()
    }
    
    
    ///-------------
    /// HELPERS
    ///-------------
    var contentBounds: CGRect {
        return CGRect(
            x: self.cropViewPadding + self.cropRegionInsets.left,
            y: self.cropViewPadding + self.cropRegionInsets.top,
            width: self.bounds.width - ((self.cropViewPadding * 2) + self.cropRegionInsets.left + self.cropRegionInsets.right),
            height: self.bounds.height - ((self.cropViewPadding * 2) + self.cropRegionInsets.top + self.cropRegionInsets.bottom))
    }
    
    var hasAspectRatio: Bool {
        return self.aspectRatio!.width > CGFloat.ulpOfOne && self.aspectRatio!.height > CGFloat.ulpOfOne
    }
    
    
    var imageSize: CGSize {
        return self.image.size
    }
    
    
    var imageViewFrame: CGRect {
        var frame = CGRect.zero
        frame.origin.x = -self.scrollView.contentOffset.x
        frame.origin.y = -self.scrollView.contentOffset.y
        frame.size = self.scrollView.contentSize
        return frame
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



// MARK: -- SCROLL VIEW DELEGATE --

extension CropView: UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { return self.bottomContainerView }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) { self.matchTopToBottom() }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.startEditing()
        self.canBeReset = true
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.startEditing()
        self.canBeReset = true
    }
    
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.isTracking {
            self.cropBoxLastEditedZoomScale = scrollView.zoomScale
            self.cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
        }
        matchTopToBottom()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.startResetTimer()
        self.checkCanReset()
    }
    
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.startResetTimer()
        self.checkCanReset()
    }
    
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.startResetTimer()
        }
    }
    
}

