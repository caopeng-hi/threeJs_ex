<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
const canvasRef = ref(null);

let scene, camera, renderer, controls;

onMounted(() => {
  initScene();
  animate();
});
function initScene() {
  // 创建场景
  scene = new THREE.Scene();
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = 5; // 设置相机的位置

  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement); // 将渲染器的 DOM 元素添加到 canvasRef 中

  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true; // 启用阻尼
  controls.dampingFactor = 0.25; // 设置阻尼因子
  controls.screenSpacePanning = false; // 禁用屏幕空间平移
  controls.minDistance = 0.1; // 设置最小距离
  controls.maxDistance = 10; // 设置最大距离
  controls.maxPolarAngle = Math.PI / 2; // 设置最大极角

  // 创建光源
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5); // 环境光
  scene.add(ambientLight);
}
function animate() {
  requestAnimationFrame(animate);
  controls.update(); // 更新控制器
  renderer.render(scene, camera); // 渲染场景和相机
}
</script>

<style scoped></style>
