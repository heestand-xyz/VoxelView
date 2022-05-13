//
//  MetalView.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Metal
import MetalKit
import DisplayLink

#if os(macOS)
public typealias _View = NSView
#else
public typealias _View = UIView
#endif

public class MetalView: _View {
    
    var depthTexture: MTLTexture!
    var metalLayer: CAMetalLayer {
        self.layer as! CAMetalLayer
    }
    
    let passDescriptor = MTLRenderPassDescriptor()
    
    var drawable:CAMetalDrawable!
    
    private let displayLink: DisplayLink
    
    weak var delegate: MetalViewDelegate?
    
    #if !os(macOS)
    public override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    #endif
    
    override init(frame: CGRect) {
        
        displayLink = DisplayLink()
        
        super.init(frame: frame)
        
        displayLink.listen(frameLoop: displayLinkDidFire)
        displayLink.start()
        
        #if os(macOS)
        wantsLayer = true
        layer = CAMetalLayer()
        metalLayer.device = MTLCreateSystemDefaultDevice()
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        displayLink = DisplayLink()
        super.init(coder: aDecoder)
    }
    
    func render(texture: MTLTexture) {
        print("------------>")
    }
    
    #if !os(macOS)
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        metalLayer.device = MTLCreateSystemDefaultDevice()
    }
    #endif
    
    public override var frame: CGRect {
        set {
            super.frame = newValue
            #if os(macOS)
            let scale: CGFloat = 2
            #else
            var scale = UIScreen.main.scale
            if let window = self.window {
                scale = window.screen.scale
            }
            #endif
            var drawableSize = self.bounds.size;
            drawableSize.width *= scale;
            drawableSize.height *= scale;
            
            self.metalLayer.drawableSize = drawableSize
            self.initDepthTexture()
        }
        get {
            return super.frame
        }
    }
    
    /// create the depth texture to back this view
    private func initDepthTexture() {
        // we don't need to recreate the texture if it's already there and matches our drawable size
        let drawableSize = self.metalLayer.drawableSize
        
        let drawableWidth = Int(drawableSize.width)
        let drawableHeight = Int(drawableSize.height)
        
        if(depthTexture == nil || depthTexture.width != drawableWidth || depthTexture.height != drawableHeight) {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: drawableWidth, height: drawableHeight, mipmapped: false)
            descriptor.usage = .renderTarget
            descriptor.storageMode = .private
            
            depthTexture = self.metalLayer.device?.makeTexture(descriptor: descriptor)
        }
    }
    
    private func displayLinkDidFire() {
        drawable = metalLayer.nextDrawable()
        delegate?.viewIsReadyToDraw(view: self)
    }
    
    func currentRenderPassDescriptor(clearDepth: Bool)->MTLRenderPassDescriptor {
        
        let colorAttachement = passDescriptor.colorAttachments[0]
        colorAttachement?.texture = self.drawable.texture
        colorAttachement?.clearColor = MTLClearColor(red: 0, green: 0.8, blue: 1, alpha: 1)
        colorAttachement?.storeAction = .store
        colorAttachement?.loadAction = clearDepth ? .clear : .load
        
        let depthAttachment = passDescriptor.depthAttachment
        depthAttachment?.texture = depthTexture
        depthAttachment?.clearDepth = 1.0
        depthAttachment?.loadAction = clearDepth ? .clear : .load
        depthAttachment?.storeAction = .store
        
        return passDescriptor
    }
}
