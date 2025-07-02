//
//  DisintegrateView.swift
//  MetalParticle
//
//  Created by doremin on 7/2/25.
//

import MetalKit

struct Uniforms {
    var projectionMatrix: simd_float4x4
    var time: Float
    var screenSize: simd_float2
}

class DisintegrateView: MTKView {
    
    private var commandQueue: MTLCommandQueue!
    private var pipelineStae: MTLRenderPipelineState!
    private var uniformBuffer: MTLBuffer!
    
    // MARK: - Initializer
    override init(frame frameRect: CGRect, device: (any MTLDevice)?) {
        super.init(frame: frameRect, device: device)
        
        setupMetal()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup Metal
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        
        self.device = device
        
        guard
            let commandQueue = device.makeCommandQueue(),
            let pipelineState = setupPipelineDescriptor(),
            let uniformBuffer = setupUniformBuffer()
        else {
            return
        }
        
        self.commandQueue = commandQueue
        self.pipelineStae = pipelineState
        self.uniformBuffer = uniformBuffer
        
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        isOpaque = false
        backgroundColor = .clear
    }
    
    private func setupPipelineDescriptor() -> MTLRenderPipelineState? {
        guard let device else { return nil }
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "particleVertexShader")
        let fragmentFunction = library?.makeFunction(name: "particleFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        // Enable blending for transparency
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            
            return pipelineState
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }
    
    private func setupUniformBuffer() -> MTLBuffer? {
        guard let device else { return nil }
        return device.makeBuffer(length: MemoryLayout<Uniforms>.size)
    }
    
    // MARK: - Create Texture From UIView
    private func createTexture(from view: UIView, bounds: CGRect) -> MTLTexture? {
        guard
            let device,
            let cgImage = uiImage(from: view, bounds: bounds).cgImage
        else {
            return nil
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        
        do {
            return try textureLoader.newTexture(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    
    private func uiImage(from view: UIView, bounds: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let snapshotImage = renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
        
        return snapshotImage
    }
}
