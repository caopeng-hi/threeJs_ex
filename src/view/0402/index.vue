<!--
 * @Author: caopeng
 * @Date: 2025-04-02 09:01:16
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-02 09:06:30
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import { ref, onMounted } from "vue";
// 导入轨道控制器（允许用户用鼠标交互控制场景）
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
const canvasRef = ref(null);
let scene, camera, renderer, controls; // 场景、相机、渲染器、控制器
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
  camera.position.set(0, 0, 5);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
};
</script>
<style lang="scss" scoped></style>
