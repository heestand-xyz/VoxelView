//import simd
//import MetalKit
//
//class ChunkRenderable: Renderable {
//    
//    // Renderable Protocol
//    var modelMatrix: matrix_float4x4!
//    var renderShadows: Bool = true
//    var samplerState: MTLSamplerState?
//    var vertexBuffer:MTLBuffer!
//    var indexBuffer:MTLBuffer!
//    var uniformBuffer:MTLBuffer!
//    var diffuseTexture:MTLTexture?
//    
//    // material
//    var material:Material
//    
//    // view variables
//    var rotationY:Float = 0
//    let rotationDampening:Float = 10.0
//    
//    // Geometry
//    var world:World!
//    var chunk:Chunk!
//    var metalDevice:MTLDevice
//    
//    /// Initializes a renderer given a MetalView to render to
//    ///
//    /// - Parameter view: The view the renderer should render to
//    init(metalDevice:MTLDevice) {
//        self.metalDevice = metalDevice
//        self.material = Material(name: "Block", fragmentFunctionName: "fragment_flatcolor", vertexFunctionName: "vertex_project", device: metalDevice)
//        world = World.getTest()
//        chunk = Chunk(blocks: world.blocks, size: world.size)
//    }
//    
//    func prepare() {
//        self.makeBuffers()
//    }
//  
//    /// Create our initial vertex, index, and uniform buffers
//    private func makeBuffers() {
//        vertexBuffer = metalDevice.makeBuffer(bytes: chunk.vertices, length: chunk.vertices.count * MemoryLayout<SVVertex>.stride, options: .cpuCacheModeWriteCombined)
//        vertexBuffer.label = "Vertices"
//        
//        indexBuffer = metalDevice.makeBuffer(bytes: chunk.triangles, length: MemoryLayout<SVIndex>.stride * chunk.triangles.count, options: .cpuCacheModeWriteCombined)
//        indexBuffer.label = "Indices"
//        
//        uniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<SVUniforms>.stride * 3, options: .cpuCacheModeWriteCombined)
//        uniformBuffer.label = "Uniforms"
//    }
//    
//    func update() {
//        // uncomment this when you want the chunk to rotate
////         rotationY += Float(timePassed) * (Float.pi / rotationDampening);
//        
//        let quat = MatrixUtilities.getQuaternionFromAngles(xx: 0, yy: 1, zz: 0, a: rotationY)
//        let rotation = MatrixUtilities.getMatrixFromQuat(q: quat)
//        
//        // get our model matrix representing our model
//        let scale = MatrixUtilities.matrixUniformScale(1)
//        modelMatrix = matrix_multiply(scale, rotation)
//    }
//    
//    func draw(timePassed: TimeInterval, viewProjectionMatrix: matrix_float4x4, projectionMatrix:matrix_float4x4, renderPassDescriptor: MTLRenderPassDescriptor, shadowRenderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, commandBuffer: MTLCommandBuffer, pipeline:MTLRenderPipelineState, shadowPipeline: MTLRenderPipelineState, depthStencilState: MTLDepthStencilState, shadowDepthStencilState: MTLDepthStencilState, completion: @escaping ()->()) {
//    }
//    
//    func getMaterial() -> Material {
//        return material
//    }
//}
