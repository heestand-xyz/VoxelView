//
//  Created by Anton Heestand on 2022-04-24.
//

import SwiftUI

#if os(macOS)

public struct VoxelView: NSViewRepresentable {
    
    private let texture: MTLTexture
    
    public init(texture: MTLTexture) {
        self.texture = texture
    }
    
    public func makeNSView(context: Context) -> MetalView {
        MetalView()
    }
    
    public func updateNSView(_ view: MetalView, context: Context) {
        view.render(texture: texture)
    }
}

#else

public struct VoxelView: UIViewRepresentable {
    
    private let texture: MTLTexture
    
    public init(texture: MTLTexture) {
        self.texture = texture
    }
    
    public func makeUIView(context: Context) -> MetalView {
        MetalView()
    }
    
    public func updateUIView(_ view: MetalView, context: Context) {
        view.render(texture: texture)
    }
}

#endif
