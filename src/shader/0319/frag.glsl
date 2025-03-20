// 设置浮点数精度为高精度，确保计算结果更精确
precision highp float;

// 从顶点着色器传递过来的纹理坐标，用于确定当前像素在纹理中的位置
varying vec2 vUv;

// 表示当前渲染窗口的分辨率，通常是一个二维向量，包含宽度和高度
uniform vec2 uResolution;

// 表示当前的时间，用于创建动画效果，通常由外部程序不断更新
uniform float uTime;

// 定义一个常量，表示分形布朗运动（FBM）中的八度数量
#define NUM_OCTAVES 5

/**
 * 生成一个基于二维向量的随机数
 * @param n 输入的二维向量
 * @return 范围在 [0, 1] 之间的随机浮点数
 */
float rand(vec2 n) {
    // 使用点积和正弦函数生成一个随机值，然后取小数部分
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); 
}

/**
 * 计算二维噪声值
 * @param p 输入的二维向量，表示噪声计算的位置
 * @return 范围在 [0, 1] 之间的噪声值
 */
float noise(vec2 p) {
    // 计算 p 的整数部分，用于确定当前点所在的网格单元
    vec2 ip = floor(p);
    // 计算 p 的小数部分，用于插值计算
    vec2 u = fract(p);
    // 使用平滑插值函数，使噪声过渡更自然
    u = u * u * (3.0 - 2.0 * u);
    // 计算四个相邻网格点的随机值，并进行双线性插值
    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
        u.y
    );
    // 对结果进行平方，增强噪声的对比度
    return res * res;
}

/**
 * 计算分形布朗运动（FBM）噪声值
 * @param x 输入的二维向量，表示 FBM 计算的位置
 * @return 范围在 [0, 1] 之间的 FBM 噪声值
 */
float fbm(vec2 x) {
    // 初始化 FBM 噪声值
    float v = 0.0;
    // 初始化振幅
    float a = 0.5;
    // 定义一个偏移向量，用于增加随机性
    vec2 shift = vec2(100);
    // 定义一个旋转矩阵，用于旋转输入向量
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    // 循环计算每个八度的噪声值
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        // 将当前八度的噪声值累加到 v 中
        v += a * noise(x);
        // 对输入向量进行旋转、缩放和偏移操作
        x = rot * x * 2.0 + shift;
        // 每次循环后，振幅减半
        a *= 0.5;
    }
    return v;
}

/**
 * 主函数，每个像素都会执行一次
 */
void main() {
    // 计算一个抖动效果，使画面产生轻微的晃动
    vec2 shake = vec2(sin(uTime * 1.5) * 0.01, cos(uTime * 2.7) * 0.01);
    // 根据纹理坐标和分辨率计算当前像素的坐标
    vec2 fragCoord = vUv * uResolution;
    // 对像素坐标进行归一化和变换，使其在屏幕中心，并进行缩放
    vec2 p = ((fragCoord + shake * uResolution) - uResolution * 0.5) / uResolution.y;
    // 对归一化后的坐标进行矩阵变换，改变画面的形状
    p *= mat2(8.0, -6.0, 6.0, 8.0);
    // 定义一个临时二维向量，用于后续计算
    vec2 v;
    // 初始化最终颜色值为黑色
    vec4 o = vec4(0.0);
    // 计算一个基础噪声值，用于后续的颜色计算
    float f = 3.0 + fbm(p + vec2(uTime * 7.0, 0.0));
    // 循环 50 次，每次循环计算一个贡献值，并累加到最终颜色中
    for (float i = 0.0; i < 50.0; i++) {
        // 计算当前循环的位置向量，包含时间、噪声和偏移信息
        v = p + cos(i * i + (uTime + p.x * 0.1) * 0.03 + i * vec2(11.0, 9.0)) * 5.0 + vec2(sin(uTime * 4.0 + i) * 0.005, cos(uTime * 4.5 - i) * 0.005);
        // 计算当前位置的尾部噪声值，并根据循环次数进行衰减
        float tailNoise = fbm(v + vec2(uTime, i)) * (1.0 - (i / 50.0));
        // 计算当前循环的颜色贡献值，包含三角函数、指数函数和长度计算
        vec4 currentContribution = (cos(sin(i) * vec4(1.0, 2.0, 3.0, 1.0)) + 1.0) * exp(sin(i * i + uTime)) / length(max(v, vec2(v.x * f * 0.02, v.y)));
        // 计算一个细薄因子，使尾部逐渐变细
        float thinnessFactor = smoothstep(0.0, 1.0, i / 50.0);
        // 将当前贡献值乘以噪声和细薄因子，并累加到最终颜色中
        o += currentContribution * (1.0 + tailNoise * 2.0) * thinnessFactor;
    }
    // 对最终颜色值进行非线性变换，使用双曲正切函数和幂运算
    o = tanh(pow(o / 1e2, vec4(1.5)));
    // 将最终颜色值赋值给当前像素的颜色
    gl_FragColor = o;
}