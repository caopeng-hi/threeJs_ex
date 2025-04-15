<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入GLTFLoader和DRACOLoader
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
// 导入ReflectorForSSRPass
import { ReflectorForSSRPass } from "three/examples/jsm/objects/ReflectorForSSRPass";
import { SSRPass } from "three/examples/jsm/postprocessing/SSRPass";
let canvasRef = ref(null);
let scene, camera, renderer, controls;
let vector3 = new THREE.Vector3();
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  scene.background.setRGB(0.01, 0.005, 0.05);
  scene.backgroundBlurriness = 0.5;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    1,
    2000
  );
  camera.position.set(-2.95, 1.33, 3.91);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true, //抗锯齿
    alpha: true, //透明
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.maxPolarAngle = Math.PI * 0.46;
  controls.minPolarAngle = 0.1;
  controls.minDistance = 4;
  controls.maxDistance = 15;
  controls.screenSpacePanning = false;
  controls.target.set(0.2, 0, 0.3);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;

  const pointLight = new THREE.SpotLight(0xffffff, 300.0, 0, 0.3, 1);
  pointLight.position.set(0, 15, 0);
  pointLight.castShadow = true;
  pointLight.shadow.autoUpdate = false;
  pointLight.shadow.bias = -0.0001;
  scene.add(pointLight);
  // 环境光
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  ambientLight.intensity = 1;
  ambientLight.name = "ambientLight";
  scene.add(ambientLight);

  // 创建物体
  // const geometry = new THREE.BoxGeometry(2, 2, 2);
  // const material = new THREE.MeshBasicMaterial({
  //   color: "yellow",
  // });
  // const cube = new THREE.Mesh(geometry, material);
  // scene.add(cube);

  // 加载物体模型
  const gltfLoader = new GLTFLoader();
  const dracoLoader = new DRACOLoader();
  dracoLoader.setDecoderPath("./draco/");
  dracoLoader.setDecoderConfig({ type: "js" });
  gltfLoader.setDRACOLoader(dracoLoader);
  gltfLoader.load("/model/911-draco.glb", (glb) => {
    const carModel = glb.scene;
    carModel.name = "911";
    scene.add(carModel);
    carModel.position.y += 0.63;

    updateAllMaterials();
  });
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
const updateAllMaterials = () => {
  scene.getObjectByName("911").traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.castShadow = true;
      child.receiveShadow = true;
      child.material.envMap = scene.userData.dynamicMap;

      if (child.material.name === "rubber") {
        child.material.color.set("#222");
        child.material.roughness = 1;
        child.material.normalScale.set(4, 4);
        child.material.envMap = scene.userData.dynamicMap;
      }
      if (child.material.name === "window") {
        child.material.color.set("#222");
        child.material.roughness = 0;
        child.material.clearcoat = 0.1;
        child.material.envMap = scene.userData.dynamicMap;
      }
      if (child.material.name === "coat") {
        child.material.envMapIntensity = 4;
        child.material.roughness = 0.5;
        child.material.metalness = 1;
        child.material.envMap = scene.userData.dynamicMap;
      }
      if (child.material.name === "paint") {
        child.material.envMapIntensity = 2;
        child.material.roughness = 0.45;
        child.material.metalness = 0.8;
        child.material.envMap = scene.userData.dynamicMap;
        child.material.color.set("#b3b3ff");
      }
    }
  });

  // 更新阴影
  scene.getObjectByProperty("type", "SpotLight").shadow.needsUpdate = true;
};
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
