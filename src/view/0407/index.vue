<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入着色器
import vertexShader from "../../shader/0407/vert.glsl?raw"; // 顶点着色器
import fragmentShader from "../../shader/0407/frag.glsl?raw"; // 片元着色器
import { ref, onMounted } from "vue";
const canvasRef = ref(null);
let renderer, scene, camera, controls;
let texture;
let uniforms = {
  u_time: { type: "f", value: 1.0 },
  u_resolution: { type: "v2", value: new THREE.Vector2() },
  u_noise: { type: "t", value: texture },
  u_mouse: { type: "v2", value: new THREE.Vector2() },
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.z = 1;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  let loader = new THREE.TextureLoader(); // 加载纹理
  loader.setCrossOrigin("anonymous");
  loader.load(
    "https://s3-us-west-2.amazonaws.com/s.cdpn.io/982762/noise.png",
    function do_something_with_texture(tex) {
      texture = tex;
      texture.wrapS = THREE.RepeatWrapping;
      texture.wrapT = THREE.RepeatWrapping;
      texture.minFilter = THREE.LinearFilter;
    }
  );
  let geometry = new THREE.PlaneGeometry(2, 2);
  let material = new THREE.ShaderMaterial({
    uniforms: uniforms,
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
  });
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
</script>
<style></style>
