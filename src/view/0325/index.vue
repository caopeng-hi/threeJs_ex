<template>
  <div class="contentRef" ref="contentRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 引入着色器
import vertexShader from "../../shader/0325/vert.glsl?raw";
import fragmentShader from "../../shader/0325/frag.glsl?raw";

let scene, camera, renderer, controls;
const contentRef = ref(null);
let mouse = new THREE.Vector2();
let home, canvas, title;
let raycaster;
let clock;
let orbit;
let particles = {};
let imageParticlesSystem;
let planeHelperObject = new Array();
let particleCanvas = {
  width: 1500,
  height: 600,
};
let guiParams;
const uniforms = {
  uDuration: { type: "f", value: 180 },
  uElapsedTime: { type: "f", value: 0 },
  uSize: { type: "f", value: 3 },
  uNoise: { type: "f", value: 8 },
  uMousePosition: { type: "v2", value: new THREE.Vector2() },
  uMouseRadius: { type: "f", value: 100 },
  uMouseStrength: { type: "f", value: 0.75 },
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // const axesHelper = new THREE.AxesHelper(5);
  // scene.add(axesHelper);
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    10000
  );
  camera.position.set(0, 500, 550);
  renderer = new THREE.WebGLRenderer({ alpha: true, antialias: false });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  contentRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  //创建图片
  const data = getImage();
  particles.initPositions = new Array();
  particles.minPositions = new Array();
  particles.maxPositions = new Array();
  particles.noiseValues = new Array();
  particles.colors = new Array();

  for (var y = 0, y2 = data.height; y < y2; y++) {
    for (var x = 0, x2 = data.width; x < x2; x++) {
      if (data.data[x * 4 + y * 4 * data.width] > 128) {
        let maxZ = Math.random() * 2000 + (camera.position.z + 10);
        particles.initPositions.push(x);
        particles.initPositions.push(y);
        particles.initPositions.push(maxZ);
        particles.minPositions.push(x);
        particles.minPositions.push(y);
        particles.minPositions.push(0);
        particles.maxPositions.push(x);
        particles.maxPositions.push(y);
        particles.maxPositions.push(maxZ);
        let color = new THREE.Color(0x7f793f);
        particles.colors.push(color.r, color.g, color.b);
        let noiseX = Math.random() * 20 - 10;
        let noiseY = Math.random() * 20 - 10;
        particles.noiseValues.push(noiseX);
        particles.noiseValues.push(noiseY);
      }
    }
  }

  let planeHelperGeometry = new THREE.PlaneGeometry(10000, 10000);
  let planeHelperMaterial = new THREE.MeshBasicMaterial({
    color: 0x000000,
    transparent: true,
    opacity: 0,
  });
  let planeHelper = new THREE.Mesh(planeHelperGeometry, planeHelperMaterial);
  planeHelperObject.push(planeHelper);
  scene.add(planeHelper);

  let imageParticlesGeometry = new THREE.BufferGeometry();
  imageParticlesGeometry.setAttribute(
    "position",
    new THREE.Float32BufferAttribute(particles.initPositions, 3)
  );
  imageParticlesGeometry.setAttribute(
    "minPosition",
    new THREE.Float32BufferAttribute(particles.minPositions, 3)
  );
  imageParticlesGeometry.setAttribute(
    "maxPosition",
    new THREE.Float32BufferAttribute(particles.maxPositions, 3)
  );
  imageParticlesGeometry.setAttribute(
    "color",
    new THREE.Float32BufferAttribute(particles.colors, 3)
  );
  imageParticlesGeometry.setAttribute(
    "noiseValue",
    new THREE.Float32BufferAttribute(particles.noiseValues, 2)
  );
  imageParticlesGeometry.setAttribute(
    "mouseRepulsion",
    new THREE.Float32BufferAttribute(particles.mouseRepulsion, 1)
  );

  let imageParticlesMaterial = new THREE.ShaderMaterial({
    uniforms: uniforms,
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
  });

  imageParticlesSystem = new THREE.Points(
    imageParticlesGeometry,
    imageParticlesMaterial
  );
  imageParticlesSystem.position.x = (-1 * particleCanvas.width) / 2;
  imageParticlesSystem.position.y = (-1 * particleCanvas.height) / 2;

  scene.add(imageParticlesSystem);

  clock = new THREE.Clock();
  raycaster = new THREE.Raycaster();
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);

  var mouseX, mouseY;
  raycaster.setFromCamera(mouse, camera);
  var intersects;
  intersects = raycaster.intersectObjects(planeHelperObject, true);
  if (intersects.length > 0) {
    var intersection = intersects[0];
    mouseX = intersection.point.x + particleCanvas.width / 2;
    mouseY = intersection.point.y + particleCanvas.height / 2;
  }

  if (imageParticlesSystem.material.uniforms) {
    imageParticlesSystem.material.uniforms.uElapsedTime.value++;
    imageParticlesSystem.material.uniforms.uMousePosition.value.x = mouseX;
    imageParticlesSystem.material.uniforms.uMousePosition.value.y = mouseY;
  }
};
const getImage = () => {
  let coordinateCanvas = document.createElement("canvas");
  let ctx = coordinateCanvas.getContext("2d");
  coordinateCanvas.width = particleCanvas.width;
  coordinateCanvas.height = particleCanvas.height;
  ctx.translate(0, particleCanvas.height);
  ctx.scale(1, -1);

  ctx.font = "250pt Times New Roman";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillStyle = "#ffffff";
  ctx.fillText("404", coordinateCanvas.width / 2, coordinateCanvas.height / 2);

  const data = ctx.getImageData(
    0,
    0,
    coordinateCanvas.width,
    coordinateCanvas.height
  );
  ctx.clearRect(0, 0, coordinateCanvas.width, coordinateCanvas.height);
  return data;
};
</script>

<style lang="scss" scoped></style>
