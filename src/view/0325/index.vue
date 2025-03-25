<template>
  <div class="contentRef" ref="contentRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 引入着色器
import vertexShader from "../../shader/0325/vert.glsl?raw";
import fragmentShader from "../../shader/0325/frag.glsl?raw";

let scene, camera, renderer, controls;
const contentRef = ref(null);
let mouse = new THREE.Vector2();
let home, canvas, title;
let raycaster;
let clock;
let orbit;
let particles = {};
let imageParticlesSystem;
let planeHelperObject = new Array();
let particlesMesh;
let particleCanvas = {
  width: 500,
  height: 300,
};
let guiParams;
const uniforms = {
  uDuration: { type: "f", value: 180 },
  uElapsedTime: { type: "f", value: 0 },
  uSize: { type: "f", value: 3 },
  uNoise: { type: "f", value: 8 },
  uMousePosition: { type: "v2", value: new THREE.Vector2() },
  uMouseRadius: { type: "f", value: 100 },
  uMouseStrength: { type: "f", value: 0.75 },
};

// 新增：存储粒子的目标位置
let targetPositions;
// 新增：动画持续时间（毫秒）
const animationDuration = 10000;

onMounted(() => {
  init();
  animate();
});

const init = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 0, 75);
  renderer = new THREE.WebGLRenderer({ alpha: true, antialias: false });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  contentRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  const data = getImage();

  const particlesGeometry = new THREE.BufferGeometry();
  const particlesCnt = particleCanvas.width * particleCanvas.height;
  const posArray = new Float32Array(particlesCnt * 3);
  const colorArray = new Float32Array(particlesCnt * 3);
  const sizeArray = new Float32Array(particlesCnt);
  // 新增：存储粒子的目标位置
  targetPositions = new Float32Array(particlesCnt * 3);

  for (let i = 0; i < particlesCnt; i++) {
    const x = i % particleCanvas.width;
    const y = Math.floor(i / particleCanvas.width);
    const pixelIndex = y * (particleCanvas.width * 4) + x * 4;
    if (data[pixelIndex + 3] === 0) continue;

    // 目标位置
    targetPositions[i * 3] = (x - particleCanvas.width / 2) * 0.1;
    targetPositions[i * 3 + 1] = (y - particleCanvas.height / 2) * 0.1;
    targetPositions[i * 3 + 2] = Math.random() * 10 - 5;

    // 初始随机位置
    posArray[i * 3] = (Math.random() - 0.5) * 100;
    posArray[i * 3 + 1] = (Math.random() - 0.5) * 100;
    posArray[i * 3 + 2] = (Math.random() - 0.5) * 100;

    colorArray[i * 3] = data[pixelIndex] / 255;
    colorArray[i * 3 + 1] = data[pixelIndex + 1] / 255;
    colorArray[i * 3 + 2] = data[pixelIndex + 2] / 255;

    const brightness =
      (data[pixelIndex] + data[pixelIndex + 1] + data[pixelIndex + 2]) /
      (3 * 255);
    sizeArray[i] = brightness * 0.8;
  }

  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(posArray, 3)
  );
  particlesGeometry.setAttribute(
    "color",
    new THREE.BufferAttribute(colorArray, 3)
  );
  particlesGeometry.setAttribute(
    "size",
    new THREE.BufferAttribute(sizeArray, 1)
  );

  const particlesMaterial = new THREE.PointsMaterial({
    size: 0.1,
    vertexColors: true,
    transparent: true,
    opacity: 0.9,
    blending: THREE.AdditiveBlending,
    sizeAttenuation: true,
  });

  particlesMesh = new THREE.Points(particlesGeometry, particlesMaterial);

  scene.add(particlesMesh);
  clock = new THREE.Clock();
  raycaster = new THREE.Raycaster();
};

const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);

  const elapsedTime = clock.getElapsedTime() * 1000;
  let t = Math.min(elapsedTime / animationDuration, 1);
  t = t * (1 - t);

  if (particlesMesh && particlesMesh.geometry.attributes.position) {
    const positions = particlesMesh.geometry.attributes.position.array;
    for (let i = 0; i < positions.length; i++) {
      positions[i] = positions[i] + (targetPositions[i] - positions[i]) * t;
    }
    particlesMesh.geometry.attributes.position.needsUpdate = true;
  }
};

const getImage = () => {
  let coordinateCanvas = document.createElement("canvas");
  let ctx = coordinateCanvas.getContext("2d");
  coordinateCanvas.width = particleCanvas.width;
  coordinateCanvas.height = particleCanvas.height;
  ctx.translate(0, particleCanvas.height);
  ctx.scale(1, -1);
  ctx.font = "250pt Times New Roman";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillStyle = "#ffffff";
  ctx.fillText("404", coordinateCanvas.width / 2, coordinateCanvas.height / 2);

  const data = ctx.getImageData(
    0,
    0,
    coordinateCanvas.width,
    coordinateCanvas.height
  );
  ctx.clearRect(0, 0, coordinateCanvas.width, coordinateCanvas.height);
  return data.data;
};
</script>

<style lang="scss" scoped></style>
