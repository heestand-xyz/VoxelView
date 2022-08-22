//
//  Shaders.metal
//  GrokVox
//
//  Created by Clay Garrett on 11/8/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn
{
    float4 position [[position]];
    float4 color;
    float3 normal;
    bool highlighted;
    float2 uv;
    float3 shadow_coord;
    uint3 location;
};

struct VertexOut
{
    float4 position [[position]];
    float4 color;
    float3 normal;
    float directional_light_level;
    bool highlighted;
    float2 uv;
    float3 shadow_coord;
};

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
    float4x4 shadow_mvp_matrix;
    float4x4 shadow_mvp_xform_matrix;
    uint3 resolution;
};

vertex VertexOut vertex_project(const device VertexIn *vertices[[buffer(0)]],
                                constant Uniforms *uniforms [[buffer(1)]],
                                texture3d<float> texture [[ texture(0) ]],
                                sampler sampler [[ sampler(0) ]],
                                uint vid [[vertex_id]],
                                uint iid [[instance_id]])
{
    
    uint3 resolution = uniforms->resolution;
    
    uint index = iid;
    uint x = index % resolution.x;
    uint y = (index / resolution.x) % resolution.y;
    uint z = index / (resolution.x * resolution.y);
    uint3 xyz = uint3(x, y, z);
    
    //uint3 location = vertices[vid].location;
    
    float u = (float(x) + 0.5) / float(resolution.x);
    float v = (float(y) + 0.5) / float(resolution.y);
    float w = (float(z) + 0.5) / float(resolution.z);
    float3 uvw = float3(u, v, w);
    
    float4 color = texture.sample(sampler, uvw);
    
//    float4 sunDirection = { -1, -2, -1, 1} ;
    
//    float dotProduct = dot(normalize(vertices[vid].normal), normalize(-sunDirection.xyz));
    
    VertexOut vertexOut;
//    vertexOut.shadow_coord = (uniforms->shadow_mvp_xform_matrix * vertices[vid].position ).xyz;
    vertexOut.position = uniforms->modelViewProjectionMatrix * (vertices[vid].position + float4(float3(xyz) * 2, 0.0));
//    vertexOut.normal = vertices[vid].normal.xyz;
//    vertexOut.highlighted = vertices[vid].highlighted;
    vertexOut.color = color; // vertices[vid].color;
//    vertexOut.directional_light_level = 0.7 + 0.3 * dotProduct;

    float2 uv = vertices[vid].uv;
    
    
   
    vertexOut.uv =   uv;
    
    //vertexOut.color = vertices[vid].color;

    
    return vertexOut;
}

fragment float4 fragment_flatcolor(VertexOut vertexIn [[stage_in]]
//                                   texture2d<float> diffuseTexture [[texture(0)]],
//                                   depth2d<float> shadowTexture [[texture(1)]],
//                                   sampler depthSampler [[sampler(1)]]
) {
//    return float4(vertexIn.normal.x * 0.5 + 0.5, vertexIn.normal.y * 0.5 + 0.5, vertexIn.normal.z * 0.5 + 0.5 , 1.0);
    
    float4 diffuse = vertexIn.color;
    
//    diffuse *= vertexIn.directional_light_level;
    
//    constexpr sampler shadowSampler(coord::normalized,
//                                    filter::linear,
//                                    mip_filter::none,
//                                    address::clamp_to_edge,
//                                    compare_func::less);
    
    // Compare the depth value in the shadow map to the depth value of the fragment in the sun's.
    // frame of reference.  If the sample is occluded, it will be zero.
    
    
//    float shadow_sample = shadowTexture.sample_compare(shadowSampler, vertexIn.shadow_coord.xy, vertexIn.shadow_coord.z);
    
    
    
    if (diffuse.a < 0.5) {
       discard_fragment();
    }
        
    return diffuse;
//    return float4(diffuse.xyz * 0.7 + shadow_sample * 0.3) , 1);
}


//fragment float4 fragment_main(Vertex inVertex [[stage_in]])
//{
////    return float4(inVertex.normal.x, inVertex.normal.y, inVertex.normal.z, 1.0);
//}

