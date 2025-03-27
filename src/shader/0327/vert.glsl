varying vec2 vUv;
 void main() {
 vUv = uv;  // 传递纹理坐标
 gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
 }