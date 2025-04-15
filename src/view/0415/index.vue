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
let vector3 = new THREE.Vector3();
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
  controls.maxPolarAngle = Math.PI * 0.46;
  controls.minPolarAngle = 0.1;
  controls.minDistance = 4;
  controls.maxDistance = 15;
  controls.screenSpacePanning = false;
  controls.target.set(0.2, 0, 0.3);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;

  const pointLight = new THREE.SpotLight(0xffffff, 300.0, 0, 0.3, 1);
  pointLight.position.set(0, 15, 0);
  pointLight.castShadow = true;
  pointLight.shadow.autoUpdate = false;
  pointLight.shadow.bias = -0.0001;
  scene.add(pointLight);
  // 环境光
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  ambientLight.intensity = 1;
  ambientLight.name = "ambientLight";
  scene.add(ambientLight);

  // 创建物体
  const geometry = new THREE.BoxGeometry(2, 2, 2);
  const material = new THREE.MeshBasicMaterial({
    color: "yellow",
  });
  const cube = new Mesh(geometry, material);
  scene.add(cube);
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
