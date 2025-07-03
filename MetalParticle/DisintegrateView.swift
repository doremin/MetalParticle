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
    
    // MARK: - Create Particles from CGImage
    private func createParticles(
        from cgImage: CGImage,
        original view: UIView,
        inset: CGFloat,
        maxTiles: Int
    ) -> [Particle] {
        // CGImage를 maxTiles에 맞게 쪼개는 과정
        let scale = UIScreen.main.scale
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        let totalPixels = imageWidth * imageHeight
        let estimatedPixelArea = Float(totalPixels) / Float(maxTiles)
        let tileSize = ceil(sqrt(estimatedPixelArea))
        
        let tilesPerRow = Int(ceil(Float(imageWidth) / tileSize))
        let tilesPerColumn = Int(ceil(Float(imageHeight) / tileSize))
        
        var particles: [Particle] = []
        
        for x in 0 ..< tilesPerRow {
            for y in 0 ..< tilesPerColumn {
                // Metal에서 Texture는 0...1 의 값
                // (0, 0)은 좌하단 (1, 1)은 우상단
                let textureX = Float(x) * tileSize / Float(imageWidth)
                let textureY = Float(y) * tileSize / Float(imageHeight)
                
                // Metal에서 좌표는 -1 ... 1의 값
                // 띠리사 -1 ... 1 의 값으로 normalized 해야함
                let tilePositionX = Float(x) * Float(tileSize) / Float(scale)
                let tilePositionY = Float(y) * Float(tileSize) / Float(scale)
                
                let normalizedX = tilePositionX / Float(imageWidth) * 2 - 1
                let normalizedY = tilePositionY / Float(imageHeight) * 2 - 1
                
                // Particle이 이동할 위치
                // 전체적으로 우상단 방향으로 이동하지만 모두가 이동하지는 않게 적절한 값으로..
                let dx = Float.random(in: 100 ... 900)
                let dy = Float.random(in: -300 ... 100)
                
                let particle = Particle(
                    position: simd_float2(normalizedX, normalizedY),
                    velocity: simd_float2(dx, dy),
                    life: 1.0,
                    maxLife: 1.0,
                    scale: 1.0,
                    textureCoord: simd_float2(textureX, textureY),
                    tileSize: tileSize / Float(scale)
                )
                
                particles.append(particle)
            }
        }
        
        return particles
    }
}
