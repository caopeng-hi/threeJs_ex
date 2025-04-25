<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { RectAreaLightHelper } from "three/examples/jsm/helpers/RectAreaLightHelper";
import { FontLoader } from "three/addons/loaders/FontLoader.js";
import { TextGeometry } from "three/addons/geometries/TextGeometry.js";
const canvasRef = ref(null);
let scene, camera, renderer, controls;
const config = {
  text: "love",
  color: "#ef77eb",
  rain: {
    count: 1000,
    speed: 1.5,
    debug: false,
  },
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  THREE.ColorManagement.enabled = false;
  // 创建场景
  scene = new THREE.Scene();
  // 添加颜色
  scene.background = new THREE.Color("#ffffff");
  // 添加坐标轴辅助器
  const axesHelper = new THREE.AxesHelper(5);
  scene.add(axesHelper);
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, 2, 9);
  const lookAt = new THREE.Vector3(0, 2, 0);
  camera.lookAt(lookAt);
  camera.updateMatrixWorld();
  scene.add(camera);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
  renderer.useLegacyLights = true;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.target = lookAt;

  // 添加灯光
  const pointLight1 = new THREE.PointLight(config.color, 0.5, 17, 0.8);
  pointLight1.position.set(0, 2, 0);
  scene.add(pointLight1);

  const pointLight2 = new THREE.PointLight("#81C8F2", 2, 30);
  pointLight2.position.set(0, 25, 0);
  scene.add(pointLight2);

  // 矩形灯光
  const rectLight1 = new THREE.RectAreaLight("#89D7FF", 66, 19.1, 0.2);
  rectLight1.position.set(0, 8, -10);
  rectLight1.rotation.set(
    THREE.MathUtils.degToRad(90),
    THREE.MathUtils.degToRad(180),
    0
  );
  scene.add(rectLight1);
  // 添加矩形灯光辅助器
  const rectLightHelper = new RectAreaLightHelper(rectLight1);
  rectLight1.add(rectLightHelper);

  // 添加贴图图片
  const textureLoader = new THREE.TextureLoader();
  const aspTex = textureLoader.load("/texture/0425/asphalt-normal.jpg");
  aspTex.rotation = THREE.MathUtils.degToRad(90);
  aspTex.wrapS = aspTex.wrapT = THREE.RepeatWrapping;
  aspTex.repeat.set(5, 8);
  // 添加地面
  const wallMat = new THREE.MeshPhongMaterial({
    color: new THREE.Color("#111111"),
    normalMap: aspTex,
    normalScale: new THREE.Vector2(0.5, 0.5),
    shininess: 200,
  });
  const wall = new THREE.Mesh(new THREE.BoxGeometry(25, 20, 0.5), wallMat);
  scene.add(wall);
  wall.position.y = 10;
  wall.position.z = -10.3;

  const wall2 = new THREE.Mesh(new THREE.BoxGeometry(0.5, 20, 20), wallMat);
  scene.add(wall2);
  wall2.position.y = 10;
  wall2.position.x = -12;

  const wall3 = new THREE.Mesh(new THREE.BoxGeometry(0.5, 20, 20), wallMat);
  scene.add(wall3);
  wall3.position.y = 10;
  wall3.position.x = 12;

  // text3D加载器
  const loader = new FontLoader();
  loader.load("/font/Source_Han_Sans_CN_Regular_Regular.json", (font) => {
    const geometry = new TextGeometry(config.text, {
      font: font,
      size: 3,
      height: 0.2,
      curveSegments: 120,
      bevelEnabled: false,
    });
    geometry.center(); // 居中
    const material = new THREE.MeshBasicMaterial({
      color: config.color,
    });
    const text = new THREE.Mesh(geometry, material);
    scene.add(text);
    text.position.y = 1.54;
  });

  // 创建雨地面
  // 加载地面纹理
  const fNormalTex = textureLoader.load("/texture/0425/floor-normal.jpg");
  const fOpacityTex = textureLoader.load("/texture/0425/floor-opacity.jpg");
  const fRoughnessTex = textureLoader.load("/texture/0425/floor-roughness.jpg");
  fNormalTex.wrapS = fNormalTex.wrapT = THREE.MirroredRepeatWrapping;
  fOpacityTex.wrapS = fOpacityTex.wrapT = THREE.MirroredRepeatWrapping;
  fRoughnessTex.wrapS = fRoughnessTex.wrapT = THREE.MirroredRepeatWrapping;

  // custom reflector
  const plan = new THREE.PlaneGeometry(25, 100);
  // 反射镜面
  const mirror = new THREE.Mesh(plan, []);
  mirror.position.z = -25;
  mirror.rotation.x = -Math.PI / 2;
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
