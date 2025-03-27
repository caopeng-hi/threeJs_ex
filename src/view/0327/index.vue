<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { ShaderPass } from "three/addons/postprocessing/ShaderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { GammaCorrectionShader } from "three/addons/shaders/GammaCorrectionShader.js";
const canvasRef = ref(null);
const clock = new THREE.Clock();
let scene, camera, renderer, controls, composer, trailTexture, particleSystem;

onMounted(() => {
  initScene();
  animate();
});
function initScene() {
  // 创建场景
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x050505); // 深灰背景
  scene.fog = new THREE.Fog(0x050505, 10, 50); // 雾效果
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = 5; // 设置相机的位置

  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.toneMapping = THREE.ACESFilmicToneMapping; // 色调映射
  renderer.toneMappingExposure = 1; // 曝光度
  canvasRef.value.appendChild(renderer.domElement); // 将渲染器的 DOM 元素添加到 canvasRef 中

  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 启用阻尼
  controls.dampingFactor = 0.25; // 设置阻尼因子
  controls.screenSpacePanning = false; // 禁用屏幕空间平移
  controls.minDistance = 0.1; // 设置最小距离
  controls.maxDistance = 10; // 设置最大距离
  controls.maxPolarAngle = Math.PI / 2; // 设置最大极角

  // 添加鼠标交互的光标样式变化
  controls.addEventListener("start", () => {
    document.body.style.cursor = "grabbing"; // 抓取状态
  });

  controls.addEventListener("end", () => {
    document.body.style.cursor = "grab"; // 可抓取状态
  });

  // 添加环境光 - 提供整体柔和照明
  const ambientLight = new THREE.AmbientLight(
    0xffffff,
    0.7 // 环境光强度
  );
  scene.add(ambientLight);

  // 添加平行光 - 提供方向性照明和阴影
  const directionalLight = new THREE.DirectionalLight(
    0xffffff,
    1 // 平行光强度
  );
  directionalLight.position.set(1, 3, 2); // 设置光源位置
  directionalLight.castShadow = true; // 启用阴影投射
  scene.add(directionalLight);

  // 创建轨迹场景
  const trailScene = new THREE.Scene();
  const trailCamera = camera.clone(); // 使用相同的相机设置

  // 创建渲染目标纹理
  trailTexture = new THREE.WebGLRenderTarget(
    window.innerWidth,
    window.innerHeight,
    {
      minFilter: THREE.LinearFilter,
      magFilter: THREE.LinearFilter,
      format: THREE.RGBAFormat,
    }
  );

  // 创建主效果合成器
  composer = new EffectComposer(renderer);
  const renderPass = new RenderPass(scene, camera); // 创建渲染通道
  composer.addPass(renderPass); // 添加到合成器

  // 添加辉光效果
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight), // 尺寸
    0.8, // 辉光强度
    0.5, // 辉光半径
    0.85 // 辉光阈值
  );
  composer.addPass(bloomPass); // 添加到合成器

  // 添加伽马校正 - 确保颜色正确显示
  const gammaCorrectionPass = new ShaderPass(GammaCorrectionShader);
  composer.addPass(gammaCorrectionPass); // 添加到合成器

  // 创建轨迹效果合成器
  const trailComposer = new EffectComposer(renderer, trailTexture);
  const trailRenderPass = new RenderPass(trailScene, trailCamera);
  trailComposer.addPass(trailRenderPass); // 添加到轨迹合成器

  // 粒子数量
  const numParticles = 25000;
  // 创建粒子几何体
  const geometry = new THREE.BufferGeometry();
  const positions = new Float32Array(numParticles * 3); // 位置数组 (x,y,z) * 粒子数量
  const colors = new Float32Array(numParticles * 3); // 颜色数组 (r,g,b) * 粒子数量
  const sizes = new Float32Array(numParticles); // 大小数组

  // 使用球坐标算法分布粒子，确保均匀覆盖球体表面
  for (let i = 0; i < numParticles; i++) {
    // 球坐标计算
    const phi = Math.acos(-1 + (2 * i) / numParticles); // 天顶角
    const theta = Math.sqrt(numParticles * Math.PI) * phi; // 方位角
    // 转换为笛卡尔坐标
    const x = Math.sin(phi) * Math.cos(theta);
    const y = Math.sin(phi) * Math.sin(theta);
    const z = Math.cos(phi);

    // 设置粒子位置，乘以1.5缩放球体大小
    positions[i * 3] = x * 1.5;
    positions[i * 3 + 1] = y * 1.5;
    positions[i * 3 + 2] = z * 1.5;

    // 设置粒子颜色，基于基础颜色添加随机亮度变化
    const color = new THREE.Color(0xff5900); // 粒子颜色 (橙色)
    color.offsetHSL(0, 0, (Math.random() - 0.5) * 0.5); // 随机调整亮度
    colors[i * 3] = color.r;
    colors[i * 3 + 1] = color.g;
    colors[i * 3 + 2] = color.b;

    // 设置粒子大小，添加随机变化
    sizes[i] = 0.035 * (0.8 + Math.random() * 0.4); // 粒子大小
  }
  // 将数据添加到几何体
  geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute("color", new THREE.BufferAttribute(colors, 3));
  geometry.setAttribute("size", new THREE.BufferAttribute(sizes, 1));

  // 创建粒子材质
  const material = new THREE.PointsMaterial({
    size: 0.035, // 粒子大小
    vertexColors: true, // 使用顶点颜色
    blending: THREE.AdditiveBlending, // 加法混合模式，使重叠粒子更亮
    depthTest: true, // 启用深度测试
    depthWrite: false, // 禁用深度写入，避免遮挡问题
    transparent: true, // 启用透明
    opacity: 0.9, // 设置不透明度
    sizeAttenuation: true, // 启用大小衰减，远处粒子更小
  });
  // 创建粒子系统并添加到场景
  particleSystem = new THREE.Points(geometry, material);
  scene.add(particleSystem);

  //   // 为轨迹效果创建粒子系统副本
  const trailParticles = particleSystem.clone();
  trailScene.add(trailParticles);

  // 创建轨迹效果的着色器材质
  const trailMaterial = new THREE.ShaderMaterial({
    uniforms: {
      tDiffuse: { value: null }, // 将在渲染时设置为上一帧的渲染结果
      opacity: { value: 0.3 }, // 轨迹不透明度 (运动轨迹效果强度)
    },
    // 顶点着色器 - 处理顶点位置
    vertexShader: `
 varying vec2 vUv;
 void main() {
 vUv = uv;  // 传递纹理坐标
 gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
 }
 `,
    // 片段着色器 - 处理像素颜色
    fragmentShader: `
  uniform sampler2D tDiffuse;  // 输入纹理
  uniform float opacity;   // 不透明度
 varying vec2 vUv;  // 从顶点着色器接收的纹理坐标
 void main() {
  vec4 texel = texture2D(tDiffuse, vUv); // 采样纹理
  gl_FragColor = opacity * texel;   // 应用不透明度
  }
 `,
  });

  // 创建轨迹效果通道并添加到合成器
  const trailPass = new ShaderPass(trailMaterial);
  trailPass.renderToScreen = true; // 设置为直接渲染到屏幕
  composer.addPass(trailPass);

  // 双击事件 - 重置相机位置和控制器
  renderer.domElement.addEventListener("dblclick", () => {
    camera.position.set(0, 0, 5); // 重置相机位置
    camera.lookAt(0, 0, 0); // 重置相机朝向
    controls.reset(); // 重置控制器
  });
}
function animate() {
  requestAnimationFrame(animate);
  controls.update(); // 更新控制器
  renderer.setRenderTarget(trailTexture); // 设置渲染目标为轨迹纹理
  renderer.render(scene, camera); // 渲染场景
  renderer.setRenderTarget(null); // 重置渲染目标
  const delta = clock.getDelta(); // 获取时间差，用于平滑动画
  // 旋转粒子系统
  if (particleSystem) {
    particleSystem.rotation.y += delta * 0.1; // 旋转速度
  }
  composer.render(); // 使用效果合成器渲染
}
</script>

<style scoped></style>
