  uniform sampler2D tDiffuse;  // 输入纹理
  uniform float opacity;   // 不透明度
  varying vec2 vUv;  // 从顶点着色器接收的纹理坐标
  
  void main() {
  vec4 texel = texture2D(tDiffuse, vUv); // 采样纹理
  gl_FragColor = opacity * texel;   // 应用不透明度
}