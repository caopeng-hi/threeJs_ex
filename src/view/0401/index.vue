<!--
 * @Author: caopeng
 * @Date: 2025-04-01 09:05:52
 * @LastEditors: 
 * @LastEditTime: 2025-04-01 09:06:18
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import * as THREE from "three";
import { ref, onMounted } from "vue";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
let canvasRef = ref(null);
let scene, camera, renderer, controls;
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
  camera.position.z = 5;
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
</script>
<style></style>
