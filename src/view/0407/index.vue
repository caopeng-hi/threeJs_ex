<!--
 * @Author: caopeng
 * @Date: 2025-04-07 10:50:54
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-07 12:51:04
 * @Description: 请填写简介
-->
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
let renderer, scene, camera, controls, material;
let texture;
let uniforms = {
  u_time: { type: "f", value: 1.0 },
  u_resolution: { type: "v2", value: new THREE.Vector2() },
  u_noise: { type: "t", value: texture },
  u_mouse: { type: "v2", value: new THREE.Vector2() },
};
const clock = new THREE.Clock(); // 创建一个时钟，用于计算时间差
onMounted(() => {
  init();
  animate();
  document.addEventListener("pointermove", (e) => {
    let ratio = window.innerHeight / window.innerWidth;
    material.uniforms.u_mouse.value.x =
      (e.pageX - window.innerWidth / 2) / window.innerWidth / ratio;
    material.uniforms.u_mouse.value.y =
      ((e.pageY - window.innerHeight / 2) / window.innerHeight) * -1;
    e.preventDefault();
  });
});
const init = () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xffffff);
  // 添加辅助坐标轴
  // const axesHelper = new THREE.AxesHelper(100);
  // scene.add(axesHelper);

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

  const loader = new THREE.TextureLoader();
  loader.setCrossOrigin("anonymous");
  loader.load(
    "https://s3-us-west-2.amazonaws.com/s.cdpn.io/982762/noise.png",
    (tex) => {
      texture = tex;
      texture.wrapS = THREE.RepeatWrapping;
      texture.wrapT = THREE.RepeatWrapping;
      texture.minFilter = THREE.LinearFilter;

      // 更新uniforms中的纹理引用
      uniforms.u_noise.value = texture;
      // 初始化分辨率uniform
      uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight);
      // 创建材质和网格(确保纹理加载完成后再创建)
      material = new THREE.ShaderMaterial({
        uniforms: uniforms,
        vertexShader: vertexShader,
        fragmentShader: fragmentShader,
        side: THREE.DoubleSide, // 添加这一行确保双面渲染
      });
      material.extensions.derivatives = true;
      // 使用BufferGeometry而不是Geometry(更高效)
      let geometry = new THREE.PlaneGeometry(2, 2);
      let mesh = new THREE.Mesh(geometry, material);
      scene.add(mesh);
    }
  );
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);

  if (material) {
    const delta = clock.getDelta();
    material.uniforms.u_time.value = -10000 + delta * 0.0005;
  }
};
</script>
<style></style>
