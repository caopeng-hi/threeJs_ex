<!--
 * @Author: caopeng
 * @Date: 2025-03-29 10:40:03
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-03-29 11:35:07
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import * as THREE from "three";
import { ref, onMounted } from "vue";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { EffectComposer, RenderPass } from "postprocessing";
import { GodraysPass } from "three-good-godrays";
import { GUI } from "three/examples/jsm/libs/lil-gui.module.min.js";
let scene, camera, renderer, controls, composer, gui, godraysPass, light;
const canvasRef = ref(null);

let params = {
  density: 0.01,
  gammaCorrection: true,
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // 添加辅助轴
  //   const axesHelper = new THREE.AxesHelper(10);
  //   scene.add(axesHelper);
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(5, 4, 15);
  camera.lookAt(0, 4, -2);
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);

  // 添加物体
  const frame = new THREE.Mesh(
    new THREE.BoxGeometry(10, 10, 1),
    new THREE.MeshStandardMaterial({ color: 0xffffff })
  );
  frame.position.set(0, 5, -6);
  frame.castShadow = true;
  scene.add(frame);

  // 栏杆（制造遮挡）
  for (let i = -3; i <= 3; i += 1.5) {
    const barMesh = new THREE.Mesh(
      new THREE.BoxGeometry(0.6, 8, 1),
      frame.material
    );
    barMesh.position.set(i, 4, -6);
    barMesh.castShadow = true;
    scene.add(barMesh);
  }

  // 地板
  const floor = new THREE.Mesh(
    new THREE.PlaneGeometry(20, 20),
    new THREE.MeshStandardMaterial({ color: 0x222222 })
  );
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = -1;
  floor.receiveShadow = true;
  scene.add(floor);

  // 墙面（后墙与左墙）
  const wallMaterial = new THREE.MeshStandardMaterial({ color: 0x111111 });

  const wallBack = new THREE.Mesh(
    new THREE.PlaneGeometry(20, 15),
    wallMaterial
  );
  wallBack.position.set(0, 5, -10);
  scene.add(wallBack);

  const wallLeft = new THREE.Mesh(
    new THREE.PlaneGeometry(20, 15),
    wallMaterial
  );
  wallLeft.position.set(-10, 5, 0);
  wallLeft.rotation.y = Math.PI / 2;
  scene.add(wallLeft);

  light = new THREE.DirectionalLight(0xffffff, 2);
  light.position.set(0, 12, -10);
  light.target.position.set(0, 4, 0);
  light.castShadow = true;
  scene.add(light);
  scene.add(light.target);

  light.shadow.mapSize.set(2048, 2048);
  light.shadow.camera.near = 0.5;
  light.shadow.camera.far = 50;

  const gui = new GUI();
  gui.add(params, "density", 0.0001, 0.02, 0.0001).onChange(updateGodrays);
  gui.add(params, "gammaCorrection").onChange(updateGodrays);

  composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));

  godraysPass = new GodraysPass(light, camera, {
    density: params.density,
    gammaCorrection: params.gammaCorrection,
  });
  godraysPass.renderToScreen = true;
  composer.addPass(godraysPass);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
  composer.render();
};
function updateGodrays() {
  composer.removePass(godraysPass);
  godraysPass = new GodraysPass(light, camera, {
    density: params.density,
    gammaCorrection: params.gammaCorrection,
  });
  godraysPass.renderToScreen = true;
  composer.addPass(godraysPass);
}
</script>
<style scoped></style>
