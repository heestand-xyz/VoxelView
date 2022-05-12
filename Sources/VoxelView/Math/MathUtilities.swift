//
//  File.swift
//  
//
//  Created by Anton Heestand on 2022-05-12.
//

import simd

func matrixLookAtRightHand(eye: SIMD3<Float>,
                           target: SIMD3<Float>,
                           up: SIMD3<Float>) -> simd_float4x4 {
    
    let z: SIMD3<Float> = normalize(eye - target)
    let x: SIMD3<Float> = normalize(cross(up, z))
    let y: SIMD3<Float> = cross(z, x)
    let t: SIMD3<Float> = SIMD3<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye))
    
    return simd_float4x4(SIMD4<Float>(x.x, y.x, z.x, 0),
                         SIMD4<Float>(x.y, y.y, z.y, 0),
                         SIMD4<Float>(x.z, y.z, z.z, 0),
                         SIMD4<Float>(t.x, t.y, t.z, 1))
}

func matrixOrthoLeftHand(left: Float,
                         right: Float,
                         bottom: Float,
                         top: Float,
                         nearZ: Float,
                         farZ: Float) -> simd_float4x4 {
    
    simd_float4x4(SIMD4<Float>(2 / (right - left), 0, 0, 0),
                  SIMD4<Float>(0, 2 / (top - bottom), 0, 0),
                  SIMD4<Float>(0, 0, 1 / (farZ - nearZ), 0),
                  SIMD4<Float>((left + right) / (left - right), (top + bottom) / (bottom - top), nearZ / (nearZ - farZ), 1))
}

func matrixScale(sx: Float,
                 sy: Float,
                 sz: Float) -> simd_float4x4 {
    
    simd_float4x4(SIMD4<Float>(sx, 0, 0, 0),
                  SIMD4<Float>(0, sy, 0, 0),
                  SIMD4<Float>(0, 0, sz, 0),
                  SIMD4<Float>(0, 0, 0, 1))
}

func matrixTranslation(tx: Float, ty: Float, tz: Float) -> simd_float4x4 {
    
    simd_float4x4(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(tx, ty, tz, 1))
}

func quaternionFromEuler(_ euler: SIMD3<Float>) -> SIMD4<Float> {
    
    var q: SIMD4<Float> = .zero
    
    let cx: Float = cosf(euler.x / 2.0)
    let cy: Float = cosf(euler.y / 2.0)
    let cz: Float = cosf(euler.z / 2.0)
    let sx: Float = sinf(euler.x / 2.0)
    let sy: Float = sinf(euler.y / 2.0)
    let sz: Float = sinf(euler.z / 2.0)
    
    q.w = cx * cy * cz + sx * sy * sz
    q.x = sx * cy * cz - cx * sy * sz
    q.y = cx * sy * cz + sx * cy * sz
    q.z = cx * cy * sz - sx * sy * cz
    
    return q
}

func quaternionRotateVector(_ q: SIMD4<Float>, _ v: SIMD3<Float>) -> SIMD3<Float> {
    let qp = SIMD3<Float>(q.x, q.y, q.z)
    let w: Float = q.w
    return 2 * dot(qp, v) * qp + ((w * w) - dot(qp, qp)) * v + 2 * w * cross(qp, v)
}
