<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { RectAreaLightHelper } from "three/examples/jsm/helpers/RectAreaLightHelper";
const canvasRef = ref(null);
let scene, camera, renderer, controls;
const config = {
  text: "love",
  color: "#ef77eb",
  rain: {
    count: 1000,
    speed: 1.5,
    debug: false,
  },
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  THREE.ColorManagement.enabled = false;
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
  camera.position.set(0, 2, 9);
  const lookAt = new THREE.Vector3(0, 2, 0);
  camera.lookAt(lookAt);
  camera.updateMatrixWorld();
  scene.add(camera);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
  renderer.useLegacyLights = true;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.target = lookAt;
  // 添加控制器
  scene.add(controls);

  // 添加灯光
  const pointLight1 = new THREE.PointLight(config.color, 0.5, 17, 0.8);
  pointLight1.position.set(0, 2, 0);
  scene.add(pointLight1);

  const pointLight2 = new THREE.PointLight("#81C8F2", 2, 30);
  pointLight2.position.set(0, 25, 0);
  scene.add(pointLight2);

  // 矩形灯光
  const rectLight1 = new THREE.RectAreaLight("#89D7FF", 66, 19.1, 0.2);
  rectLight1.position.set(0, 8, -10);
  rectLight1.rotation.set(
    THREE.MathUtils.degToRad(90),
    THREE.MathUtils.degToRad(180),
    0
  );
  scene.add(rectLight1);
  // 添加矩形灯光辅助器
  const rectLightHelper = new RectAreaLightHelper(rectLight1);
  rectLight1.add(rectLightHelper);
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
