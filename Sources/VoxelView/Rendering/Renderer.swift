//
//  Renderer.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import simd
import MetalKit

typealias SVIndex = UInt32;

struct SVVertex {
    let position:vector_float4
    let color:vector_float4
    let normal:vector_float3
    let highlighted:Bool
    let uv:vector_float2
    let shadow_coord:vector_float3
    let location: (UInt32, UInt32, UInt32)
    
    init(position:vector_float4, normal: vector_float3, uv:vector_float2, color: SIMD4<Float>?, location: (UInt32, UInt32, UInt32)) {
        self.position = position
        self.normal = normal
        self.uv = uv
        self.shadow_coord = vector_float3(0, 0, 0)
        self.highlighted = true
        if(color != nil) {
            self.color = color!
        } else {
            self.color = SIMD4<Float>(0, 0, 0, 0)
        }
        self.location = location
    }
}

struct SVUniforms {
    var modelViewProjectionMatrix:matrix_float4x4
    var shadow_mvp_matrix:matrix_float4x4
    var shadow_mvp_xform_matrix:matrix_float4x4
    let resolution: (UInt32, UInt32, UInt32)
}

class Renderer:MetalViewDelegate {
   
    // children
//    var renderables:[Renderable] = []
    
    // rendering/metal
    var commandQueue:MTLCommandQueue!
    var depthStencilState:MTLDepthStencilState!
    var shadowDepthStencilState:MTLDepthStencilState!
    var shadowMapTexture:MTLTexture!
    var pipeline:MTLRenderPipelineState!
    var metalDevice:MTLDevice!
    var materialPipelines:[Material: MTLRenderPipelineState] = [:]
    
    // threading
    let displaySemaphore:DispatchSemaphore = DispatchSemaphore(value: 2)
    var bufferIndex:NSInteger = 0
    let inFlightBufferCount:NSInteger = 2
    
    // shadows
    var shadowRenderPassDescriptor: MTLRenderPassDescriptor!
    var shadowMvpMatrix:matrix_float4x4!
    var shadowMvpXformMatrix: matrix_float4x4!
    var shadowGenPipelineState:MTLRenderPipelineState!
//    var shadowSamplerState: MTLSamplerState?
    
    // view/state
    let metalView:MetalView!
//    static let defaultCameraDistance:Float = 100.0
    var cameraDefaultDistance: Float {
        Float(texture?.width ?? 1) * 4.0
    }
    var cameraZoom: Float = 1.0
    var cameraDistance: Float = 1.0
    var timePassed:Float = 0
    var rotationY:Float = 0
    var rotationX:Float = 0
    var cameraHeight:Float = 0
    let rotationDampening:Float = 5.0
    var mainCameraProjectionMatrix:matrix_float4x4!
    
    var isPanning: Bool = false
    var panningLastX: Float = 0
    var panningLastY: Float = 0
    var zoomingLastAmount: Float = 0
    
    var modelMatrix: matrix_float4x4!
    
    private var lastDrawableSize: CGSize?
    
    let chunk: Chunk = {
        let block = Block(visible: true, type: .trunk, color: SIMD4<Float>(0.0, 1.0, 0.0, 1.0), location: (0, 0, 0))
        return Chunk(blocks: [block], size: (1, 1, 1))
    }()
    
    lazy var vertexBuffer: MTLBuffer = {
        metalDevice.makeBuffer(bytes: chunk.vertices, length: chunk.vertices.count * MemoryLayout<SVVertex>.stride, options: .cpuCacheModeWriteCombined)!
    }()
    
    lazy var uniformBuffer: MTLBuffer = {
        metalDevice.makeBuffer(length: MemoryLayout<SVUniforms>.stride * 3, options: .cpuCacheModeWriteCombined)!
    }()

    lazy var indexBuffer: MTLBuffer = {
        metalDevice.makeBuffer(bytes: chunk.triangles, length: MemoryLayout<SVIndex>.stride * chunk.triangles.count, options: .cpuCacheModeWriteCombined)!
    }()
    
    // ui/event
    var handlers:[ControllerHandler] = []
    
    var texture: MTLTexture?
    
    /// Initializes a renderer given a MetalView to render to
    ///
    /// - Parameter view: The view the renderer should render to
    init(view: MetalView) {
        self.metalView = view
        self.metalView.delegate = self
        metalDevice = MTLCreateSystemDefaultDevice()!
        
        makePipelines()
        
//        initShadowSampler()
        
//        let chunkRenderable = ChunkRenderable(metalDevice: metalDevice)
//        chunkRenderable.prepare()
//        renderables.append(chunkRenderable)
        
//        let blockRenderable = BlockRenderable(metalDevice: metalDevice)
//        handlers.append(blockRenderable)
//        blockRenderable.prepare()
//        blockRenderable.addTexturesToQueue(commandQueue: commandQueue)
//        renderables.append(blockRenderable)
    }
    
    /// Creats the sampler descriptor for the shadow pass and stores it in a local variable
//    private func initShadowSampler() {
//        let shadowSamplerDesc = MTLSamplerDescriptor()
//        shadowSamplerDesc.sAddressMode = .clampToEdge
//        shadowSamplerDesc.tAddressMode = .clampToEdge
//        shadowSamplerDesc.minFilter = .linear
//        shadowSamplerDesc.magFilter = .linear
//        shadowSamplerDesc.mipFilter = .linear
//        shadowSamplerState = metalDevice.makeSamplerState(descriptor: shadowSamplerDesc)
//    }
    
    private func getPipelineForMaterial(material: Material) -> MTLRenderPipelineState {
        
        if(materialPipelines.keys.contains(material)) {
            return materialPipelines[material]!
        }
        
        var renderablePipeline:MTLRenderPipelineState!
        
        // tie it all together with our pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = material.getVertexFunction()
        pipelineDescriptor.fragmentFunction = material.getFragmentFunction()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            try renderablePipeline = metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch  {
            fatalError("Couldn't create a render state pipeline \(material.name)")
        }
        return renderablePipeline
    }
    
    /// Creates the pipeline state to be used in rendering
    private func makePipelines() {
        // get a new command queue from the device.
        // a command queue keeps a list of command buffers to be executed
        commandQueue = metalDevice.makeCommandQueue()
        
        // create our frag and vert functions from the files in our library
//        let library:MTLLibrary = try! metalDevice.makeDefaultLibrary(bundle: .module)
        
//        let shadowVertexFunction = library.makeFunction(name: "shadow_vertex")

//        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
//        renderPipelineDescriptor.label = "Shadow Gen"
//        renderPipelineDescriptor.vertexDescriptor = nil
//        renderPipelineDescriptor.vertexFunction = shadowVertexFunction
//        renderPipelineDescriptor.fragmentFunction = nil
//        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // Create depth state for shadow pass
//        let shadowDepthStateDescription = MTLDepthStencilDescriptor()
//        shadowDepthStateDescription.label = "Shadow Gen Depth"
//        shadowDepthStateDescription.depthCompareFunction = .lessEqual
//        shadowDepthStateDescription.isDepthWriteEnabled = true
//        shadowDepthStencilState = metalDevice.makeDepthStencilState(descriptor: shadowDepthStateDescription)!
        
        // Create depth texture for shadow pass
//        let shadowTextureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: 1125, height: 1941, mipmapped: false)
//
//        shadowTextureDesc.resourceOptions = .storageModePrivate
//        shadowTextureDesc.usage = [.renderTarget, .shaderRead]
        
//        shadowMapTexture = metalDevice.makeTexture(descriptor: shadowTextureDesc)
//        shadowMapTexture.label = "Shadow Map Texture"
        
        // create our pipmeeline state from our descriptor
//        do {
//            try shadowGenPipelineState = metalDevice.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
//
//        } catch  {
//            print("Error: \(error)")
//        }
        
        // set up our depth stencil
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    /// Creates and returns a pass descriptor for the shadow pass, with the appropriate load action specified
    ///
    /// - Parameter overwrite: Whether to overwrite or load the depth attachment for this pass
    /// - Returns: The pass descriptor
//    func getShadowPassDescriptor(overwrite: Bool) -> MTLRenderPassDescriptor {
//        let shadowRenderPassDescriptor = MTLRenderPassDescriptor()
//        shadowRenderPassDescriptor.depthAttachment.texture = shadowMapTexture
//        shadowRenderPassDescriptor.depthAttachment.loadAction = overwrite ? .clear : .load
//        shadowRenderPassDescriptor.depthAttachment.storeAction = .store
//        shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0
//        return shadowRenderPassDescriptor
//    }
    
    /// Creates the projection matrix for the main camera
    ///
    /// - Parameter size: The size of the texture
    private func createMainCameraProjectionMatrix(size:CGSize) {
        // create our projection matrix
        let aspect = Float(size.width / size.height)
        let fov = Float((2 * Double.pi) / 5)
        let near:Float = 1.0
        let far:Float = cameraDistance * 100.0
        mainCameraProjectionMatrix = MatrixUtilities.matrixPerspective(aspect: aspect, fovy: fov, near: near, far: far)
    }
    
    /// Uses the given model matrix to create an MVP matrix (from the
    /// sun's point of view) of the renderable that the view matrix belongs to
    ///
    /// - Parameter modelMatrix: the model matrix of the renderable the sun is pointing at
    func updateSunMatrices() {
        let directionalLightUpVector:vector_float3 = [0.0, 1.0, 0.0];

        // Update sun direction in view space
        let sunModelPosition:vector_float4 = [2, 2, 2, 0.0]

        let sunWorldDirection:vector_float4 = -sunModelPosition;
        let sunWorldDirectionXYZ:vector_float3 = [sunWorldDirection.x, sunWorldDirection.y, sunWorldDirection.z]
        var shadowViewMatrix:matrix_float4x4 = matrixLookAtRightHand(eye: sunWorldDirectionXYZ,
                                                                     target: vector_float3(0, 0, 0),
                                                                     up: directionalLightUpVector);

        shadowViewMatrix = matrix_multiply(shadowViewMatrix, modelMatrix)

        // TODO: Make this dyanmic based on phone resolution
        let aspectRatio:Float = 3.0 / 4.0

        // this is temporary while we're just spinning around the scene
        // but we need to determine the size of our ortho shadow box
        // such that it fully encompasses our scene from the angle we're viewing at
        let orthoBoxWidth: Float = /*Float(CHUNK_SIZE) * */2

        let shadowProjectionMatrix = matrixOrthoLeftHand(left: -orthoBoxWidth, right: orthoBoxWidth, bottom: -orthoBoxWidth / aspectRatio, top: orthoBoxWidth / aspectRatio, nearZ: -orthoBoxWidth, farZ: orthoBoxWidth);

        // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
        // convert from the [-1, 1] range of clip coordinates to [0, 1] range of
        // used for texture sampling
        let shadowScale = matrixScale(sx: 0.5, sy: -0.5, sz: 1.0);
        let shadowTranslate = matrixTranslation(tx: 0.5, ty: 0.5, tz: 0);
        let shadowTransform = matrix_multiply(shadowTranslate, shadowScale);
        shadowMvpMatrix = matrix_multiply(shadowProjectionMatrix, shadowViewMatrix)
        shadowMvpXformMatrix = matrix_multiply(shadowTransform, shadowMvpMatrix)
    }
    
    // TODO: Remove mainCameraViewProjectionMatrix as a dependency
    /// Renders the shadow pass for each renderable
    ///
    /// - Parameters:
    ///   - mainCameraViewProjectionMatrix: the mvp of the main camera
    ///   - uniformBufferOffset: The offset of the uniform buffer
    ///   - commandBuffer: The command buffer to perform the work on
    fileprivate func renderShadowPasses(mainCameraViewProjectionMatrix: simd_float4x4, uniformBufferOffset: Int, commandBuffer: MTLCommandBuffer) {
        // update and shadow pass

//        for (i, renderable) in renderables.enumerated() {

//        shadowRenderPassDescriptor = getShadowPassDescriptor(overwrite: true)

        updateSunMatrices()

        // calculate our model/view/projection matrix by multiplying the 2 we have
        let modelViewProjectionMatrix:matrix_float4x4 = matrix_multiply(mainCameraViewProjectionMatrix, modelMatrix)

        // create and upload our uniforms
        var uniforms:SVUniforms = SVUniforms(modelViewProjectionMatrix: modelViewProjectionMatrix, shadow_mvp_matrix: shadowMvpMatrix, shadow_mvp_xform_matrix: shadowMvpXformMatrix, resolution: (UInt32(texture?.width ?? 0), UInt32(texture?.height ?? 0), UInt32(texture?.depth ?? 0)));
        let contents = uniformBuffer.contents()
        memcpy(contents + uniformBufferOffset, &uniforms, MemoryLayout.size(ofValue: uniforms))

        // create our command encoder and add our buffers to it
//        let shadowEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescriptor)!
//        shadowEncoder.label = "Shadow Map Encoder"
//        shadowEncoder.setRenderPipelineState(shadowGenPipelineState)
//        shadowEncoder.setDepthStencilState(shadowDepthStencilState)
//        shadowEncoder.setCullMode(.back)
//        shadowEncoder.setDepthBias(0.015, slopeScale: 7, clamp: 0.02)
//        shadowEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        shadowEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, index: 1)
//
//        // draw our geometry
//            shadowEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<SVIndex>.size, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
//
//        // do the encoding
//        shadowEncoder.endEncoding()
//        }
    }
    
    /// Renders the main pass for each renderable
    ///
    /// - Parameters:
    ///   - view: The view we're rendering into
    ///   - commandBuffer: The command buffer to perofrm the work on
    ///   - uniformBufferOffset: The offset of the uniform buffer
    fileprivate func renderMainPasses(view: MetalView, commandBuffer: MTLCommandBuffer, uniformBufferOffset: Int) {
        
//        for (i, renderable) in renderables.enumerated() {
        
        // get a pass descriptor appropriate for this index
        // first index pass descriptors clear our buffer
        // while subsequent ones load data from the previous pass
        let passDescriptor = view.currentRenderPassDescriptor(clearDepth: true)
        
        // create our command encoder and add our buffers and textures to it
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)!
        
        let material = Material(name: "Block", fragmentFunctionName: "fragment_flatcolor", vertexFunctionName: "vertex_project", device: metalDevice)
        let pipeline = getPipelineForMaterial(material: material)
        
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, index: 1)
//        let samplerInfo = MTLSamplerDescriptor()
//        samplerInfo.minFilter = .linear
//        samplerInfo.magFilter = .linear
//        samplerInfo.sAddressMode = .clampToZero
//        samplerInfo.tAddressMode = .clampToZero
//        samplerInfo.rAddressMode = .clampToZero
//        samplerInfo.compareFunction = .never
//        let sampler = metalDevice.makeSamplerState(descriptor: samplerInfo)!
//        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.none)
        
//        if let diffuseTexture = renderable.diffuseTexture {
//            commandEncoder.setFragmentTexture(diffuseTexture, index: 0)
//        }
        
        if let sampler: MTLSamplerState = self.sampler() {
            commandEncoder.setVertexSamplerState(sampler, index: 0)
        }
        
        if let texture: MTLTexture = texture {
            commandEncoder.setVertexTexture(texture, index: 0)
        }

        // add our shadow texture and sampler state
        // TODO: I think we're creating our sampler state in the shader, so we need to remove that part
//        commandEncoder.setFragmentTexture(shadowRenderPassDescriptor.depthAttachment.texture!, index: 1)
//        if let shadowSamplerState = self.shadowSamplerState {
//            commandEncoder.setFragmentSamplerState(shadowSamplerState, index: 1)
//        }
        
        let width: Int = texture?.width ?? 1
        let height: Int = texture?.height ?? 1
        let depth: Int = texture?.depth ?? 1
        
        // draw our geometry
//            commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: renderable.indexBuffer.length / MemoryLayout<SVIndex>.size, indexType: .uint32, indexBuffer: renderable.indexBuffer, indexBufferOffset: 0)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3 * 2 * 6, instanceCount: width * height * depth)
        
        // do the encoding
        commandEncoder.endEncoding()
//        }
    }
    
    /// Loops through renderables and renders the shadow pass and main pass for each. Prepares all necessary camera
    /// data for both passes.
    ///
    /// - Parameters:
    ///   - view: The view we're drawing into.
    ///   - duration: The amount of time passed since the last render
    private func render(view: MetalView) {
        
        let _  = displaySemaphore.wait(timeout: .distantFuture)
        
        let drawableSize: CGSize = view.metalLayer.drawableSize
        if mainCameraProjectionMatrix == nil || drawableSize != lastDrawableSize {
            createMainCameraProjectionMatrix(size: view.metalLayer.drawableSize)
            lastDrawableSize = drawableSize
        }
                
        let directionalCameraUpVector:vector_float3 = [0.0, 1.0, 0.0];
        
        // spin the camera around the center of the scene at a given radius r:
        let directionVector = SIMD3<Float>(0, 0, 1)
        let cameraDirection = quaternionFromEuler(vector_float3(rotationX, rotationY, 0))
        let newPosition = quaternionRotateVector(cameraDirection, directionVector) * cameraDistance
        let mainCameraViewMatrix:matrix_float4x4 = matrixLookAtRightHand(eye: newPosition,
                                                                         target: vector_float3(0, -60, 0),
                                                                         up: directionalCameraUpVector);
        let mainCameraViewProjectionMatrix = matrix_multiply(mainCameraProjectionMatrix, mainCameraViewMatrix)
        
        // do the heavy lifting of creating a command buffer and command encoder
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let uniformBufferOffset:Int = 256 * bufferIndex
        
        // update the renderables models
//        renderables.forEach { (renderable) in
//            renderable.update()
//        }
        let quat = MatrixUtilities.getQuaternionFromAngles(xx: 0, yy: 1, zz: 0, a: 0/*rotationY*/)
        let rotation = MatrixUtilities.getMatrixFromQuat(q: quat)
        // get our model matrix representing our model
        let scale = MatrixUtilities.matrixUniformScale(1)
        modelMatrix = matrix_multiply(scale, rotation)
        
        // draw the shadow and main passes for each renderable
        // these both loop through the renderables
        renderShadowPasses(
            mainCameraViewProjectionMatrix: mainCameraViewProjectionMatrix,
            uniformBufferOffset: uniformBufferOffset,
            commandBuffer: commandBuffer)
        
        renderMainPasses(
            view: view,
            commandBuffer: commandBuffer,
            uniformBufferOffset: uniformBufferOffset)
        
        commandBuffer.present(view.drawable)
        
        // find out when our work is completed to signal the semaphore is free
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.displaySemaphore.signal()
            self.bufferIndex = (self.bufferIndex + 1) % self.inFlightBufferCount
        }
        
        // finalize
        commandBuffer.commit()
    }
    
    /// Delegate method for MetalView, called when the view is ready to be drawn to
    ///
    /// - Parameter view: The metal view that's ready for drawing
    func viewIsReadyToDraw(view: MetalView) {
        // wait until our resources are free
        
        self.render(view: view)
    }
    
    /// Temporary. Moves our box on the screen
    func moveBox() {
        for handler in handlers {
            handler.moveTapped()
        }
    }
    
    func startPan() {
        isPanning = true
    }
    
    func endPan() {
        isPanning = true
        panningLastX = 0
        panningLastY = 0
    }
    
    func endZoom() {
        zoomingLastAmount = 0
    }
    
    func pan(x:Float, y:Float) {
        let thisPanX = (panningLastX - x) / 50.0
        let thisPanY = (panningLastY - y) / 50.0

        panningLastX = x
        panningLastY = y
        
        rotationY += Float(thisPanX) * (Float.pi / rotationDampening);
        rotationX += Float(thisPanY) * (Float.pi / rotationDampening);
        cameraHeight += Float(thisPanY)
    }
    
//    func zoom(amount: Float) {
//        let thisZoomAmount = (zoomingLastAmount - amount) * -50
//
//        zoomingLastAmount = amount
//        cameraZoom += Float(thisZoomAmount)
//    }
    
    
    func sampler() -> MTLSamplerState? {
        let samplerInfo = MTLSamplerDescriptor()
        samplerInfo.minFilter = .linear
        samplerInfo.magFilter = .linear
        samplerInfo.sAddressMode = .clampToZero
        samplerInfo.tAddressMode = .clampToZero
        samplerInfo.rAddressMode = .clampToZero
        samplerInfo.compareFunction = .never
        return metalDevice.makeSamplerState(descriptor: samplerInfo)
    }
}
