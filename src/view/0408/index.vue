<!--
 * @Author: caopeng
 * @Date: 2025-04-08 09:15:55
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-08 09:17:41
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入着色器
import vertexShader from "../../shader/0407/vert.glsl?raw"; // 顶点着色器
import fragmentShader from "../../shader/0407/frag.glsl?raw"; // 片元着色器
import { ref, onMounted } from "vue";
const canvasRef = ref(null);
let renderer, scene, camera, controls, material;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xffffff);
  // 添加辅助坐标轴
  // const axesHelper = new THREE.AxesHelper(100);
  // scene.add(axesHelper);
  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 0, 10);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
</script>
<style></style>
