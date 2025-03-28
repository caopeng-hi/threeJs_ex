<!--
 * @Author: caopeng
 * @Date: 2025-03-28 10:00:29
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-03-28 10:01:45
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
let scene, camera, renderer, controls;
const canvasRef = ref(null);
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
  camera.position.set(0, 0, 5);
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
};
</script>
<style scoped></style>
