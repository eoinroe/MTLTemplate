//
//  Shaders.metal
//  ComputeNormals
//
//  Created by Eoin Roe on 11/02/2021.
//

#include <metal_stdlib>
using namespace metal;

// Encoding normal map in tangent space
kernel void tangentSpaceNormals(texture2d<float, access::read>  heightmap [[ texture(0) ]],
                                texture2d<float, access::write> normalmap [[ texture(1) ]],
                                constant float &intensity [[ buffer(0) ]],
                                uint2 gid [[ thread_position_in_grid ]])
{
    // Perform sampler-less reads from the heightmap using the thread ID.
    float dhdx = (heightmap.read(gid + uint2(1, 0)).r - heightmap.read(gid - uint2(1, 0)).r) * 0.5;
    float dhdy = (heightmap.read(gid + uint2(0, 1)).r - heightmap.read(gid - uint2(0, 1)).r) * 0.5;
    
    float3 normal = normalize(float3(-dhdx, -dhdy, intensity)) * 0.5f + 0.5f;
    normalmap.write(float4(normal, 1.0), gid);
}

// Screen filling quad in normalized device coordinates.
constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Simple vertex shader which passes through NDC quad positions.
vertex VertexOut base_vertex(unsigned short vid [[vertex_id]]) {
    float2 position = quadVertices[vid];
    
    VertexOut out {
        .position = float4(position, 0, 1),
        .uv = position * 0.5f + 0.5f
    };
    
    return out;
}

typedef VertexOut FragmentIn;

// Simple fragment shader which copies a texture.
fragment float4 base_fragment(FragmentIn in [[stage_in]],
                              texture2d<float, access::sample> normalmap)
{
    constexpr sampler s(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    float3 color = normalmap.sample(s, in.uv).xyz;
    
    return float4(color, 1.0);
}
