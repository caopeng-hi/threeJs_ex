// Uniform变量（从JavaScript传入的值）
uniform float uTime;       // 时间变量，用于动画效果
uniform float uProgress;   // 过渡进度(0-1)
uniform float uMinY;       // 物体Y轴最小值
uniform float uMaxY;       // 物体Y轴最大值

// 传递给片段着色器的变量
varying vec3 vPosition;    // 顶点世界坐标
varying vec3 vNormal;      // 顶点法线向量

// 随机数生成函数（伪随机）
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    // 计算顶点在世界空间中的位置
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    
    // 基于时间和Y坐标计算故障效果时间
    float glitchTime = uTime - modelPosition.y;
    
    // 通过多个正弦波叠加计算基础故障强度
    float glitchstrength = sin(glitchTime) * sin(glitchTime * 3.45) + sin(glitchTime * 8.76);
    glitchstrength /= 3.0;  // 降低强度
    glitchstrength = smoothstep(0.5, 1.0, glitchstrength); // 平滑过渡
    glitchstrength *= 2.0;  // 增强效果
    
    // 在X和Z轴应用随机偏移（故障效果）
    modelPosition.x += (random(modelPosition.xz + uTime) - 0.5) * glitchstrength;
    modelPosition.z += (random(modelPosition.xz + uTime) - 0.5) * glitchstrength;
    
    // 计算当前顶点在物体Y轴的归一化位置(0-1)
    float normalizedY = (modelPosition.y - uMinY) / (uMaxY - uMinY);
    float diff = abs(normalizedY - uProgress); // 计算与过渡线的距离
    
    // 基于过渡进度计算额外的故障强度
    float glitchStrength = smoothstep(0.02, 0.0, diff); // 靠近过渡线时强度增加
    glitchStrength *= 0.3; // 降低强度
    
    // 在X和Z轴应用额外的随机偏移（过渡效果）
    modelPosition.x += (random(modelPosition.xz + uTime) - 0.5) * glitchStrength;
    modelPosition.z += (random(modelPosition.xz + uTime) - 0.5) * glitchStrength;
    
    // 计算最终的裁剪空间坐标
    gl_Position = projectionMatrix * viewMatrix * modelPosition;
    
    // 传递世界坐标给片段着色器
    vPosition = modelPosition.xyz;
    
    // 计算并传递世界空间法线
    vec4 newNormal = modelMatrix * vec4(normal, 0.0);
    vNormal = newNormal.xyz;
}