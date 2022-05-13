//
//  Created by Anton Heestand on 2022-04-24.
//

import SwiftUI

public struct VoxelView: ViewRepresentable {
    
    private let texture: MTLTexture
    private let textureID: UUID
    private let zoom: CGFloat
    private let rotationX: Angle
    private let rotationY: Angle
    
    public init(texture: MTLTexture,
                textureID: UUID,
                zoom: CGFloat = 1.0,
                rotationX: Angle = .zero,
                rotationY: Angle = .zero) {
        self.texture = texture
        self.textureID = textureID
        self.zoom = zoom
        self.rotationX = rotationX
        self.rotationY = rotationY
    }
    
    public func makeView(context: Context) -> MetalView {
        let metalView = MetalView()
        context.coordinator.setup(metalView: metalView)
        metalView.delegate = context.coordinator
        return metalView
    }
    
    public func updateView(_ view: MetalView, context: Context) {
        if context.coordinator.lastTextureID != textureID {
            view.render(texture: texture)
            context.coordinator.lastTextureID = textureID
        }
        context.coordinator.renderer?.cameraDistance = Float(zoom) * Renderer.defaultCameraDistance
        context.coordinator.renderer?.rotationX = Float(rotationX.radians)
        context.coordinator.renderer?.rotationY = Float(rotationY.radians)
        view.render()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

public class Coordinator: MetalViewDelegate {
    
    var renderer: Renderer?
    
    var lastTextureID: UUID?
    
    func setup(metalView: MetalView) {
        renderer = Renderer(view: metalView)
    }
    
    func viewIsReadyToDraw(view: MetalView) {
        renderer?.viewIsReadyToDraw(view: view)
    }
}
