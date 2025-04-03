<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import { ref, onMounted, onBeforeUnmount } from "vue";
// 导入轨道控制器（允许用户用鼠标交互控制场景）
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";

// Vue ref引用，用于挂载Three.js渲染器DOM元素
const canvasRef = ref(null);
let renderer, scene, camera, controls;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    45, // 视场角
    window.innerWidth / window.innerHeight, // 宽高比
    0.1, // 近裁剪面
    1000 // 远裁剪面
  );
  // 设置相机位置
  camera.position.set(0, 0, 10);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true, // 抗锯齿
    alpha: true, // 透明背景
  });
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器DOM元素添加到Vue ref引用的DOM元素中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);
};
const animate = () => {
  // 渲染场景和相机
  renderer.render(scene, camera);
  // 循环调用animate函数
  requestAnimationFrame(animate);
  // 更新控制器
  controls.update();
};
</script>
<style></style>
