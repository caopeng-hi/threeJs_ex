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
    p = abs(p);
    if (p.x > p.y) p = p.yx;
    vec2 q = p - size;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
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
    vec2 tUv = vec2(uv.x * uAspect, uv.y);
    vec2 tiling = vec2(50.0);
    vec2 tiledUv = mod(tUv * tiling, 2.0) - 1.0;
    float dist = sdCross(tiledUv, vec2(0.3, 0.02), 0.0);
    vec3 cross = vec3(smoothstep(0.0, 0.02, dist));

    // 3. 深度遮罩
    float invertedDepth = 1.0 - depth;
    float flow = 1.0 - smoothstep(0.0, 0.02, abs(invertedDepth - uProgress));

    // 4. 混合最终效果
    vec3 mask = (1.0 - cross) * flow * vec3(10.0);
    vec3 final = blendScreen(tMapColor, mask); 

    gl_FragColor = vec4(final, 1.0);
  }