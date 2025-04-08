<!--
 * @Author: caopeng
 * @Date: 2025-04-08 09:15:55
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-08 10:52:37
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
import vertexModelShader from "../../shader/0408/vert.glsl?raw"; // 顶点着色器
import fragmentModelShader from "../../shader/0408/frag.glsl?raw"; // 片元着色器
import vertexFireShader from "../../shader/0408/vertFire.glsl?raw"; // 顶点着色器
import fragmentFireShader from "../../shader/0408/fragFire.glsl?raw"; // 片元着色器
import fragmentAshesShader from "../../shader/0408/fragAshes.glsl?raw"; // 片元着色器

// 导入RenderPass
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
// 导入UnrealBloomPass
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass";
// 导入OutputPass
import { OutputPass } from "three/examples/jsm/postprocessing/OutputPass";
// 导入EffectComposer
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";

// 导入glb-loader
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";
// 导入draco解码器
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader";

import { ref, onMounted } from "vue";
const canvasRef = ref(null);
let renderer,
  scene,
  camera,
  controls,
  composer,
  fireMat,
  ashesMat,
  floorMat,
  fireplaceMat;
let clock = new THREE.Clock(); // 创建一个时钟，用于计算时间差
let time = 0;
let deltaTime = 0;
let fireSpeed = 1;

onMounted(() => {
  init();
  animate();
});
const init = async () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);

  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    60,
    window.innerWidth / window.innerHeight,
    0.1,
    10
  );
  camera.position.set(0, 0.5, 1.5);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    preserveDrawingBuffer: true,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.toneMapping = THREE.LinearToneMapping;
  renderer.toneMappingExposure = 1;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.VSMShadowMap;
  renderer.localClippingEnabled = true;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.minDistance = 0;
  controls.maxDistance = 20;
  controls.enabled = true;
  controls.maxPolarAngle = Math.PI / 2 - 0.1;
  controls.target = new THREE.Vector3(0, 0.3, 0);

  const { fireplace, floor } = await createModel();
  scene.add(fireplace);
  scene.add(floor);

  const fire = await createFire(); // 创建火焰
  fireplace.add(fire); // 将火焰添加到火盆中

  const ashes = await createAshes(); // 创建灰烬
  fireplace.add(ashes); // 将灰烬添加到火盆中

  createPostProcessing(); // 创建后期处理
};
const animate = () => {
  deltaTime = clock.getDelta();
  time += deltaTime;
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
  if (composer) {
    composer.render();
  }
  if (fireMat && ashesMat) {
    updateFire();
  }
  if (floorMat && fireplaceMat) {
    updateLight();
  }
};
const loadModel = () => {
  return new Promise((resolve) => {
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
const createFire = async () => {
  const texture = await loadTexture();
  fireMat = new THREE.ShaderMaterial({
    uniforms: {
      noiseMap: { value: texture },
      time: { value: 0 },
      opacity: { value: 1 },
      intensity: { value: 1 },
      stylizeRatio: { value: 0.5 },
      stylizeThreshold: { value: 0.5 },
      grayscale: { type: "b", value: false },
      details: { value: 0.5 },
    },
    side: THREE.DoubleSide,
    transparent: false,
    blending: THREE.AdditiveBlending,
    vertexShader: vertexFireShader,
    fragmentShader: fragmentFireShader,
  });
  const fireGeom = new THREE.CylinderGeometry(
    0.03,
    0.2,
    0.35,
    15,
    15,
    true,
    -Math.PI / 2,
    Math.PI
  );
  fireGeom.applyMatrix4(new THREE.Matrix4().makeTranslation(0, 0.1, 0));
  const fire = new THREE.Mesh(fireGeom, fireMat);
  fire.position.set(0.1, -0.1, 0);
  fire.rotation.y = -Math.PI / 2;
  return fire;
};
const createAshes = async () => {
  ashesMat = new THREE.ShaderMaterial({
    uniforms: {
      noiseMap: { value: await loadTexture() },
      intensity: { value: 1 },
      time: { value: 0 },
    },
    side: THREE.DoubleSide,
    transparent: false,
    blending: THREE.MultiplyBlending,
    vertexShader: vertexFireShader,
    fragmentShader: fragmentAshesShader,
  });

  const ashesGeom = new THREE.CylinderGeometry(
    0.15,
    0.15,
    0.4,
    15,
    15,
    true,
    -Math.PI / 2,
    Math.PI
  );
  const ashes = new THREE.Mesh(ashesGeom, ashesMat);
  ashes.position.set(0.1, 0.1, 0);
  ashes.rotation.y = -Math.PI / 2;
  return ashes;
};
const createGUI = () => {};
const createPostProcessing = () => {
  const renderScene = new RenderPass(scene, camera);
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(1024, 1024),
    0.25,
    0.1,
    0.8
  );
  const outputPass = new OutputPass();
  composer = new EffectComposer(renderer);
  composer.addPass(renderScene);
  composer.addPass(bloomPass);
  composer.addPass(outputPass);
};
const updateFire = () => {
  fireMat.uniforms.time.value = time * fireSpeed;
  ashesMat.uniforms.time.value = time * fireSpeed;
};
const updateLight = () => {
  const r = Math.abs(Math.sin(time) + Math.cos(time * 4 + 0.1) * 0.5) * 0.2;
  const g =
    Math.abs(Math.sin(time + Math.PI / 2) + Math.cos(time * 4 + 1.4) * 0.5) *
    0.2;
  const b = Math.abs(Math.sin(time + Math.PI)) * 0.2;

  floorMat.uniforms.ratioR.value = 0.1 + r * 3;
  floorMat.uniforms.ratioG.value = 0.1 + g * 3;
  floorMat.uniforms.ratioB.value = 0.1 + b * 3;

  fireplaceMat.uniforms.ratioR.value = 0.0 + r * 1.5;
  fireplaceMat.uniforms.ratioG.value = 0.0 + g * 1.5;
  fireplaceMat.uniforms.ratioB.value = 0.0 + b * 1.5;
};
const createModel = async () => {
  // 加载模型
  const model = await loadModel();
  const fireplace = model.getObjectByName("fireplace");
  const fireplaceMap = fireplace.material.map;
  fireplaceMat = new THREE.ShaderMaterial({
    uniforms: {
      map: { value: fireplaceMap },
      ratioR: { value: 0.0 },
      ratioG: { value: 1.0 },
      ratioB: { value: 0.0 },
      gamma: { value: 1 },
    },
    vertexShader: vertexModelShader,
    fragmentShader: fragmentModelShader,
  });
  fireplace.material = fireplaceMat;

  // 加载地板
  const floor = model.getObjectByName("floor");
  const floorMap = floor.material.map;
  floorMat = fireplaceMat.clone();
  floorMat.uniforms.map.value = floorMap;
  floor.material = floorMat;

  return { fireplace, floor };
};
</script>
<style></style>
