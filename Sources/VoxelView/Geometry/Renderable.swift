//
//  Renderable.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/25/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import Foundation
import Metal
import simd

protocol Renderable {
    
    var modelMatrix:simd_float4x4! { get set }
    var renderShadows:Bool { get set }
    var vertexBuffer:MTLBuffer! { get }
    var indexBuffer:MTLBuffer! { get }
    var uniformBuffer:MTLBuffer! { get }
    var diffuseTexture:MTLTexture? { get }
    var samplerState:MTLSamplerState? { get }
    
    /// Returns the material this rendrable should be rendered with
    func getMaterial() -> Material
    
    /// Called once to do initial setup such as buffer creation
    func prepare()
    
    /// Called per frame to allow renderables to update their model matrices
    func update()
}
