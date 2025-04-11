precision highp float;
  uniform vec2 uPointer;
  uniform float uProgress;
  uniform sampler2D tDepthMap;
  uniform sampler2D tMap;
  uniform vec2 uResolution;
  uniform float uAspect;
  uniform float uStrength;

  varying vec2 vUv;

  // 交叉形状的距离场函数（SDF）
  float sdCross(vec2 p, vec2 size, float angle) {
    p = abs(p);  // 使形状对称
    // 计算水平和垂直臂的距离场
    float d1 = length(max(p - vec2(size.x, 0.0), 0.0));
    float d2 = length(max(p - vec2(0.0, size.y), 0.0));
    // 取最小值得到交叉形状
    return min(d1, d2);
}

    vec3 blendScreen(vec3 a, vec3 b) {
    return 1.0 - (1.0 - a) * (1.0 - b);
    }
  void main() {
    vec2 uv = vUv;

    // 1. 主纹理 + 深度图偏移
    float depth = texture2D(tDepthMap, uv).r;
    vec2 offset = uPointer * depth * uStrength;
    vec3 tMapColor = texture2D(tMap, uv + offset).rgb * 0.8;

    // 2. 生成交叉图案
    vec2 tUv = vec2(uv.x * uAspect, uv.y);  // 1. 调整UV坐标以保持宽高比
    vec2 tiling = vec2(50.0);               // 2. 设置平铺密度(50x50)
    vec2 tiledUv = mod(tUv * tiling, 2.0) - 1.0; // 3. 创建平铺UV坐标(-1到1范围)
    float dist = sdCross(tiledUv, vec2(0.3, 0.3), 0.0); // 4. 计算交叉形状距离场
    vec3 cross = vec3(smoothstep(0.0, 0.02, dist)); // 5. 生成平滑的交叉图案

    // 3. 深度遮罩
    float invertedDepth = 1.0 - depth;
    float flow = 1.0 - smoothstep(0.0, 0.02, abs(invertedDepth - uProgress));

    // 4. 混合最终效果
    vec3 mask = (1.0 - cross) * flow * vec3(10.0);
    vec3 final = blendScreen(tMapColor, mask); 

    gl_FragColor = vec4(final, 1.0);
  }