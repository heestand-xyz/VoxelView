#if os(macOS)
import AppKit
#else
import UIKit
#endif
import simd

let CHUNK_SIZE = 32
let NUM_SIDES_IN_CUBE = 6

class Chunk: NSObject {
    
    // Configuration
    let gridSpacing:Float = 2.0
    
    var blockSize:Vector3
    
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
    
    let triangleVertPositions:[Block.Direction: [SIMD4<Float>]]
    
    // Geometry
    var triangles:[SVIndex] = []
    var vertices:[SVVertex] = []
    var blocks: [Block]
    var numVerts:UInt32 = 0
    
    /// Initializes a chunk with a given set of blocks
    ///
    /// - Parameter blocks: The blocks that should be chunked
    init(blocks:[Block], size: Vector3) {
        self.blocks = blocks
        self.blockSize = size
        
        triangleVertPositions = [
            .north: [rightBottomBack, leftTopBack, leftBottomBack, rightTopBack, leftTopBack, rightBottomBack],
            .east: [rightTopFront, rightBottomBack, rightBottomFront, rightTopFront, rightTopBack, rightBottomBack],
            .south: [leftBottomFront, leftTopFront, rightBottomFront, rightBottomFront, leftTopFront, rightTopFront],
            .west: [leftTopFront, leftBottomFront, leftBottomBack, leftTopFront, leftBottomBack, leftTopBack],
            .top: [leftTopBack, rightTopFront, leftTopFront, leftTopBack, rightTopBack, rightTopFront],
            .bottom: [leftBottomFront, rightBottomBack, leftBottomBack, leftBottomFront, rightBottomFront, rightBottomBack]
        ]
        
        super.init()
        self.recalculate()
    }
    
    /// Rebuilds the geometry for the given chunk
    func recalculate() {
        for i in 0..<blockSize.x{
            for j in 0..<blockSize.y {
                for k in 0..<blockSize.z {
                    let index = BlockUtilities.get1DIndexFromXYZ(x: i, y: j, z: k, chunkSize: blockSize)
                    let block = blocks[index]
                    
                    if(block.type == .air) {
                        continue;
                    }
                    
                    for direction in Block.Direction.allCases {
                        let offset = faceNormals[direction]!;
                        
                        let newI = i + Int(offset.x);
                        let newJ = j + Int(offset.y);
                        let newK = k + Int(offset.z);
                        
                        let newIndex = BlockUtilities.get1DIndexFromXYZ(x: newI, y: newJ, z: newK, chunkSize: blockSize)
                        
                        // if the neighbor block of this face is outside the bounds
                        // of this chunk, just add the face.
                        // TODO: Add checking of neighboring chunks to further optimize drawing
                        if(newI < 0 || newI >= blockSize.x || newJ < 0 || newJ >= blockSize.y || newK < 0 || newK >= blockSize.z) {
                            addFace(block: block, position: [Float(i), Float(j), Float(k), 0], direction: direction, color: block.color)
                            continue
                        }
                        
//                        let neighborBlock = blocks[newIndex]
                        
//                        if(neighborBlock.type != .air) {
//                            continue;
//                        }
                        
                        addFace(block: block, position: [Float(i), Float(j), Float(k), 0], direction: direction, color: block.color)
                    }
                }
            }
        }
    }
    
    /// Adds a face consisting of two triangles for the given position, direction, and color
    ///
    /// - Parameters:
    ///   - position: The center position of the block who's face we're drawing
    ///   - direction: The direciton of the face we're adding
    ///   - color: The color of the face
    func addFace(block: Block, position:SIMD4<Float>, direction:Block.Direction, color: SIMD4<Float>?) {
        
       let offset = -Float(CHUNK_SIZE) * Float(gridSpacing) / 2.0 + 1
       let offsetArray:SIMD4<Float> = [offset, offset, offset, 0]
        
        for i in 0..<NUM_SIDES_IN_CUBE {
            triangles.append(numVerts + UInt32(i))
        }
        
        numVerts += UInt32(NUM_SIDES_IN_CUBE)
        
        let (topLeftUV, topRightUV, bottomRightUV, bottomLeftUV) = block.getUVCorners(forDirection: direction)
        
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
                uv: uvs[direction]![i],
                color: color,
                location: block.location)
            
            vertices.append(vertex)
        }
    }
}
