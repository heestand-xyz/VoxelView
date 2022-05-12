import simd

class Block {
    enum BlockType: Int, CaseIterable {
        case grass
        case dirt
        case trunk
        case leaves
        case cloud
        case air
    }
    
    enum Direction: Int, CaseIterable {
        case north
        case east
        case south
        case west
        case top
        case bottom
    }
    
    // Enums
    enum TextureQuadrant {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    var visible: Bool
    var type: BlockType
    var color:SIMD4<Float>
    
    let baryX = simd_float3(x: 1, y: 0, z: 0)
    let baryY = simd_float3(x: 0, y: 1, z: 0)
    let baryZ = simd_float3(x: 0, y: 0, z: 1)
    
    let triangleVertPositions:[Block.Direction: [SIMD4<Float>]]
    
    // Geometry
    var triangles:[SVIndex] = []
    var vertices:[SVVertex] = []
    
    var numVerts:UInt32 = 0
    
    init(visible: Bool, type: BlockType, color: SIMD4<Float>?) {
        self.visible = visible
        self.type = type
        self.color = color != nil ? color! : SIMD4<Float>(0, 0, 0, 0)
        
        triangleVertPositions = [
            .north: [rightBottomBack, leftTopBack, leftBottomBack, rightTopBack, leftTopBack, rightBottomBack],
            .east: [rightTopFront, rightBottomBack, rightBottomFront, rightTopFront, rightTopBack, rightBottomBack],
            .south: [leftBottomFront, leftTopFront, rightBottomFront, rightBottomFront, leftTopFront, rightTopFront],
            .west: [leftTopFront, leftBottomFront, leftBottomBack, leftTopFront, leftBottomBack, leftTopBack],
            .top: [leftTopBack, rightTopFront, leftTopFront, leftTopBack, rightTopBack, rightTopFront],
            .bottom: [leftBottomFront, rightBottomBack, leftBottomBack, leftBottomFront, rightBottomFront, rightBottomBack]
        ]
        
        self.recalculate()
    }
    
    /// Rebuilds the geometry for the given chunk
    func recalculate() {
        if(type == .air) {
            return;
        }
                            
        for direction in Block.Direction.allCases {
            addFace(position: [0, 0, 0, 0], direction: direction, color: nil)
        }
    }
    
    /// Adds a face consisting of two triangles for the given position, direction, and color
    ///
    /// - Parameters:
    ///   - position: The center position of the block who's face we're drawing
    ///   - direction: The direciton of the face we're adding
    ///   - color: The color of the face
    func addFace(position:SIMD4<Float>, direction:Block.Direction, color: SIMD4<Float>?) {
        
        let offset = -Float(CHUNK_SIZE) * Float(gridSpacing) / 2.0 + 1
        let offsetArray:SIMD4<Float> = [offset, offset, offset, 0]
        
        for i in 0..<NUM_SIDES_IN_CUBE {
            triangles.append(numVerts + UInt32(i))
        }
        
        numVerts += UInt32(NUM_SIDES_IN_CUBE)
        
        let (topLeftUV, topRightUV, bottomRightUV, bottomLeftUV) = getUVCorners(forDirection: direction)
        
        let uvs:[Block.Direction: [simd_float2]] = [
            .north: [bottomLeftUV, topRightUV, bottomRightUV, topLeftUV, topRightUV, bottomLeftUV],
            .east: [topLeftUV, bottomRightUV, bottomLeftUV, topLeftUV, topRightUV, bottomRightUV],
            .south: [bottomLeftUV, topLeftUV, bottomRightUV, bottomRightUV, topLeftUV, topRightUV],
            .west: [topRightUV, bottomRightUV, bottomLeftUV, topRightUV, bottomLeftUV, topLeftUV],
            .top: [topLeftUV, bottomRightUV, bottomLeftUV, topLeftUV, topRightUV, bottomRightUV],
            .bottom: [topLeftUV, bottomRightUV, bottomLeftUV, topLeftUV, topRightUV, bottomLeftUV]
        ]
        
        for i in 0..<NUM_SIDES_IN_CUBE {
            let triangleVertPosition = triangleVertPositions[direction]![i]
            let finalPosition = offsetArray + triangleVertPosition + position * gridSpacing
            let vertex = SVVertex(
                position: finalPosition,
                normal: faceNormals[direction]!,
                uv: uvs[direction]![i], color: color)
            
            vertices.append(vertex)
        }
    }
    
    // Configuration
    let gridSpacing:Float = 2.0
    
    // The positions of the verts of each corner of the cube
    let rightTopBack:SIMD4<Float> = [1.0, 1.0, 1.0, 1.0];
    let rightTopFront:SIMD4<Float> = [1.0, 1.0, -1.0, 1.0];
    let rightBottomBack:SIMD4<Float> = [1.0, -1.0, 1.0, 1.0];
    let rightBottomFront:SIMD4<Float> = [1.0, -1.0, -1.0, 1.0];
    let leftTopBack:SIMD4<Float> = [-1.0, 1.0, 1.0, 1.0];
    let leftTopFront:SIMD4<Float> = [-1.0, 1.0, -1.0, 1.0];
    let leftBottomBack:SIMD4<Float> = [-1.0, -1.0, 1.0, 1.0];
    let leftBottomFront:SIMD4<Float> = [-1.0, -1.0, -1.0, 1.0];
    
    // The normal vector of each of the faces of the cube
    let faceNormals:[Block.Direction: vector_float3] = [
        .north: [0, 0, 1],
        .east: [1, 0, 0],
        .south: [0, 0, -1],
        .west: [-1, 0, 0],
        .top: [0, 1, 0],
        .bottom:[0, -1, 0]
    ]

    /// Returns the x/y uv positions of the slot this block's texture resides in
    ///
    /// - Returns: The uv position
    func getUVCorners(forDirection direction: Direction) -> (topLeft: simd_float2, topRight: simd_float2, bottomRight: simd_float2, bottomLeft: simd_float2) {
        // our texture is a square
        // so it is a grid of texture slots where m x m = num types
        let index = self.type.rawValue
        let numSlotsInRow = Int(sqrt(Double(Block.BlockType.allCases.count)))
        let slotWidth:Float = 1.0 / Float(numSlotsInRow)
        let quadrantWidth = Float(slotWidth) / 2.0
        let x = slotWidth * Float(index % numSlotsInRow)
        let y = slotWidth * Float(index / numSlotsInRow) + slotWidth
        let quadrant = getTextureQuadrantForDirection(direction: direction)
        
        var topLeftUV:simd_float2;
        var topRightUV:simd_float2;
        var bottomRightUV:simd_float2;
        var bottomLeftUV:simd_float2;
        
        switch quadrant {
        case .topLeft:
            topLeftUV = [x, y - quadrantWidth * 2];
            topRightUV = [x + quadrantWidth, y - quadrantWidth * 2];
            bottomRightUV = [x + quadrantWidth, y - quadrantWidth];
            bottomLeftUV = [x, y - quadrantWidth];
        case .topRight:
            topLeftUV = [x + quadrantWidth, y - quadrantWidth * 2];
            topRightUV = [x + quadrantWidth * 2, y - quadrantWidth * 2];
            bottomRightUV = [x + quadrantWidth * 2, y - quadrantWidth];
            bottomLeftUV = [x + quadrantWidth, y - quadrantWidth];
        case .bottomLeft, .bottomRight:
            topLeftUV = [x, y - quadrantWidth];
            topRightUV = [x + quadrantWidth, y - quadrantWidth];
            bottomRightUV = [x + quadrantWidth, y];
            bottomLeftUV = [x, y];
        }
        
        let returnVal = (topLeft: topLeftUV, topRight: topRightUV, bottomRight: bottomRightUV, bottomLeft: bottomLeftUV)
        return returnVal
    }
    
    /// Returns which texture quadrant to use for a given face direction
    ///
    /// - Parameter direction: The direction of the face
    /// - Returns: The texture quadrant that the face's texture lives in
    private func getTextureQuadrantForDirection(direction:Direction) -> TextureQuadrant {
        switch direction {
        case .north, .east, .south, .west:
            return .topLeft
        case .top:
            return .topRight
        case .bottom:
            return .bottomLeft
        }
    }
}
