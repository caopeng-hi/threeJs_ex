  uniform sampler2D noiseMap;  
  uniform float time;  
  varying vec2 vUv;

void main() {
    vec4 noiseCol1 = texture2D( noiseMap, vUv * 2.2 + vec2(time*.1, -time*.9));    
    vec4 noiseCol2 = texture2D( noiseMap, vUv * 3. + vec2(.0, -time*1.6));
    float ashes = 1. - (noiseCol1.r * noiseCol2.g * noiseCol2.b );    
    ashes += pow(vUv.y, 2.);    
    ashes = smoothstep(.65,.75, ashes);
    gl_FragColor = vec4(ashes, ashes, ashes, 1.0);
}