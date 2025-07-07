//
//  DisintegrateView.swift
//  MetalParticle
//
//  Created by doremin on 7/2/25.
//

import MetalKit

class DisintegrateView: MTKView {
    
    // MARK: - Metal Properties
    private var commandQueue: MTLCommandQueue!
    private var pipelineStae: MTLRenderPipelineState!
    private var uniformBuffer: MTLBuffer!
    private var particleBuffer: MTLBuffer!
    private var texture: MTLTexture!
    
    // MARK: - Properties
    private var particles: [Particle] = []
    private var animationStartTime: CFTimeInterval = .zero
    
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
            let pipelineState = setupPipelineDescriptor()
        else {
            return
        }
        
        self.commandQueue = commandQueue
        self.pipelineStae = pipelineState
        
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
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        
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
    
    // MARK: - Create Texture From UIView
    private func createTexture(from image: CGImage, bounds: CGRect) -> MTLTexture? {
        guard
            let device
        else {
            return nil
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        
        do {
            return try textureLoader.newTexture(cgImage: image)
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
        guard let window = view.window else { return [] }
        let windowWidth = window.bounds.width
        let windowHeight = window.bounds.height
        
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
        
        let globalPosition = view.convert(view.bounds.origin, to: nil)
        let offsetX = globalPosition.x + inset
        let offsetY = globalPosition.y + inset
        
        for x in 0 ..< tilesPerRow {
            for y in 0 ..< tilesPerColumn {
                // Metal에서 Texture는 0...1 의 값
                let textureX = Float(x) * tileSize / Float(imageWidth)
                let textureY = Float(y) * tileSize / Float(imageHeight)
                
                // 화면상의 실제 window 기준 좌표
                let screenX = CGFloat(x) * CGFloat(tileSize) / scale + offsetX
                let screenY = CGFloat(y) * CGFloat(tileSize) / scale + offsetY
                
                // Metal clip space로 정규화
                // Metal은 Y축이 위 -> 아래로 1 → -1 임
                let normalizedX = Float(screenX / windowWidth) * 2 - 1
                let normalizedY = 1 - Float(screenY / windowHeight) * 2
                
                // Particle이 이동할 위치
                // 전체적으로 우상단 방향으로 이동하지만 모두가 이동하지는 않게 적절한 값으로..
                let dx = Float.random(in: 0.05 ... 0.1)
                let dy = Float.random(in: -0.01 ... 0.03)
                
                let particle = Particle(
                    position: simd_float2(normalizedX, normalizedY),
                    velocity: simd_float2(dx, dy),
                    life: 1.0,
                    textureCoord: simd_float2(textureX, textureY),
                )
                
                particles.append(particle)
            }
        }
        
        return particles
    }
    
    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard
            let drawable = currentDrawable,
            let renderPassDescriptor = currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }
        
        updateParticles()

        renderEncoder.setRenderPipelineState(pipelineStae)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateParticles() {
        let currentTime = CACurrentMediaTime()
        let elapsedTime = Float(currentTime - animationStartTime)
        
        for i in 0 ..< particles.count {
            particles[i].position.x += particles[i].velocity.x * elapsedTime
            particles[i].position.y += particles[i].velocity.y * elapsedTime
            particles[i].life = max(0.0, 1.0 - elapsedTime)
        }
        
        // Buffer에 있는 컨텐츠를 기반으로 GPU에서 그리기 떄문에 업데이트 된 particles를 덮어씌우기
        let bufferSize = MemoryLayout<Particle>.size * particles.count
        _ = particles.withUnsafeBufferPointer { particlesPtr in
            memcpy(particleBuffer.contents(), particlesPtr.baseAddress, bufferSize)
        }
    }
    
    // MARK: - Disintegrate Public API
    public func disintegrate(
        from view: UIView,
        maxTile: Int = 50000,
        inset: CGFloat = 20
    ) {
        guard
            let snapshotImage = uiImage(
                from: view,
                bounds: view.bounds.insetBy(dx: inset, dy: inset)
            ).cgImage,
            let texture = createTexture(
                from: snapshotImage,
                bounds: view.bounds.insetBy(dx: inset, dy: inset)
            ),
            let window = view.window
        else {
            return
        }
        
        particles.removeAll()
        frame = window.bounds
        window.addSubview(self)
        
        let particles = createParticles(from: snapshotImage, original: view, inset: inset, maxTiles: maxTile)
        particleBuffer = device?.makeBuffer(
            bytes: particles,
            length: MemoryLayout<Particle>.size * particles.count,
        )
        
        self.particles = particles
        self.texture = texture
        self.animationStartTime = CACurrentMediaTime()
        
        view.removeFromSuperview()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.removeFromSuperview()
        }
    }
}
