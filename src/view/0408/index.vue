<!--
 * @Author: caopeng
 * @Date: 2025-04-08 09:15:55
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-08 09:50:45
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
import vertexModelShader from "../../shader/0407/vert.glsl?raw"; // 顶点着色器
import fragmentModelShader from "../../shader/0407/frag.glsl?raw"; // 片元着色器
import vertexFireShader from "../../shader/0407/fire/vertFire.glsl?raw"; // 顶点着色器
import fragmentFireShader from "../../shader/0407/fire/fragFire.glsl?raw"; // 片元着色器

// 导入glb-loader
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";
// 导入draco解码器
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader";

import { ref, onMounted } from "vue";
const canvasRef = ref(null);
let renderer, scene, camera, controls;
let clock = new THREE.Clock(); // 创建一个时钟，用于计算时间差
let timer = 0;
let deltaTime = 0;
let fireSpeed = 1;
let stylize = false;

let fireUniforms = {
  map: { value: {} },
  ratioR: { value: 0.0 },
  ratioG: { value: 1.0 },
  ratioB: { value: 0.0 },
  gamma: { value: 1 },
};
onMounted(() => {
  init();
  animate();
});
const init = async () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // 添加辅助坐标轴
  const axesHelper = new THREE.AxesHelper(5);
  scene.add(axesHelper);

  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    60,
    window.innerWidth / window.innerHeight,
    0.1,
    10
  );
  camera.position.set(0, 0.5, 1.5);
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

  // 加载模型
  const model = await loadModel();
  const fireplace = model.getObjectByName("fireplace");
  fireUniforms.map.value.fireplaceMap = fireplace.material.map;
  const fireplaceMat = new THREE.ShaderMaterial({
    uniforms: fireUniforms,
    vertexShader: vertexModelShader,
    fragmentShader: fragmentModelShader,
  });
  fireplace.material = fireplaceMat;

  // 加载地板
  const floor = model.getObjectByName("floor");
  const floorMap = floor.material.map;
  const floorMat = fireplaceMat.clone();
  floorMat.uniforms.map.value = floorMap;
  floor.material = floorMat;
  console.log(fireplace, floor);

  scene.add(fireplace);
  scene.add(floor);
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
const loadModel = () => {
  return new Promise((resolve, reject) => {
    const loader = new GLTFLoader();
    const dracoLoader = new DRACOLoader();
    dracoLoader.setDecoderPath("./draco/");
    dracoLoader.setDecoderConfig({ type: "js" });
    loader.setDRACOLoader(dracoLoader);
    loader.load("/model/fireplace9.glb", (gltf) => {
      return resolve(gltf.scene);
    });
  });
};
const loadTexture = () => {
  const textureLoader = new THREE.TextureLoader();
  return new Promise((resolve) => {
    textureLoader.load("/texture/noise_1.jpg", (texture) => {
      texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
      resolve(texture);
    });
  });
};
const createFire = () => {
  const fireMat = new THREE.ShaderMaterial({
    uniforms: {
      noiseMap: { value: this.noiseTexture },
      time: { value: 0 },
      opacity: { value: 1 },
      intensity: { value: 1 },
      stylizeRatio: { value: 0.5 },
      stylizeThreshold: { value: 0.5 },
      grayscale: { type: "b", value: false },
      details: { value: 0.5 },
      side: THREE.DoubleSide,
      transparent: false,
      blending: THREE.AdditiveBlending,
      vertexShader: fireVert,
      fragmentShader: fireFrag,
    },
  });
};
</script>
<style></style>
