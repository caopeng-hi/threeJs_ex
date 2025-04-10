<!--
 * @Author: caopeng
 * @Date: 2025-04-10 11:25:16
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-10 14:16:12
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
// 导入Vue组合式API
import { onMounted, onUnmounted, ref } from "vue";
let renderer,
  camera,
  controls,
  scene,
  composer,
  bloomPass,
  outputPass,
  renderPass;
let scale = 1.0;
let cubeTexture;
const canvasRef = ref(null);
const init = async () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();

  let cubeTexturePaths = generateCubeUrls("./img/", ".png");

  // 异步加载立方体贴图
  const cubeTextureLoader = new THREE.CubeTextureLoader();
  cubeTexture = cubeTextureLoader.load(cubeTexturePaths);

  scene.background = cubeTexture;
  scene.environment = cubeTexture;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 1, 14); // 适当拉远一点，能看到球体全貌
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;

  // 1. 创建球体几何
  const sphere = new THREE.SphereGeometry(4.5, 140, 140);
  let meshGeo = sphere;

  // 2. 创建材质
  const phyMat = new THREE.MeshPhysicalMaterial();
  phyMat.color = new THREE.Color(0x636363); // 初始颜色为灰色
  phyMat.metalness = 2.0; // 金属度(可以根据需求调试)
  phyMat.roughness = 0.0; // 粗糙度(越低越光滑)
  phyMat.side = THREE.DoubleSide; // 双面渲染

  // 3. 组合几何体和材质，生成网格
  let mesh = new THREE.Mesh(meshGeo, phyMat);
  scene.add(mesh);
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
onMounted(() => {
  init();
  animate();
});
// 定义一个函数，用来生成六张立方体纹理的路径
function generateCubeUrls(prefix, postfix) {
  return [
    prefix + "posx" + postfix,
    prefix + "negx" + postfix,
    prefix + "posy" + postfix,
    prefix + "negy" + postfix,
    prefix + "posz" + postfix,
    prefix + "negz" + postfix,
  ];
}
</script>
<style scoped></style>
