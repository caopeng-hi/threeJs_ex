uniform float uTime;
uniform float uProgress;
uniform  float uMinY;
uniform float uMaxY;
varying vec3 vPosition;
varying vec3 vNormal;
float random(vec2 st) { 
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}
void main(){
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    float glitchTime = uTime - modelPosition.y;
    float glitchstrength = sin(glitchTime) * sin(glitchTime * 3.45) + sin(glitchTime * 8.76);
    glitchstrength /= 3.0;
    glitchstrength = smoothstep(0.5, 1.0, glitchstrength);
    glitchstrength *= 2.0;
    modelPosition.x += (random(modelPosition.xz + uTime) - 0.5) * glitchstrength;
    modelPosition.z += (random(modelPosition.xz + uTime) - 0.5) * glitchstrength;

    float normalizedY = (modelPosition.y - uMinY) / (uMaxY - uMinY);
    float diff = abs(normalizedY - uProgress);
    float glitchStrength = smoothstep(0.02, 0.0, diff);
    glitchStrength *= 0.3;

    modelPosition.x += (random(modelPosition.xz + uTime) - 0.5) * glitchStrength;
    modelPosition.z += (random(modelPosition.xz + uTime) - 0.5) * glitchStrength;
    gl_Position = projectionMatrix * viewMatrix * modelPosition;

    vPosition = modelPosition.xyz;

    vec4 newNormal = modelMatrix * vec4(normal, 0.0);
    vNormal = newNormal.xyz;
}