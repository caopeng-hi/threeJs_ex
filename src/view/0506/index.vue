<!--
 * @Author: caopeng
 * @Date: 2025-05-06 11:43:36
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-05-06 17:44:59
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import anime from "animejs";
import { createNoise3D, createNoise4D } from "simplex-noise";
const canvasRef = ref(null); // 定义一个ref对象来引用canvas元素
let scene, camera, renderer, controls, clock; // 定义场景、相机、渲染器和控制器变量

onMounted(() => {
  init();
  animate();
});
// 初始化函数
function init() {
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
  renderer = new THREE.WebGLRenderer({ antialias: true }); // 开启抗锯齿
  renderer.setSize(window.innerWidth, window.innerHeight); // 设置渲染器大小
  // 将渲染器添加到canvas元素中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
}
function animate() {
  requestAnimationFrame(animate); // 循环调用animate函数
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
}
</script>

<style lang="scss" scoped></style>
