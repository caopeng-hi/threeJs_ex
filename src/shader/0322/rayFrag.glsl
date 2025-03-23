varying vec3 vColor;
varying float vLife;


void main(){
        vec2 coord = gl_PointCoord - vec2(0.5);
        float distanceToCenter = length(coord);
        if (distanceToCenter > 0.5) discard;
        
        float strength = 1.0 - distanceToCenter * 2.0;
        strength = pow(strength, 3.0);
        
        float noise = sin(distanceToCenter * 30.0 + vLife * 10.0) * cos(distanceToCenter * 25.0) * 0.3 + 0.7;
        strength *= noise;
        
        vec3 finalColor = vColor * (2.5 * vLife);
        gl_FragColor = vec4(finalColor, strength * vLife * 1.5);
}