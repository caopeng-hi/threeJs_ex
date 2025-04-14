<!--
 * @Author: caopeng
 * @Date: 2025-04-14 10:57:51
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-14 11:04:03
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
let canvasRef = ref(null); // 定义一个ref引用，用于获取canvas元素
let scene = null; // 定义场景
let camera = null; // 定义相机
let renderer = null; // 定义渲染器
let controls = null; // 定义控制器
let cube = null; // 定义立方体
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  const bgColor = new THREE.Color(0.5, 0.5, 0.5); // 设置背景颜色
  scene.background = bgColor;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(15, 0, 15);
  camera.up.set(0, 0, 1);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器添加到canvasRef中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.screenSpacePanning = true; // 开启屏幕空间平移

  // 创建一个平面
  let squareGeometry = new THREE.PlaneGeometry(10, 10);
  let gray50 = new THREE.Color(0.5, 0.5, 0.5);
  let minusMaterial = new THREE.MeshBasicMaterial({
    color: gray50,
    blending: THREE.CustomBlending, // 设置混合模式
    blendEquation: THREE.ReverseSubtractEquation, // 设置混合方程
    blendSrc: THREE.SrcAlphaFactor, // 设置源因子
    blendDst: THREE.OneFactor, // 设置目标因子
    blendEquationAlpha: THREE.AddEquation, // 设置透明度混合方程
    depthTest: false, // 关闭深度测试
    depthWrite: false, // 关闭深度写入
    transparent: true, // 开启透明度
    side: THREE.DoubleSide, // 设置双面
  });
  let textureLoader = new THREE.TextureLoader();
  let texture = textureLoader.load("/texture/ripple.png");
  let plusMaterial = new THREE.MeshBasicMaterial({
    map: texture, // 设置纹理贴图
    blending: THREE.CustomBlending, // 设置混合模式
    blendEquation: THREE.AddEquation, // 设置混合方程
    blendSrc: THREE.SrcAlphaFactor, // 设置源因子
    blendDst: THREE.OneFactor, // 设置目标因子
    depthTest: false, // 关闭深度测试
    depthWrite: false, // 关闭深度写入
    transparent: true, // 开启透明度
    side: THREE.DoubleSide, // 设置双面
  });
  let ripples = [];
  let order = 0;
};
const animate = () => {
  requestAnimationFrame(animate);
  // 渲染场景和相机
  renderer.render(scene, camera);
  controls.update();
};
</script>
<style scoped></style>
