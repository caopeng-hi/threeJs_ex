<!--
 * @Author: caopeng
 * @Date: 2025-04-02 09:01:16
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-02 09:57:14
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import { ref, onMounted } from "vue";
// 导入轨道控制器（允许用户用鼠标交互控制场景）
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
const canvasRef = ref(null);
let scene, camera, renderer, controls; // 场景、相机、渲染器、控制器
let colors = ["#da6b00", "#8555d4", "#4ad3b5", "#ffffff"];
let radius = 5; // 圆的半径
let mouse = new THREE.Vector2(); // 鼠标位置
let canvasMouse = new THREE.Vector3(0, 0, 0); // 画布上的鼠标位置
let spheresInfo = {}; // 球的信息
let sphereIndex = 0; // 球的索引
let parent = new THREE.Object3D(); // 父对象
let floorDimensions = 350; // 地板尺寸
let floorLevel = -100; // 地板位置
let floor; // 地板
let dotsPerInterval;
let geometry, material; // 球的几何体和材质
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  // 添加辅助坐标轴
  //   const axesHelper = new THREE.AxesHelper(100); // 100表示坐标轴长度
  //   scene.add(axesHelper);
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.z = 600;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setClearColor("#4e4d70");
  canvasRef.value.appendChild(renderer.domElement);
  // 添加灯光
  const ambientLight = new THREE.AmbientLight("#ffffff", 0.5);
  scene.add(ambientLight);
  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);
  // 监听性能

  // 添加物体
  geometry = new THREE.BoxGeometry(floorDimensions, 5, floorDimensions);
  material = new THREE.MeshLambertMaterial({
    color: "#000000",
    depthWrite: false,
    transparent: true, // 开启透明
    opacity: 1, // 设置透明度
  });
  floor = new THREE.Mesh(geometry, material);
  floor.position.y = floorLevel - radius / 2;
  floor.position.z = 0;
  scene.add(floor);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
  initShaper();
};
const initShaper = () => {
  let i, j, k, ref, ref1, results, v;
  dotsPerInterval = 2;
  for (
    i = j = 0, ref = dotsPerInterval;
    0 <= ref ? j < ref : j > ref;
    i = 0 <= ref ? ++j : --j
  ) {
    initDot();
  }
  ref1 = spheresInfo;
  results = [];
  for (k in ref1) {
    v = ref1[k];
    results.push(drawDot(spheresInfo[k]));
  }
  return results;
};
const initDot = () => {
  let info = {};
  info.color = colors[random(0, 4)];
  info.radius = radius;
  info.radiusStart = info.radius;
  info.radiusDeincrement = info.radius * -0.002;
  info.startX = canvasMouse.x || 0;
  info.startY = canvasMouse.y || 100;
  info.startZ = canvasMouse.z || 0;
  if (info.startY < floorLevel - info.radiusStart / 2) {
    info.startY = floorLevel - info.radiusStart / 2;
  }
  info.isXNegative = random(1, 2);
  info.isZNegative = random(1, 2);
  info.vx =
    info.isXNegative === 1 ? random(0, 50) * -0.15 : random(0, 50) * 0.15;
  info.vxMult = random(10, 20) * 0.15;
  info.vy = random(-10, 20);
  info.vyMult = random(4, 6) * -0.1;
  info.vz =
    info.isZNegative === 1 ? random(-25, 25) * -0.4 : random(-25, 25) * 0.4;
  info.vzMult = random(10, 20) * 0.1;
  sphereIndex++;
  spheresInfo[sphereIndex] = info;
  info.ID = sphereIndex;
  info.bounced = false;
  info.startGravity = 1;
  info.gravity = info.startGravity;
  const geometry = new THREE.CircleGeometry(info.radius, 20);
  const material = new THREE.MeshBasicMaterial({ color: info.color });
  const sphere = new THREE.Mesh(geometry, material);
  scene.add(sphere);
  return (info.sphere = sphere);
};
const drawDot = (info) => {
  info.sphere.scale.x = info.sphere.scale.x += info.radiusDeincrement;
  info.sphere.scale.y = info.sphere.scale.y += info.radiusDeincrement;
  info.sphere.scale.z = info.sphere.scale.z += info.radiusDeincrement;
  info.sphere.position.x = info.startX += info.vx * 0.6;
  info.sphere.position.y = info.startY -= info.vy * 0.5;
  info.sphere.position.z = info.startZ -= info.vz * 0.6;
  if (info.sphere.position.y < floorLevel - info.radiusStart / 2) {
    if (!info.bounced) {
      info.vx *= info.vxMult;
      info.vz *= info.vzMult;
    } else {
      info.vx *= 0.95;
      info.vz *= 0.95;
    }
    if (
      !(
        info.sphere.position.x > floorDimensions / 2 ||
        info.sphere.position.x < -(floorDimensions / 2) ||
        info.sphere.position.z > floorDimensions / 2 ||
        info.sphere.position.z < -(floorDimensions / 2)
      )
    ) {
      info.vy *= info.vyMult;
      info.sphere.position.y =
        floorLevel + info.radiusStart * info.sphere.scale.x;
    } else {
      info.gravity = info.startGravity / 4;
      info.sphere.position.y =
        (info.startY -= info.vy * 0.01) +
        (20 - info.radiusStart * info.sphere.scale.x);
    }
    info.bounced = true;
  }
  info.vy += info.gravity;
  if (info.sphere.scale.y <= 0.1) {
    delete spheresInfo[info.ID];
    return scene.remove(info.sphere);
  }
};
const random = (min, max) => {
  return Math.floor(Math.random() * max) + min;
};
</script>
<style lang="scss" scoped></style>
