<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入Vue组合式API
import { onMounted, onUnmounted, ref } from "vue";
// 导入着色器
import vertexShader from "../../shader/0411/vert.glsl?raw";
import fragmentShader from "../../shader/0411/frag.glsl?raw";

// 创建一个ref来引用canvas元素
const canvasRef = ref(null);
let renderer, camera, controls, scene, material;
const uniforms = {
  uPointer: { value: new THREE.Vector2(0, 0) },
  uProgress: { value: 0 },
  tDepthMap: { value: null }, // 由外部传入的深度图
  tMap: { value: null }, // 由外部传入的主纹理
  uResolution: {
    value: new THREE.Vector2(window.innerWidth, window.innerHeight),
  },
  uAspect: { value: window.innerWidth / window.innerHeight },
  uStrength: { value: 0.01 },
};
onMounted(() => {
  init();
  animate();
  // 添加鼠标移动事件监听
  canvasRef.value.addEventListener("mousemove", onMouseMove);
});

const init = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xffffff);
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, 0, 10);
  // 创建一个渲染器，设置其背景色为白色
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setClearColor(0xffffff, 1.0); // 设置背景色为白色
  // 将渲染器的输出添加到页面上
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);

  const textureLoader = new THREE.TextureLoader();
  const texture = textureLoader.load("/texture/raw-3.jpg");
  texture.colorSpace = THREE.SRGBColorSpace;

  const depthMap = textureLoader.load("/texture/depth-3.png");

  uniforms.tMap.value = texture;
  uniforms.tDepthMap.value = depthMap;

  material = new THREE.ShaderMaterial({
    uniforms,
    vertexShader,
    fragmentShader,
  });
  const geometry = new THREE.PlaneGeometry(2, 2);

  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();

  // 使用sin函数实现平滑循环
  material.uniforms.uProgress.value = Math.sin(Date.now() * 0.001) * 0.5 + 0.5;
};
const onMouseMove = (e) => {
  material.uniforms.uPointer.value.set(
    (e.clientX / window.innerWidth) * 2 - 1,
    -(e.clientY / window.innerHeight) * 2 + 1
  );
};
</script>
<style scoped></style>
