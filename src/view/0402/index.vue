<!--
 * @Author: caopeng
 * @Date: 2025-04-02 09:01:16
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-02 09:24:06
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
let colors = ["#da6b00", "#8555d4", "#4ad3b5", "#ffffff"];
let radius = 5; // 圆的半径
let mouse = new THREE.Vector2(); // 鼠标位置
let canvasMouse = new THREE.Vector3(0, 0, 0); // 画布上的鼠标位置
let spheresInfo = {}; // 球的信息
let sphereIndex = 0; // 球的索引
let parent = new THREE.Object3D(); // 父对象
let floorDimensions = 350; // 地板尺寸
let floorLevel = -100; // 地板位置
let floor; // 地板
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.z = 600;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setClearColor("#4e4d70");
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  canvasRef.value.appendChild(renderer.domElement);
  // 添加灯光
  const ambientLight = new THREE.AmbientLight("#ffffff", 0.5);
  scene.add(ambientLight);
  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);
  // 监听性能

  // 添加物体
  const geometry = new THREE.BufferGeometry(
    floorDimensions,
    5,
    floorDimensions
  );
  const material = new THREE.MeshLambertMaterial({
    color: "#000000",
    depthWrite: false,
    transparent: true, // 开启透明
    opacity: 0.2, // 设置透明度
  });
  floor = new THREE.Mesh(geometry, material);
  floor.position.y = floorLevel - radius / 2;
  floor.position.z = 0;
  scene.add(floor);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
};
</script>
<style lang="scss" scoped></style>
