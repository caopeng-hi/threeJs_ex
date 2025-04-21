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
let camera, scene, renderer, controls;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.z = 5;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
};
const animate = () => {
  requestAnimationFrame(animate);
  // 渲染场景和相机
  renderer.render(scene, camera);
  // 更新控制器
  controls.update();
};
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
