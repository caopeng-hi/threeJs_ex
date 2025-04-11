<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three/webgpu";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入Vue组合式API
import { onMounted, onUnmounted, ref } from "vue";

// 创建一个ref来引用canvas元素
const canvasRef = ref(null);
let renderer, camera, controls, scene;
const uniforms = {
  uPointer: { value: new THREE.Vector2(0, 0) },
  uProgress: { value: 0 },
  tDepthMap: { value: null }, // 由外部传入的深度图
  tMap: { value: null }, // 由外部传入的主纹理
  uResolution: {
    value: new THREE.Vector2(window.innerWidth, window.innerHeight),
  },
  uAspect: { value: window.innerWidth / window.innerHeight },
  uStrength: { value: 0.01 },
};
onMounted(() => {
  init();
  animate();
});

const init = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, 0, 10);
  // 创建一个渲染器，设置其背景色为白色
  renderer = new THREE.WebGPURenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setClearColor(0xffffff, 1.0); // 设置背景色为白色
  // 将渲染器的输出添加到页面上
  canvasRef.value.appendChild(renderer.domElement);
  // 创建一个控制器，用于控制相机的旋转、缩放和平移
  controls = new OrbitControls(camera, renderer.domElement);

  // 加载平面贴图
  const textureLoader = new THREE.TextureLoader();
  const texture = textureLoader.load("/texture/raw-3.jpg");
  texture.colorSpace = THREE.SRGBColorSpace; // 设置纹理颜色空间为sRGB
  // 加载深度贴图
  const depthMap = textureLoader.load("/texture/depth-3.png");

  uniforms.tMap.value = texture; // 将纹理赋值给uniforms
  uniforms.tDepthMap.value = depthMap; // 将深度贴图赋值给uniforms

  const material = new THREE.ShaderMaterial({
    uniforms,
    vertexShader,
    fragmentShader,
  });
  const geometry = new THREE.PlaneGeometry(2, 2);
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);
};
const animate = async () => {
  requestAnimationFrame(animate);
  // 渲染场景
  await renderer.renderAsync(scene, camera);
  // 更新控制器
  controls.update();
};
</script>
<style scoped></style>
