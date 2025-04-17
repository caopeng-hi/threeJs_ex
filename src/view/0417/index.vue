<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
const canvasRef = ref(null);
let scene, camera, renderer, geometry, material, cube, controls;
onMounted(() => {
  init();
  animate();
});
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
  camera.position.z = 5;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建几何体
  geometry = new THREE.BoxGeometry();
  // 创建材质
  material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
  // 创建网格
  cube = new THREE.Mesh(geometry, material);
  // 将网格添加到场景中
  scene.add(cube);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
}
function animate() {
  // 旋转立方体
  cube.rotation.x += 0.01;
  cube.rotation.y += 0.01;
  // 渲染场景
  renderer.render(scene, camera);
  // 递归调用animate函数
  requestAnimationFrame(animate);
}
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
