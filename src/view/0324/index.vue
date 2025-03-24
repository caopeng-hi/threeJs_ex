<template>
  <div ref="contentRef" class="content"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
const contentRef = ref(null);
let scene, camera, renderer, controls, clock;
let w = 500,
  h = 500;
let tiles = [];
let dummy = new THREE.Object3D();
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  // 增减辅助坐标轴
  const axesHelper = new THREE.AxesHelper(5);
  scene.add(axesHelper);

  camera = new THREE.PerspectiveCamera(75, w / h, 0.1, 1000);
  camera.position.set(40, 40, 40);
  camera.lookAt(scene.position);
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(w, h);
  contentRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
  //添加灯光
  let light = new THREE.PointLight(0xffffff);
  light.position.set(10, 10, 10);
  scene.add(light);
  // 增加物体
  new plane(-4, 0, 0, 0x444444);
  new plane(-8, 0, 4, 0x444444);
  new plane(-4, 0, 4);
  new plane(-8, 0, 0);
  // 增加obj
  let dummy = new THREE.Object3D();
  dummy.position.x = -6;
  dummy.position.y = 0.25;
  dummy.position.z = 2;
  scene.add(dummy);
  //修改obj材质和形状
  let geometry = new THREE.BoxGeometry(4, 4, 4);
  let material = new THREE.MeshLambertMaterial({
    color: 0x00fb9f,
    shading: THREE.NoShading,
    emissive: 0x444444,
  });
  geometry.applyMatrix4(new THREE.Matrix4().makeTranslation(-2, 2, 2));
  let cube = new THREE.Mesh(geometry, material);
  dummy.add(cube);
  dummy.rotation.x = Math.PI + Math.PI / 2;
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
};
function plane(x, y, z, color) {
  if (color == undefined) {
    color = 0x555555;
  }
  this.x = x;
  this.y = y;
  this.z = z;
  this.color = color;
  var geometry = new THREE.BoxGeometry(4, 1, 4);
  var material = new THREE.MeshLambertMaterial({
    color: 0xffffff,
    shading: THREE.NoShading,
    emissive: this.color,
  });
  geometry.applyMatrix4(
    new THREE.Matrix4().makeTranslation(this.x, this.y, this.z)
  );
  var tile = new THREE.Mesh(geometry, material);
  scene.add(tile);
  tiles.push(tile);
}
</script>

<style lang="scss" scoped>
.content {
  width: 100vw;
  height: 100vh;
  background: #222;
  overflow: hidden;
  position: relative;
  canvas {
    position: absolute;
    top: calc(50% - 250px);
    left: calc(50% - 250px);
  }
}
</style>
