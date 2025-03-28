<!--
 * @Author: caopeng
 * @Date: 2025-03-28 10:00:29
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-03-28 10:12:03
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 引入后期处理
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass";
import { OutputPass } from "three/examples/jsm/postprocessing/OutputPass";

// 引入着色器
import vertexShader from "../../shader/0328/vert.glsl?raw"; // 顶点着色器
import fragmentShader from "../../shader/0328/frag.glsl?raw"; // 片段着色器

let scene, camera, renderer, controls;
const canvasRef = ref(null);
const uniforms = {
  u_time: { type: "f", value: 0.0 }, // 时间变量
  u_frequency: { type: "f", value: 0.0 }, // 音频频率
  u_red: { type: "f", value: 0.3 }, // 颜色 R 分量
  u_green: { type: "f", value: 1.0 }, // 颜色 G 分量
  u_blue: { type: "f", value: 0.6 }, // 颜色 B 分量
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, -2, 14);
  // 设置相机朝向场景中心
  camera.lookAt(0, 0, 0);
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建着色器材质
  const mat = new THREE.ShaderMaterial({
    uniforms,
    vertexShader,
    fragmentShader,
  }); // 创建二十面体几何体，用于雷达效果

  const geo = new THREE.IcosahedronGeometry(4, 30); // 创建网格并添加到场景
  const mesh = new THREE.Mesh(geo, mat);
  // 设置为线框模式
  mesh.material.wireframe = true;
  scene.add(mesh);

  //   // 创建渲染通道，用于后期处理
  //   const renderScene = new RenderPass(scene, camera);

  //   // 创建辉光通道，为场景添加发光效果
  //   const bloomPass = new UnrealBloomPass(
  //     new THREE.Vector2(window.innerWidth, window.innerHeight)
  //   );
  //   // 设置辉光阈值，只有亮度超过此值的像素才会发光
  //   bloomPass.threshold = 0.5;
  //   // 设置辉光强度
  //   bloomPass.strength = 0.5;
  //   // 设置辉光半径
  //   bloomPass.radius = 0.4;

  //   // 创建效果合成器，用于组合多个后期处理效果
  //   const bloomComposer = new EffectComposer(renderer);
  //   // 添加渲染通道
  //   bloomComposer.addPass(renderScene);
  //   // 添加辉光通道
  //   bloomComposer.addPass(bloomPass);

  //   // 创建输出通道，用于最终渲染结果的输出
  //   const outputPass = new OutputPass();
  //   bloomComposer.addPass(outputPass);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
</script>
<style scoped></style>
