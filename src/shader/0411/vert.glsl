varying vec2 vUv;

void main() {
  vUv = uv;
  // 直接使用位置坐标，不经过模型视图变换
  gl_Position = vec4(position.xy, 0.0, 1.0); 
}