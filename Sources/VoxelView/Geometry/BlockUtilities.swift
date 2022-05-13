
class BlockUtilities {
    static func get1DIndexFromXYZ(x: Int, y: Int, z: Int, chunkSize: Vector3) -> Int {
        return x * chunkSize.z * chunkSize.y + y * chunkSize.z + z
    }
}
