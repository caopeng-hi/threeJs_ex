  uniform sampler2D noiseMap;  
  uniform float time;  
  uniform float opacity;  
  uniform float stylizeRatio;  
  uniform float stylizeThreshold;  
  uniform float details;  
  uniform bool grayscale;  
  varying vec2 vUv;

  float makeBorders(vec2 uv, float top, float left, float bottom, float right, float gradient){    
    float t = 1. - smoothstep(top, top + gradient, uv.y);    
    float b = smoothstep(bottom - gradient, bottom, uv.y);    
    float r = 1. - smoothstep(right, right + gradient, uv.x);    
    float l = smoothstep(left - gradient, left, uv.x);    
    return t*b*l*r;  
}

void main() {

    vec4 noiseCol1 = texture2D( noiseMap, vUv * vec2(2., 2.) + vec2(.0, -time * 3.));    
    vec4 noiseCol2 = texture2D( noiseMap, vUv * vec2(3., 1.) + vec2(.0, -time));    
    vec4 noiseCol3 = texture2D( noiseMap, vUv * vec2(1., 1.) + vec2(.0, -time*1.5));

    float flameHoles = noiseCol3.r * noiseCol3.g;
    flameHoles += pow( 1. - vUv.y, 2.);
    flameHoles = smoothstep(.30,.6, flameHoles);

    float red = noiseCol1.r + noiseCol1.g * .5 + noiseCol1.b * .25;   
    float green  = noiseCol1.r * makeBorders(vUv, .8, .4, .1, .6, .1);    
    float blue = noiseCol1.r * makeBorders(vUv, .6, .5, .1, .5, .1); 
    vec4 flame = vec4(red, green, blue, 1.);
    flame.r += (noiseCol2.r * noiseCol2.g * noiseCol2.b) * details;    
    flame.g += (noiseCol2.r * noiseCol2.g * noiseCol2.b) * details;    
    flame.b += (noiseCol2.r * noiseCol2.g * noiseCol2.b) * details;
    vec3 stylisedFlame = vec3(0.);    
    stylisedFlame.r = step(stylizeThreshold, flame.r);    
    stylisedFlame.g = step(stylizeThreshold, flame.g);    
    stylisedFlame.b = step(stylizeThreshold, flame.b);      
    flame.rgb = mix(flame.rgb, stylisedFlame, stylizeRatio);
    flame.rgb *= makeBorders(vUv, .7, .3, .4, .7, .25) * opacity * flameHoles;
    if (grayscale){     
        float flameValue = dot(flame.rgb, vec3(0.2, 0.3, 0.2));      
        flame = vec4(flameValue, flameValue, flameValue, 1.);   
     }        
     gl_FragColor = vec4(flame.rgb, 1.);
}