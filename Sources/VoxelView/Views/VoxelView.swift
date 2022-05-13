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
        let metalView = MetalView()
        context.coordinator.setup(metalView: metalView)
        metalView.delegate = context.coordinator
        return metalView
    }
    
    public func updateNSView(_ view: MetalView, context: Context) {
        view.render(texture: texture)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

#else

public struct VoxelView: UIViewRepresentable {
    
    private let texture: MTLTexture
    
    public init(texture: MTLTexture) {
        self.texture = texture
    }
    
    public func makeUIView(context: Context) -> MetalView {
        let metalView = MetalView()
        context.coordinator.setup(metalView: metalView)
        metalView.delegate = context.coordinator
        return metalView
    }
    
    public func updateUIView(_ view: MetalView, context: Context) {
        view.render(texture: texture)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

#endif

public class Coordinator: MetalViewDelegate {
    
    var renderer: Renderer?
    
    func setup(metalView: MetalView) {
        renderer = Renderer(view: metalView)
    }
    
    func viewIsReadyToDraw(view: MetalView) {
        renderer?.viewIsReadyToDraw(view: view)
    }
}
