<!--
 * @Author: caopeng
 * @Date: 2025-04-01 09:05:52
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-01 09:17:31
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import * as THREE from "three";
import { ref, onMounted } from "vue";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import gsap from "gsap";
let canvasRef = ref(null);
let scene, camera, renderer, controls;
// 全局变量

// 纹理参数
const textureParams = {
  offsetX: 0,
  offsetY: 0,
  repeatX: 10,
  repeatY: 4,
};
// 相机抖动参数
const cameraShake = {
  x: 0,
  y: 0,
};
// 鼠标状态
const mouse = {
  position: new THREE.Vector2(0, 0),
  ratio: new THREE.Vector2(0, 0),
  target: new THREE.Vector2(0, 0),
};
onMounted(() => {
  mouse = {
    position: new THREE.Vector2(
      window.innerWidth * 0.5,
      window.innerHeight * 0.5
    ),
    ratio: new THREE.Vector2(0, 0),
    target: new THREE.Vector2(
      window.innerWidth * 0.5,
      window.innerHeight * 0.5
    ),
  };
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(
    15,
    window.innerWidth / window.innerHeight,
    0.01,
    1000
  );
  camera.rotation.y = Math.PI;
  camera.position.z = 0.35;
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);

  const points = [];
  for (let i = 0; i < 5; i++) {
    points.push(new THREE.Vector3(0, 0, 3 * (i / 4)));
  }
  points[4].y = -0.06;

  const curve = new THREE.CatmullRomCurve3(points);
  curve.type = "catmullrom";

  const tubeGeometry = new THREE.TubeGeometry(curve, 70, 0.02, 30, false);
  // 加载纹理
  const loader = new THREE.TextureLoader();
  loader.load("/img.jpg", function (texture) {
    const tubeMaterial = new THREE.MeshBasicMaterial({
      side: THREE.BackSide,
      map: texture,
    });
    tubeMaterial.map.wrapS = THREE.MirroredRepeatWrapping;
    tubeMaterial.map.wrapT = THREE.MirroredRepeatWrapping;
    tubeMaterial.map.repeat.set(10, 4); // textureParams.repeatX, textureParams.repeatY

    const tubeMesh = new THREE.Mesh(tubeGeometry, tubeMaterial);
    scene.add(tubeMesh);
  });
  const hyperSpace = gsap.timeline({ repeat: -1 });
  hyperSpace.to(textureParams, {
    duration: 4,
    repeatX: 0.3,
    ease: "power1.inOut",
  });
  hyperSpace.to(
    textureParams,
    {
      duration: 12,
      offsetX: 8,
      ease: "power2.inOut",
    },
    0
  );
  hyperSpace.to(
    textureParams,
    {
      duration: 6,
      repeatX: 10,
      ease: "power2.inOut",
    },
    "-=5"
  );
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
</script>
<style></style>
