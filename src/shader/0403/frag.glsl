varying vec3 vNormal; 
void main() { 
    float intensity = pow( 0.7 - dot( vNormal, vec3( 0.0, 0.0, 0.5 ) ), 4.0 ); 
    gl_FragColor = vec4( 0.89, 0.82, 0.69, 1.0 ) * intensity; 
    }