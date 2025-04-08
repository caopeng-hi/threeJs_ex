precision highp float;
uniform sampler2D noiseMap;
uniform float time;  
uniform float intensity;  
varying vec2 vUv;

void main() {
    vUv = uv;
    vec4 noise = texture2D(noiseMap, vUv * .3 + vec2(0., -time * .2));        
    vec3 pos = position;    pos.y *= intensity;        
    vec3 displacement = vec3(0., 0., 0.);    
    displacement.z += (-.5 + noise.g) * .1 * vUv.y;    
    displacement.y += (-.5 + noise.r) * .2 * vUv.y ;        
    vec4 modelViewPosition = modelViewMatrix * vec4(pos + displacement, 1.0);    
    gl_Position = projectionMatrix * modelViewPosition; 
}