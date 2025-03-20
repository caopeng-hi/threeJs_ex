<!--
 * @Author: caopeng
 * @Date: 2025-03-20 11:32:41
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-03-20 15:26:48
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import * as THREE from "three";
import { onMounted, ref } from "vue";
// 引入控制器
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 引入gui
import { GUI } from "three/examples/jsm/libs/lil-gui.module.min.js";

const canvasRef = ref(null);
let scene, camera, renderer, controls;
let group = new THREE.Group();
var c1 = 255,
  c1S = 1,
  c2 = 255,
  c2S = 1,
  c3 = 255,
  c3S = 1; // 初始化
var shapes = [],
  perlin = new Noise(),
  iteration = 0,
  params = { speed: 1, perlinVariation: 0.3, perlinAmp: 2 };
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);

  // 添加环境光
  const light = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(light);
  camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = 5;
  renderer = new THREE.WebGLRenderer({
    alpha: false,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
  const count = 5000;
  for (let i = 0; i < count; i++) {
    const point = new Point(i);
    shapes.push(point);
    group.add(point.point);
  }
  scene.add(group);
  var gui;
  gui = new GUI();
  gui.add(params, "speed").min(0.1).max(2).step(0.1).name("Speed");
  gui
    .add(params, "perlinVariation")
    .min(0)
    .max(0.5)
    .step(0.0001)
    .name("Variation");
  gui.add(params, "perlinAmp").min(0).max(10).step(0.1).name("Amplification");
  gui.open();
};
const animate = () => {
  iteration++;
  changeColor();
  // 遍历group
  for (let i = 0; i < shapes.length; i++) {
    const point = shapes[i];
    point.move();
  }
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
// 构造类
class Point {
  id;
  point;
  speed;
  geometry;
  material;
  constructor(id) {
    this.id = id; // 粒子id
    this.speed = Math.floor(Math.random() * 100) / 100;
    this.geometry = new THREE.BufferGeometry();
    this.material = new THREE.PointsMaterial({
      size: 0.002,
      sizeAttenuation: true,
    });
    // 设置顶点数据
    const positions = new Float32Array([0, 0, 0]);
    this.geometry.setAttribute(
      "position",
      new THREE.BufferAttribute(positions, 3)
    );
    this.point = new THREE.Points(this.geometry, this.material);
    this.dist = 5;
    this.u = Math.random();
    this.v = Math.random();
    var theta = 2 * Math.PI * this.u; // 生成球面坐标
    var phi = Math.acos(2 * this.v - 1); // 生成球面坐标
    this.point.position.x = this.dist * Math.sin(phi) * Math.cos(theta); // 生成球面坐标
    this.point.position.y = this.dist * Math.sin(phi) * Math.sin(theta); // 生成球面坐标
    this.point.position.z = this.dist * Math.cos(phi); // 生成球面坐标
  }
  move() {
    this.dist =
      1.8 +
      perlin.perlin3(
        (iteration / 100) * params.speed,
        this.point.position.y * params.perlinVariation,
        this.point.position.z * params.perlinVariation
      ) *
        params.perlinAmp;
    var theta = 2 * Math.PI * this.u;
    var phi = Math.acos(2 * this.v - 1);
    this.point.position.x = this.dist * Math.sin(phi) * Math.cos(theta);
    this.point.position.y = this.dist * Math.sin(phi) * Math.sin(theta);
    this.point.position.z = this.dist * Math.cos(phi);
    this.point.material.color.setRGB(c1 / 255, c2 / 255, c3 / 255);
  }
}
function changeColor() {
  if (c1 <= 150 || c1 == 255) c1S *= -1;
  if (c2 <= 120 || c2 == 255) c2S *= -1;
  if (c3 <= 100 || c3 == 255) c3S *= -1;
  c1 += 1 * c1S;
  c2 += 1 * c2S;
  c3 += 1 * c3S;
}
</script>

<style lang="scss" scoped>
.canvasRef {
  position: absolute;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
}
</style>
