//
//  Shaders.metal
//  MTLRaytracing-iOS
//
//  Created by Eoin Roe on 09/11/2020.
//

#include <metal_stdlib>
using namespace metal;

void kernel gradient(texture2d<float, access::write> tex0,
                     uint2 tid [[thread_position_in_grid]])
{
    float2 resolution = float2(tex0.get_width(),
                               tex0.get_height());
    
    float2 uv = (float2)tid / resolution;
    tex0.write( float4(uv.x, 0, uv.y, 1), tid );
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

struct RasterizerData {
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];
    float2 uv;
};

vertex RasterizerData
base_vertex(unsigned short vid [[vertex_id]]) {
    float2 position = quadVertices[vid];
    
    RasterizerData out {
        .position = float4(position, 0, 1),
        
        // N.B. Need to check this line in the raytracer now
        .uv = position * 0.5 + 0.5
    };
    
    return out;
}
            
fragment float4
base_fragment(RasterizerData in [[stage_in]]) {
    float2 st = in.uv;
    
    // Gradient
    return float4(0.0, st.x, st.y, 1.0);
}
