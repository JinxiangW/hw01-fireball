#version 300 es
precision mediump int;
// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform float u_Frequency;
// These are the interpolated values out of the rasterizer, so you can't know

uniform int u_Noise;
uniform float u_Time; // in seconds
uniform float u_Speed;
uniform vec3 u_Camera;
uniform vec2 u_Resolution;
uniform vec2 u_Mouse;
uniform int u_Octaves;
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec3 fs_world;
in vec4 fs_Up;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
#define MOD3 vec3(443.8975,397.2973, 491.1871)

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p)
{
    vec3 p3 = fract(p * MOD3);
    p3 += dot(p3, p3.zyx+19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float getBias(float t, float b) {
    return (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
}

float getGain(float t, float gain)
{
  if(t < 0.5)
    return getBias(t * 2.0, gain)/2.0;
  else
    return getBias(t * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}

vec3 rand(vec3 p){
 	const vec3 k = vec3( 3.1415926, 2.71828,6.62607015);
 	p = p*k + p.yzx;
 	return -1.0 + 2.0*fract( 2.0 * k * fract( p.x*p.y*(p.x+p.y)) );
}

// 3d fbm function
float cubic(float a) {
    return a * a * (3.0 - 2.0 * a);
}

float sdfSphere2d(vec2 p, float r)
{
    return length(p) - r;
}



float computeWave(vec2 pos, float amp, vec2 vel, float freq)
{
    vec2 wave = vec2(amp * sin(pos.x * freq + u_Time * u_Speed * vel.x), amp * sin(pos.y * freq + u_Time * u_Speed * vel.y));
    
    return length(wave);
}

float hightOffset(vec3 pos)
{
    float wave = 0.0;
    for (int i = 1; i <= u_Octaves; i++)
    {
        // generate random wave dir using hash12
        vec2 wavedir = normalize(vec2(hash12(vec2(float(i) * 4832.11)), hash12(vec2(float(i) * 331.11))));

        float freq = 2.5 * pow(2.0, float(i));
        float amp = 1.2 * pow(0.5, float(i));
        wave += computeWave(pos.xz + hash12(vec2(float(i) * 4832.11)), amp, 2.0 * wavedir, freq);
    }
    return wave;
}

const float PI = 3.14159265359;
void main()
{
    vec2 up = normalize(vec2(fs_Up.xy));
    vec3 world = normalize(fs_world);
    vec2 UV = gl_FragCoord.xy / u_Resolution.y;
    vec2 screenCenter = vec2(u_Resolution.x / (2.0 * u_Resolution.y), 0.5);

    // // mouse interaction
    // vec2 mouse = u_Mouse / u_Resolution.y;
    // mouse.y = 1.0 - mouse.y;
    // float dist = distance(UV, mouse);
    // float radius = 0.1;
    // float transparency = 1.0;
    // if (dist < radius)
    // {
    //     float t = 1.0 - dist / radius;
    //     t = getGain(t, 0.5);
    //     // t = PI / 6.0; // map the range of t to [0, PI/6]
    //     // initialize rotation matrices, as t gets higher, the more distorted the sphere becomes
    //     mat3 rtz = mat3(cos(t), -sin(t), 0, sin(t), cos(t), 0, 0, 0, 1);
    //     mat3 rty = mat3(cos(t), 0, sin(t), 0, 1, 0, -sin(t), 0, cos(t));
    //     world = rtz * rty * world;
    //     // transparency = t;
    // }

    float attenuation = clamp(dot(fs_Nor, vec4(0, 1.0, 0, 0)), 0.0, 1.0);
    attenuation = getBias(attenuation, 0.15);
    float offset = hightOffset(world.xyz) * attenuation;
    world.y += offset;
    vec3 dx = dFdx(world);
    vec3 dy = dFdy(world);
    vec3 normal = normalize(cross(dx, dy));

    
    // vec3 normal = fs_Nor.xyz;
    vec3 viewDir = normalize(u_Camera - fs_world);
    // vec3 normal = fs_Nor.xyz;
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for half-Lambert shading
    float diffuseTerm = dot(normalize(vec4(normal, 0.0)), normalize(fs_LightVec));
    diffuseTerm = diffuseTerm * 0.5 + 0.5;

    float ambientTerm = 0.2;
    float hightlightTerm = pow(max(dot(normalize(fs_LightVec.xyz + viewDir.xyz), fs_Nor.xyz), 0.0), 32.0);
    float lightIntensity = diffuseTerm + ambientTerm + hightlightTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.
    // Compute final shaded color

    vec3 flame = u_Color.rgb;
    float theta = dot(viewDir, normal);
    float threshold = clamp((UV.y - 0.3), 0.0, 1.0) * 2.2;
    if (theta < threshold)
    {
        flame = vec3(220.0, 0, 0) / 255.0;
    } else
    {
        vec2 sphereCenter = screenCenter + up * 0.13;
        float transition = sdfSphere2d(UV - sphereCenter, 0.25);
        transition = 1.0 - clamp((transition + 0.1) / 0.2, 0.0, 1.0);
        transition = getGain(transition, 0.12) * 0.2;
        flame = flame * (1.0 + transition);
    }
    
    

    // return output color
    out_Col = vec4(flame, 1.0);
}
