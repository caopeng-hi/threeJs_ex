 varying vec2 vUv;
 varying vec3 vNormal;
 varying vec3 vPosition;
 uniform float uTime;
 uniform float uUniqueOffset;


 void main(){
        vUv = uv;
        vNormal = normal;
        float breathingScale = sin(uTime * 2.0 + uUniqueOffset) * 0.05 + 1.0;
        vec3 breathingPos = position * breathingScale;
        vec3 transformed = breathingPos;
        transformed += normal * sin(uTime * 3.5 + uUniqueOffset + length(position) * 10.0) * 0.03;
        vPosition = transformed;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(transformed, 1.0);
 }