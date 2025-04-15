<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
let canvasRef = ref(null);
let scene, camera, renderer, controls;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  const bgColor = new THREE.Color(0.5, 0.5, 0.5); // 设置背景颜色
  scene.background = bgColor;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 0, 5);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
