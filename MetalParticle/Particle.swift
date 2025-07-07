//
//  Particle.swift
//  MetalParticle
//
//  Created by doremin on 7/2/25.
//

import simd

// MARK: - Particle Structure
struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var life: Float
    var textureCoord: simd_float2
}
