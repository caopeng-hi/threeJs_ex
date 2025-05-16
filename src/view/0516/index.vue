<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three"; // 导入轨道控制器
let scene, camera, renderer, controls;
const canvasRef = ref(null);
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  // 1. 加载 HDR 环境贴图
  new THREE.RGBELoader().load("/img/tv_studio_small.hdr", (texture) => {
    // 2. 设置场景背景
    scene.background = texture;

    // 3. 设置环境光照
    scene.environment = texture;

    // 4. 模糊背景（需额外处理）
    texture.mapping = THREE.EquirectangularReflectionMapping;
    texture.minFilter = THREE.LinearFilter;
    texture.magFilter = THREE.LinearFilter;
    texture.generateMipmaps = false; // 禁用 mipmaps 以简化模糊
  });
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    35, // fov - 视野角度
    window.innerWidth / window.innerHeight, // 宽高比 - 通常设为窗口宽高比
    0.1, // near - 近裁剪面
    200 // far - 远裁剪面
  );
  // 设置相机位置
  camera.position.set(0, 0, 60);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  controls = new THREE.OrbitControls(camera, renderer.domElement);

  // 1. 创建平行光
  const directionalLight = new THREE.DirectionalLight(0xffffff, 4);
  directionalLight.position.set(2, 4, -2);

  // 2. 启用阴影
  directionalLight.castShadow = true;

  // 3. 设置阴影贴图分辨率
  directionalLight.shadow.mapSize.width = 512;
  directionalLight.shadow.mapSize.height = 512;

  // 4. 设置阴影偏移（避免阴影痤疮）
  directionalLight.shadow.bias = 0.0001;

  // 5. 配置阴影相机（正交相机）
  directionalLight.shadow.camera.near = 1;
  directionalLight.shadow.camera.far = 50;
  directionalLight.shadow.camera.left = -50;
  directionalLight.shadow.camera.right = 50;
  directionalLight.shadow.camera.top = 50;
  directionalLight.shadow.camera.bottom = -50;

  // 6. 将光源添加到场景
  scene.add(directionalLight);
};
const animate = () => {
  // 渲染场景和相机
  renderer.render(scene, camera);
  // 递归调用animate函数
  requestAnimationFrame(animate);
  controls.update();
};
</script>

<style lang="scss" scoped></style>
