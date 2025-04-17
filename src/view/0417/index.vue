<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入gsap 库
import gsap from "gsap";
const canvasRef = ref(null);
let scene, camera, renderer, geometry, material, cube, controls;
const params = {
  color: "#00d5ff",
  stageColor: "#d4d4d4",
  ambientLight: "#ffffff",
  directionalLight: "#a4d5f4",
  currentIndex: 0,
  nextIndex: 1,
};
const uniforms = {
  uColor: new THREE.Uniform(new THREE.Color(params.color)),
  uTime: new THREE.Uniform(0),
  uProgress: new THREE.Uniform(0),
  uIndex: new THREE.Uniform(0),
  uCurrentIndex: new THREE.Uniform(params.currentIndex),
  uNextIndex: new THREE.Uniform(params.nextIndex),
  uMinY: new THREE.Uniform(0),
  uMaxY: new THREE.Uniform(0),
};
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
  camera.position.set(0, 4, -10);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  // 添加环境灯光
  const ambientLight = new THREE.AmbientLight(
    new THREE.Color(params.ambientLight),
    0.5
  );
  scene.add(ambientLight);
  // 添加平行光
  const dLight = new THREE.DirectionalLight(
    new THREE.Color(params.directionalLight),
    1.0
  );
  dLight.position.set(0, 3, 1);
  scene.add(dLight);
  // 添加点光源
  const pLight = new THREE.PointLight(new THREE.Color(params.color), 1, 10);
  pLight.position.set(0, -1.3, 0);
  scene.add(pLight);
  // 创建基础材质
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
