<!--
 * @Author: caopeng
 * @Date: 2025-03-28 10:00:29
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-03-28 10:32:06
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

let scene, camera, renderer, controls, bloomComposer, analyser, sound;
let clock = new THREE.Clock();
// 加载音频文件
let audioLoaded = false;
let audioBuffer = null;
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
  document.addEventListener("click", function () {
    if (audioLoaded && !sound.isPlaying) {
      tryPlayAudio();
    }
  });
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

  // 创建音频监听器
  const listener = new THREE.AudioListener();
  camera.add(listener);

  // 创建音频对象
  sound = new THREE.Audio(listener);

  // 创建音频加载器
  const audioLoader = new THREE.AudioLoader();

  // 加载音频文件
  audioLoader.load("/2293934203.mp3", function (buffer) {
    console.log("音频加载完成");
    audioBuffer = buffer;
    audioLoaded = true;
  });
  // 创建音频分析器，用于获取音频频率数据
  analyser = new THREE.AudioAnalyser(sound, 32);
  // 创建渲染通道，用于后期处理
  const renderScene = new RenderPass(scene, camera);

  // 创建辉光通道，为场景添加发光效果
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight)
  );
  // 设置辉光阈值，只有亮度超过此值的像素才会发光
  bloomPass.threshold = 0.5;
  // 设置辉光强度
  bloomPass.strength = 0.5;
  // 设置辉光半径
  bloomPass.radius = 0.4;

  // 创建效果合成器，用于组合多个后期处理效果
  bloomComposer = new EffectComposer(renderer);
  // 添加渲染通道
  bloomComposer.addPass(renderScene);
  // 添加辉光通道
  bloomComposer.addPass(bloomPass);
  // 创建输出通道，用于最终渲染结果的输出
  const outputPass = new OutputPass();
  bloomComposer.addPass(outputPass);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
  bloomComposer.render();

  // 更新时间变量
  uniforms.u_time.value = clock.getElapsedTime();

  // 确保音频分析器已初始化且音频正在播放

  if (sound && sound.isPlaying && analyser) {
    // 获取频率数据并添加平滑处理
    const frequency = analyser.getAverageFrequency();
    // 对频率值进行归一化处理 (0-1范围)
    uniforms.u_frequency.value = Math.min(frequency / 255, 1.0);
  } else {
    // 如果没有音频播放，设置基础值
    uniforms.u_frequency.value = 0.01;
  }
};
function tryPlayAudio() {
  if (!audioLoaded) return;
  try {
    sound.setBuffer(audioBuffer);
    sound.setLoop(true);
    sound.play();
    console.log("音频开始播放");
  } catch (error) {
    console.error("音频播放失败:", error);
  }
}
</script>
<style scoped></style>
