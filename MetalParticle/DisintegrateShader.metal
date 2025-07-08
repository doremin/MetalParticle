#include <metal_stdlib>

using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float life;
    float2 textureCoord;
};

struct Uniforms {
    float time;
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoord;
    float pointSize [[point_size]];
    float alpha;
};

vertex VertexOut particleVertexShader(uint vertexID [[vertex_id]],
                                      constant Particle* particles [[buffer(0)]],
                                      constant Uniforms& uniforms [[buffer(1)]]) {
    Particle particle = particles[vertexID];
    
    VertexOut out;
    float2 position = particle.position + particle.velocity * uniforms.time;
    out.position = float4(position, 0.0, 1.0);
    out.textureCoord = particle.textureCoord;
    out.pointSize = 5.0;
    out.alpha = 1.0 - uniforms.time;
    return out;
};

fragment float4 particleFragmentShader(VertexOut in [[stage_in]],
                                          texture2d<float> colorTexture [[texture(0)]]) {
    
    constexpr sampler textureSampler;
    
    float4 color = colorTexture.sample(textureSampler, in.textureCoord);
    
    color.a *= in.alpha;
    
    return color;
}
