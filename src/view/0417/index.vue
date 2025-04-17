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
import vertexShader from "../../shader/0417/vert.glsl?raw";
import fragmentShader from "../../shader/0417/frag.glsl?raw";
// 导入gsap 库
import gsap from "gsap";
const canvasRef = ref(null);
let scene, camera, renderer, geometry, material, cube, controls, materials;
const clock = new THREE.Clock();
const params = {
  color: "#00d5ff",
  stageColor: "#d4d4d4",
  ambientLight: "#ffffff",
  directionalLight: "#a4d5f4",
  currentIndex: 0,
  nextIndex: 1,
};
const uniforms = {
  uColor: new THREE.Uniform(new THREE.Color(params.color)),
  uTime: new THREE.Uniform(0),
  uProgress: new THREE.Uniform(0),
  uIndex: new THREE.Uniform(0),
  uCurrentIndex: new THREE.Uniform(params.currentIndex),
  uNextIndex: new THREE.Uniform(params.nextIndex),
  uMinY: new THREE.Uniform(0),
  uMaxY: new THREE.Uniform(0),
};
onMounted(() => {
  init();
  animate();
});
function init() {
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
  camera.position.set(0, 4, -10);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  // 添加环境灯光
  const ambientLight = new THREE.AmbientLight(
    new THREE.Color(params.ambientLight),
    0.5
  );
  scene.add(ambientLight);
  // 添加平行光
  const dLight = new THREE.DirectionalLight(
    new THREE.Color(params.directionalLight),
    1.0
  );
  dLight.position.set(0, 3, 1);
  scene.add(dLight);
  // 添加点光源
  const pLight = new THREE.PointLight(new THREE.Color(params.color), 1, 10);
  pLight.position.set(0, -1.3, 0);
  scene.add(pLight);
  // 创建基础材质

  const baseMaterial = new THREE.ShaderMaterial({
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
    uniforms,
    transparent: true,
    blending: THREE.AdditiveBlending,
  });
  baseMaterial.depthWrite = false;
  // 创建物体
  const cylinder = new THREE.Mesh(
    new THREE.CylinderGeometry(2, 2, 0.5, 128),
    new THREE.MeshStandardMaterial({
      color: new THREE.Color(params.stageColor),
    })
  );
  cylinder.position.set(0, -2, 0);
  scene.add(cylinder);
  // 创建圆环
  const torusknotGeometry = new THREE.TorusKnotGeometry(1, 0.5, 128, 32);
  torusknotGeometry.computeBoundingBox(); // 计算几何体的包围盒
  const icosahedronGeometry = new THREE.IcosahedronGeometry(2, 24); // 创建一个IcosahedronGeometry
  icosahedronGeometry.computeBoundingBox(); // 计算几何体的包围盒
  const torusGeometry = new THREE.TorusGeometry(1.4, 0.5, 128, 32); // 创建一个TorusGeometry
  torusGeometry.computeBoundingBox(); // 计算几何体的包围盒

  // 计算所有几何体的最小和最大Y坐标
  const minY = Math.min(
    torusknotGeometry.boundingBox.min.y,
    icosahedronGeometry.boundingBox.min.y,
    torusGeometry.boundingBox.min.y
  );
  const maxY = Math.max(
    torusknotGeometry.boundingBox.max.y,
    icosahedronGeometry.boundingBox.max.y,
    torusGeometry.boundingBox.max.y
  );
  const margin = 0.1;
  const posY = 0.5;
  uniforms.uMinY.value = minY + posY - margin;
  uniforms.uMaxY.value = maxY + posY + margin;

  // 创建圆环结
  const torusKnotMaterial = baseMaterial.clone();
  torusKnotMaterial.uniforms.uIndex.value = 0;
  const torusKnot = new THREE.Mesh(torusknotGeometry, torusKnotMaterial);
  torusKnot.position.y = posY;
  scene.add(torusKnot);

  const icosahedronMaterial = baseMaterial.clone();
  icosahedronMaterial.uniforms.uIndex.value = 1;
  const icosahedron = new THREE.Mesh(icosahedronGeometry, icosahedronMaterial);
  icosahedron.position.y = posY;
  scene.add(icosahedron);

  const torusMaterial = baseMaterial.clone();
  torusMaterial.uniforms.uIndex.value = 2;
  const torus = new THREE.Mesh(torusGeometry, torusMaterial);
  torus.position.y = posY;
  scene.add(torus);

  materials = [torusKnotMaterial, icosahedronMaterial, torusMaterial];
}
function animate() {
  const delta = clock.getDelta();
  const elapsedTime = clock.getElapsedTime();
  const newIndex = Math.floor((elapsedTime * 0.25) % 3);
  if (newIndex !== params.currentIndex) {
    params.currentIndex = newIndex;
    params.nextIndex = newIndex === 2 ? 0 : newIndex + 1;
    materials.forEach((material) => {
      material.uniforms.uCurrentIndex.value = params.currentIndex;
      material.uniforms.uNextIndex.value = params.nextIndex;
      gsap.fromTo(
        material.uniforms.uProgress,
        { value: 0 },
        { value: 1, duration: 1.5, ease: "linear" }
      );
    });
  }
  torusKnot.rotation.y += delta * 0.5;
  torusKnot.rotation.x += delta * 0.5;
  torus.rotation.y += delta * 0.5;
  torus.rotation.x += delta * 0.5;

  torusMaterial.uniforms.uTime.value = elapsedTime;
  icosahedronMaterial.uniforms.uTime.value = elapsedTime;
  // 渲染场景
  renderer.render(scene, camera);
  // 递归调用animate函数
  requestAnimationFrame(animate);
}
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
