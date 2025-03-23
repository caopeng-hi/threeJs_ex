 attribute float size;
 varying vec3 vColor;
 uniform float uTime;


 void main(){
        vColor = color;
        float pulse = sin(uTime * 2.0 + position.x * 5.0 + position.y * 3.0 + position.z * 4.0) * 0.3 + 1.0;
        vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
        gl_PointSize = size * pulse * (300.0 / -mvPosition.z);
        gl_Position = projectionMatrix * mvPosition;
 }