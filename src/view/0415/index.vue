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
  scene.background = new Color(0x000000);
  scene.background.setRGB(0.01, 0.005, 0.05);
  scene.backgroundBlurriness = 0.5;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    1,
    2000
  );
  camera.position.set(-2.95, 1.33, 3.91);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    canvas: container,
    antialias: true, //抗锯齿
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建物体
  const geometry = new THREE.BoxGeometry(2, 2, 2);
  const material = new THREE.MeshBasicMaterial({
    color: "yellow",
  });
  const cube = new Mesh(geometry, material);
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
