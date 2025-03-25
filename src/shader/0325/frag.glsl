varying float pointDisplacement;
varying vec3 vColor;
uniform float uMouseRadius;

void main(){
    vec4 finalColor = vec4(vColor + min(pointDisplacement / 15.0, 0.3), 1.0);
    gl_FragColor = finalColor;
}