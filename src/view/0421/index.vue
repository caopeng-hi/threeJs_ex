<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入着色器
import vertexShader from "../../shader/0421/vert.glsl?raw";
import fragmentShader from "../../shader/0421/frag.glsl?raw";
let canvasRef = ref(null);
let camera, scene, renderer, controls;
let uniforms = {
  u_time: { type: "f", value: 0.0 },
  u_resolution: { type: "v2", value: new THREE.Vector2() },
  u_mouse: { type: "v2", value: new THREE.Vector2() },
  u_complex: { type: "b", value: false },
};
onMounted(() => {
  init();
  animate();
  document.addEventListener("mouseup", onMouseUp, false);
  document.onmousemove = function (e) {
    uniforms.u_mouse.value.x = e.pageX;
    uniforms.u_mouse.value.y = e.pageY;
  };
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.z = 1;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建物体
  const geometry = new THREE.PlaneGeometry(2, 2);
  const material = new THREE.ShaderMaterial({
    uniforms: uniforms,
    vertexShader: document.getElementById("vertexShader").textContent,
    fragmentShader: document.getElementById("fragmentShader").textContent,
  });
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);
};
const animate = () => {
  requestAnimationFrame(animate);
  // 渲染场景和相机
  renderer.render(scene, camera);
  // 更新控制器
  controls.update();
  uniforms.u_time.value += 0.05 * (1 + uniforms.u_mouse.value.x / 200.0);
};
function onMouseUp() {
  uniforms.u_complex.value = !uniforms.u_complex.value;
}
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
