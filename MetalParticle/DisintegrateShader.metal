#include <metal_stdlib>

using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float life;
    float2 textureCoord;
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoord;
    float pointSize [[point_size]];
    float alpha;
};

vertex VertexOut particleVertexShader(uint vertexID [[vertex_id]],
                                      constant Particle* particles [[buffer(0)]]) {
    Particle particle = particles[vertexID];
    
    VertexOut out;
    out.position = float4(particle.position, 0.0, 1.0);
    out.textureCoord = particle.textureCoord;
    out.pointSize = 5.0;
    out.alpha = particle.life;
    return out;
};

fragment float4 particleFragmentShader(VertexOut in [[stage_in]],
                                          texture2d<float> colorTexture [[texture(0)]]) {
    
    constexpr sampler textureSampler;
    
    float4 color = colorTexture.sample(textureSampler, in.textureCoord);
    
    color.a *= in.alpha;
    
    return color;
}
