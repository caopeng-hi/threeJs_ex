<template>
  <div ref="contentRef" class="content"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
const contentRef = ref(null);
let scene, camera, renderer, controls, clock;

let tiles = [];
let dummy = new THREE.Object3D();
let bk = false;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(40, 40, 40);
  camera.lookAt(scene.position);
  renderer = new THREE.WebGLRenderer({
    alpha: true,
    antialias: true,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
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

  dummy.position.x = -6;
  dummy.position.y = 0.25;
  dummy.position.z = 2;
  scene.add(dummy);
  //修改obj材质和形状
  let geometry = new THREE.BoxGeometry(4, 4, 4);
  let material = new THREE.MeshLambertMaterial({
    color: 0x00fb9f,
  });
  geometry.applyMatrix4(new THREE.Matrix4().makeTranslation(-2, 2, 2));
  let cube = new THREE.Mesh(geometry, material);
  dummy.add(cube);
  dummy.rotation.x = Math.PI + Math.PI / 2;
};
const animate = () => {
  requestAnimationFrame(animate);
  if (dummy.rotation.x >= Math.PI * 2 || bk == true) {
    if (dummy.rotation.z <= -(Math.PI / 2)) {
      bk = true;
      if (dummy.rotation.x <= Math.PI + Math.PI / 2) {
        if (dummy.rotation.y <= -(Math.PI / 2)) {
          bk = false;
          dummy.rotation.x = Math.PI + Math.PI / 2;
          dummy.rotation.y = 0;
          dummy.rotation.z = 0;
        } else {
          dummy.rotation.y -= 0.1;
        }
      } else {
        dummy.rotation.x -= 0.1;
      }
    } else {
      dummy.rotation.z -= 0.1;
    }
  } else {
    if (bk == true) {
    } else {
      dummy.rotation.x += 0.1;
    }
  }
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
    flatShading: true,
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
}
</style>
