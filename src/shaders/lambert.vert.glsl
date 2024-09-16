#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time; // In seconds

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec3 fs_world;         // The world position of each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Up;            // The up vector of the camera in world space. This is implicitly passed to the fragment shader.
const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
const vec2 wavedir1 = vec2(0.70710, 0.70710);
const vec2 wavedir2 = vec2(-0.70710, 0.70710);
#define MOD3 vec3(443.8975,397.2973, 491.1871)
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float computeWave(vec2 pos, float amp, vec2 vel, float freq)
{
    vec2 wave = vec2(amp * sin(pos.x * freq + u_Time * vel.x), amp * sin(pos.y * freq + u_Time * vel.y));
    
    return length(wave);
}

float hightOffset(vec3 pos)
{
    float wave1 = computeWave(pos.xz + hash12(vec2(114.514, 1919.810)), 0.6, 2.0 * wavedir1, 5.0);
    float wave2 = computeWave(pos.xz + hash12(vec2(372561.0, 99232.0)), 0.3, 1.0 * wavedir2, 10.0);
    return wave1 + wave2;
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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    
    vec4 modelposition =  u_Model * vs_Pos;
    fs_world = vec3(modelposition); // Pass the world position of the vertex to the fragment shader

    float delta = 0.01;
    // compute vertex offset
    float attenuation = clamp(dot(fs_Nor, vec4(0, 1.0, 0, 0)), 0.0, 1.0);
    attenuation = getBias(attenuation, 0.35);
    // vec3 dxPositive = modelposition.xyz + vec3(delta, 0, 0);
    // dxPositive.y += hightOffset(dxPositive) * attenuation;
    // vec3 dxNegative = modelposition.xyz + vec3(-delta, 0, 0);
    // dxNegative.y += hightOffset(dxNegative) * attenuation;
    // vec3 dx = normalize(dxPositive - dxNegative);

    // vec3 dzPositive = modelposition.xyz + vec3(0, 0, delta);
    // dzPositive.y += hightOffset(dzPositive) * attenuation;
    // vec3 dzNegative = modelposition.xyz + vec3(0, 0, -delta);
    // dzNegative.y += hightOffset(dzNegative) * attenuation;
    // vec3 dz = normalize(dzPositive - dzNegative);

    // vec3 normal = normalize(cross(dz, dx));
    // fs_Nor = vec4(normal, 0);

    float offset = hightOffset(modelposition.xyz) * attenuation;
    modelposition.y += offset;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
    fs_Up = u_ViewProj * vec4(0, 1, 0, 0);

                                             
}
