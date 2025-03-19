<!--
 * @Author: caopeng
 * @Date: 2025-03-19 14:58:09
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-03-19 17:42:51
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import * as THREE from "three";
import { onMounted, ref } from "vue";
// 引入控制轴
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";

// 引入片元着色器
import fragmentShader from "../../shader/0319/frag.glsl?raw";
// 顶点着色器
import vertexShader from "../../shader/0319/vert.glsl?raw";
const canvasRef = ref(null);
let scene, camera, renderer, controls;
onMounted(() => {
  initScene();
  animate();
});
const uni = {
  uTime: { value: 0 },
  uResolution: { value: new THREE.Vector2() },
};
const initScene = () => {
  scene = new THREE.Scene();
  camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建物体
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(2, 2),
    new THREE.ShaderMaterial({
      blending: THREE.AdditiveBlending,
      transparent: true,
      fragmentShader,
      vertexShader,
      uniforms: uni,
    })
  );
  scene.add(mesh);
};

const animate = () => {
  uni.uTime.value = performance.now() / 1000;
  uni.uResolution.value.set(window.innerWidth, window.innerHeight);
  renderer.render(scene, camera);
  controls.update();
  requestAnimationFrame(animate);
};
</script>

<style lang="scss" scoped>
.canvasRef {
  position: absolute;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
}
</style>
