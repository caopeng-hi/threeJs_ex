<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入Vue组合式API
import { onMounted, onUnmounted, ref } from "vue";

// 创建一个ref来引用canvas元素
const canvasRef = ref(null);
let renderer, camera, controls, scene;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  // 创建一个透视相机，参数分别为视野角度，长宽比，相机离视锥体近面的距离，相机离视锥体远面的距离
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, 0, 100);
  // 创建一个渲染器，设置其背景色为白色
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setClearColor(0xffffff, 1.0); // 设置背景色为白色
  // 将渲染器的输出添加到页面上
  canvasRef.value.appendChild(renderer.domElement);
  // 创建一个控制器，用于控制相机的旋转、缩放和平移
  controls = new OrbitControls(camera, renderer.domElement);
  // 创建一个立方体几何体
  const geometry = new THREE.BoxGeometry();
  // 创建一个材质
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
  // 创建一个网格
  const cube = new THREE.Mesh(geometry, material);
  // 将网格添加到场景中
  scene.add(cube);
};
const animate = () => {
  requestAnimationFrame(animate);
  // 渲染场景
  renderer.render(scene, camera);
  // 更新控制器
  controls.update();
};
</script>
<style scoped></style>
