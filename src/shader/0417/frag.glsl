// Uniform变量声明（从JavaScript传入的值）
uniform float uTime;        // 时间变量，用于动画效果
uniform float uIndex;       // 当前物体的索引
uniform float uCurrentIndex; // 当前激活物体的索引
uniform float uNextIndex;   // 下一个激活物体的索引
uniform float uProgress;    // 过渡进度(0-1)
uniform vec3 uColor;        // 基础颜色
uniform float uMinY;        // 物体Y轴最小值
uniform float uMaxY;        // 物体Y轴最大值

// 从顶点着色器传递的变量
varying vec3 vPosition;     // 当前片元的世界坐标
varying vec3 vNormal;       // 当前片元的法线向量

void main(){
    // 如果当前物体既不是当前激活也不是下一个激活的物体，则丢弃片元
    if(uIndex != uCurrentIndex && uIndex != uNextIndex) {
        discard;
    }
    
    // 创建条纹效果
    float lines = 20.0;                  // 条纹密度
    float offset = vPosition.y - uTime * 0.2; // 随时间移动的Y轴偏移
    float density = mod(offset * lines, 1.0); // 使用模运算创建重复条纹
    density = pow(density, 3.0);         // 增强条纹对比度
    
    // 计算菲涅尔效应
    vec3 viewDirection = normalize(vPosition - cameraPosition); // 视线方向
    float fresnel = 1.0 - abs(dot(normalize(vNormal), viewDirection)); // 菲涅尔强度
    fresnel = pow(fresnel, 2.0);         // 增强菲涅尔效果
    
    // 边缘衰减效果
    float falloff = smoothstep(0.8, 0.0, fresnel); // 平滑过渡
    
    // 组合全息效果
    float holographic = density * fresnel; // 条纹与菲涅尔结合
    holographic += fresnel * 1.25;        // 增强边缘亮度
    holographic *= falloff;               // 应用边缘衰减
    
    // 计算当前片元在物体Y轴的归一化位置(0-1)
    float normalizedY = (vPosition.y - uMinY) / (uMaxY - uMinY);
    
    // 过渡动画处理
    if(uIndex == uCurrentIndex && normalizedY < uProgress) {
        discard; // 当前物体低于过渡线的部分丢弃
    }
    if(uIndex == uNextIndex && normalizedY > uProgress) {
        discard; // 下一个物体高于过渡线的部分丢弃
    }
    
    // 输出最终颜色（RGBA，A通道控制透明度）
    gl_FragColor = vec4(uColor, holographic);
    
    // Three.js内置函数（色调映射和色彩空间转换）
    #include <tonemapping_fragment>
    #include <colorspace_fragment>
}