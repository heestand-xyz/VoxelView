import simd

let gridSize:Int = CHUNK_SIZE

class World {

    var blocks:[Block] = []
    var size:Vector3
    
    init(width: Int, height: Int, depth: Int) {
        size = (width, height, depth)
    }
    
    static func getBlock() -> World {
        let world = World(width: 1, height: 1, depth: 2)
        let block = Block(visible: true, type: .grass, color: nil)
        world.blocks.append(block)
        world.blocks.append(block)

        return world
    }
    
    static func getTest() -> World {
        
        let world = World(width: CHUNK_SIZE, height: CHUNK_SIZE, depth: CHUNK_SIZE)
        
        for _ in 0..<CHUNK_SIZE {
            for _ in 0..<CHUNK_SIZE {
                for _ in 0..<CHUNK_SIZE {
                    let block = Block(visible: true, type: .air, color: nil)
                    world.blocks.append(block)
                }
            }
        }
        
        for x in 0..<CHUNK_SIZE {
            for y in 0..<CHUNK_SIZE {
                for z in 0..<CHUNK_SIZE {
                    let index = BlockUtilities.get1DIndexFromXYZ(x: x, y: y, z: CHUNK_SIZE - z, chunkSize: (CHUNK_SIZE, CHUNK_SIZE, CHUNK_SIZE))
                    let block = world.blocks[index]
                    block.color = SIMD4<Float>(Float(x) / Float(CHUNK_SIZE - 1),
                                               Float(y) / Float(CHUNK_SIZE - 1),
                                               Float(z) / Float(CHUNK_SIZE - 1),
                                               1.0)
                    block.type = .trunk
                }
            }
        }
        
        return world
    }
    
//    static func getLandscape() -> World {
//        let world = World(width: gridSize, height: gridSize, depth: gridSize)
//        for _ in 0..<gridSize {
//            for _ in 0..<gridSize {
//                for _ in 0..<gridSize {
//                    let block = Block(visible: true, type: .air, color: nil)
//                    world.blocks.append(block)
//                }
//            }
//        }
//        
//        for i in 0..<gridSize {
//            for k in 0..<gridSize {
//                let index = BlockUtilities.get1DIndexFromXYZ(x: i, y: 0, z: k, chunkSize: (CHUNK_SIZE, CHUNK_SIZE, CHUNK_SIZE))
//                let block = world.blocks[index]
//                block.type = .grass
//            }
//        }
//        
//        let numTrees = 100
//        for _ in 0..<numTrees {
//            let rangeMin = 5
//            let rangeMax = world.size.x - 5
//            let randomX = Int.random(in: rangeMin..<rangeMax)
//            let randomY = Int.random(in: rangeMin..<rangeMax)
//            let randomHeight = Int.random(in: 4..<20)
//            
//            world.addTreeAtLocation(x: randomX, z: randomY, height: randomHeight)
//        }
//        
//        return world
//     }
//    
//    func addTreeAtLocation(x:Int, z:Int, height:Int) {
//        let width = Int(height / 2)
//        for j in 0..<height {
//            let index = BlockUtilities.get1DIndexFromXYZ(x: x, y: j, z: z, chunkSize: (gridSize, gridSize, gridSize))
//            let block = blocks[index]
//            block.type = .trunk
//        }
//        
//        let radius = max(width / 2, 1)
//        
//        for i in x-radius..<x+radius+1 {
//            for j in height..<height+width {
//                for k in z-radius..<z+radius+1 {
//                    let index = BlockUtilities.get1DIndexFromXYZ(x: i, y: j, z: k, chunkSize: (gridSize, gridSize, gridSize))
//                    let block = blocks[index]
//                    block.type = .leaves
//                    block.visible = true
//                }
//            }
//        }
//    }
}
