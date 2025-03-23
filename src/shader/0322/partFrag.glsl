varying vec3 vColor;


void main(){
        float distanceToCenter = length(gl_PointCoord - vec2(0.5));
        if (distanceToCenter > 0.5) discard;
        float strength = 1.0 - (distanceToCenter * 2.0);
        strength = pow(strength, 1.5);
        gl_FragColor = vec4(vColor, strength);
}