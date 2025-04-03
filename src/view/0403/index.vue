<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import { ref, onMounted, onBeforeUnmount } from "vue";
// 导入轨道控制器（允许用户用鼠标交互控制场景）
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入着色器
import vertexShader from "../../shader/0403/vert.glsl?raw"; // 顶点着色器
import fragmentShader from "../../shader/0403/frag.glsl?raw"; // 片元着色器

// Vue ref引用，用于挂载Three.js渲染器DOM元素
const canvasRef = ref(null);
let renderer, scene, camera, controls;
let circle, particle, halo, luminor;
onMounted(() => {
  init();
  animate();
  window.addEventListener("resize", onWindowResize, false);
});
const init = () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    45, // 视场角
    window.innerWidth / window.innerHeight, // 宽高比
    0.1, // 近裁剪面
    1000 // 远裁剪面
  );
  // 设置相机位置
  camera.position.z = 400;
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true, // 抗锯齿
    alpha: true, // 透明背景
  });
  renderer.setPixelRatio(window.devicePixelRatio);
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.autoClear = false;
  renderer.setClearColor(0x000000, 0.0);
  // 将渲染器DOM元素添加到Vue ref引用的DOM元素中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);
  // 添加物体
  circle = new THREE.Object3D();
  particle = new THREE.Object3D();
  halo = new THREE.Object3D();
  luminor = new THREE.Object3D();

  scene.add(circle);
  scene.add(particle);
  scene.add(halo);
  scene.add(luminor);

  var geometry = new THREE.TetrahedronGeometry(1, 1);
  var geo_planet = new THREE.SphereGeometry(10, 64, 32);
  var geom3 = new THREE.SphereGeometry(16, 32, 16);
  var geo_star = new THREE.SphereGeometry(90, 64, 64);

  var material = new THREE.MeshPhongMaterial({
    color: 0x111111,
    shading: THREE.FlatShading,
  });

  for (var i = 0; i < 500; i++) {
    var mesh = new THREE.Mesh(geometry, material);
    mesh.position
      .set(Math.random() - 0.5, Math.random() - 0.5, Math.random() - 0.5)
      .normalize();
    mesh.position.multiplyScalar(200 + Math.random() * 500);
    mesh.rotation.set(Math.random() * 2, Math.random() * 2, Math.random() * 2);
    particle.add(mesh);
  }
  var mat = new THREE.MeshPhongMaterial({
    color: 0xe3d1af,
    emissive: 0x000000,
    shading: THREE.SmoothShading,
    map: new THREE.TextureLoader().load(
      "https://upload.wikimedia.org/wikipedia/commons/2/2c/Generic_Celestia_asteroid_texture.jpg"
    ),
    bumpMap: new THREE.TextureLoader().load(
      "https://upload.wikimedia.org/wikipedia/commons/2/2c/Generic_Celestia_asteroid_texture.jpg"
    ),
    bumpScale: 0.025,
    specularMap: new THREE.TextureLoader().load(
      "https://upload.wikimedia.org/wikipedia/commons/2/2c/Generic_Celestia_asteroid_texture.jpg"
    ),
    specular: new THREE.Color("grey"),
  });
  var mat3 = new THREE.ShaderMaterial({
    uniforms: {},
    vertexShader: document.getElementById("vertexShader").textContent,
    fragmentShader: document.getElementById("fragmentShader").textContent,
    side: THREE.BackSide,
    blending: THREE.AdditiveBlending,
    transparent: true,
  });
  var planet = new THREE.Mesh(geo_planet, mat);
  planet.scale.x = planet.scale.y = planet.scale.z = 15;
  circle.add(planet);

  var ball = new THREE.Mesh(geom3, mat3);
  ball.scale.x = ball.scale.y = ball.scale.z = 16;
  halo.add(ball);

  var ball2 = new THREE.Mesh(geom3, mat3);
  ball2.scale.x = ball2.scale.y = ball2.scale.z = 12;
  ball2.position.set(25, 5, 1);
  halo.add(ball2);

  var ambientLight = new THREE.AmbientLight(0x000000);
  scene.add(ambientLight);

  var hemiLight = new THREE.HemisphereLight(0x000000, 0x1111111, 20);
  hemiLight.position.set(-1, -1, 2);
  luminor.add(hemiLight);

  lights[1] = new THREE.DirectionalLight(0x000000, 7);
  lights[1].position.set(-1, 0, 0.5);
  lights[2] = new THREE.DirectionalLight(0x000000, 7);
  lights[2].position.set(1, 0, 0.5);

  scene.add(lights[1]);
  scene.add(lights[2]);
};
const animate = () => {
  var timer = 0.0001 * Date.now();
  particle.rotation.x += 0.0;
  particle.rotation.y -= 0.004;
  circle.rotation.x -= 0.001;
  circle.rotation.y -= 0.001;
  halo.rotation.z -= 0.005;
  luminor.rotation.z -= 0.005;
  renderer.clear();
  // 渲染场景和相机
  renderer.render(scene, camera);
  // 循环调用animate函数
  requestAnimationFrame(animate);
  // 更新控制器
  controls.update();
};
function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}
</script>
<style></style>
