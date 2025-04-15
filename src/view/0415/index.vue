<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入GLTFLoader和DRACOLoader
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
// 导入ReflectorForSSRPass
import { ReflectorForSSRPass } from "three/examples/jsm/objects/ReflectorForSSRPass";
import { SSRPass } from "three/examples/jsm/postprocessing/SSRPass";
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
import { OutputPass } from "three/examples/jsm/postprocessing/OutputPass";
import { ShaderPass } from "three/examples/jsm/postprocessing/ShaderPass";
import { FXAAShader } from "three/examples/jsm/shaders/FXAAShader";
let canvasRef = ref(null);
const clock = new THREE.Clock();
let previousTime = 0;
let scene,
  camera,
  renderer,
  controls,
  composer,
  ssrPass,
  renderTarget,
  rtCubeCamera;
let vector3 = new THREE.Vector3();
const parameters = {
  bloomStrength: 0.3,
  bloomThreshold: 0.1,
  bloomRadius: 0.6,
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  scene.background.setRGB(0.01, 0.005, 0.05);
  scene.backgroundBlurriness = 0.5;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    1,
    2000
  );
  camera.position.set(-2.95, 1.33, 3.91);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true, //抗锯齿
    alpha: true, //透明
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  renderTarget = new THREE.WebGLCubeRenderTarget(256);
  renderTarget.texture.type = THREE.HalfFloatType;

  rtCubeCamera = new THREE.CubeCamera(1, 1000, renderTarget);
  rtCubeCamera.layers.set(1);
  scene.userData.rtCubeCameraLayer = 1;
  scene.userData.dynamicMap = renderTarget.texture;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.maxPolarAngle = Math.PI * 0.46;
  controls.minPolarAngle = 0.1;
  controls.minDistance = 4;
  controls.maxDistance = 15;
  controls.screenSpacePanning = false;
  controls.target.set(0.2, 0, 0.3);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;

  const pointLight = new THREE.SpotLight(0xffffff, 300.0, 0, 0.3, 1);
  pointLight.position.set(0, 15, 0);
  pointLight.castShadow = true;
  pointLight.shadow.autoUpdate = false;
  pointLight.shadow.bias = -0.0001;
  scene.add(pointLight);
  // 环境光
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  ambientLight.intensity = 1;
  ambientLight.name = "ambientLight";
  scene.add(ambientLight);
  createDynamicEnv();
  // 创建物体
  // const geometry = new THREE.BoxGeometry(2, 2, 2);
  // const material = new THREE.MeshBasicMaterial({
  //   color: "yellow",
  // });
  // const cube = new THREE.Mesh(geometry, material);
  // scene.add(cube);
  //  -----> 加载纹理
  const cubeTextureLoader = new THREE.CubeTextureLoader();
  const envMap = cubeTextureLoader.load([
    "/texture/px.png",
    "/texture/nx.png",
    "/texture/py.png",
    "/texture/ny.png",
    "/texture/pz.png",
    "/texture/nz.png",
  ]);
  envMap.mapping = THREE.CubeRefractionMapping;
  const textureLoader = new THREE.TextureLoader();
  let skyTextureEquirec = textureLoader.load(
    import.meta.env.BASE_URL + "texture/envmap/room.png"
  );
  skyTextureEquirec.mapping = THREE.EquirectangularReflectionMapping;
  skyTextureEquirec.colorSpace = THREE.SRGBColorSpace;
  // 加载物体模型
  const gltfLoader = new GLTFLoader();
  const dracoLoader = new DRACOLoader();
  dracoLoader.setDecoderPath("./draco/");
  dracoLoader.setDecoderConfig({ type: "js" });
  gltfLoader.setDRACOLoader(dracoLoader);
  gltfLoader.load("/model/911-draco.glb", (glb) => {
    const carModel = glb.scene;
    carModel.name = "911";
    scene.add(carModel);
    carModel.position.y += 0.63;

    updateAllMaterials();
  });

  //  后期渲染
  const renderScene = new RenderPass(scene, camera);
  // 辉光处理通道
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    1.5,
    0.4,
    0.85
  );
  bloomPass.threshold = parameters.bloomThreshold;
  bloomPass.strength = parameters.bloomStrength;
  bloomPass.radius = parameters.bloomRadius;
  // 抗锯齿处理通道
  const fxaaPass = new ShaderPass(FXAAShader);
  const pixelRatio = renderer.getPixelRatio();
  fxaaPass.material.uniforms["resolution"].value.x =
    1 / (window.innerWidth * pixelRatio);
  fxaaPass.material.uniforms["resolution"].value.y =
    1 / (window.innerHeight * pixelRatio);
  ssrPass = new SSRPass({
    renderer,
    scene,
    camera,
    width: innerWidth,
    height: innerHeight,
    groundReflector: null,
    selects: [],
  });
  const outputPass = new OutputPass();
  composer = new EffectComposer(renderer);
  composer.addPass(renderScene);
  composer.addPass(ssrPass);
  composer.addPass(bloomPass);
  composer.addPass(outputPass);
  composer.addPass(fxaaPass);
};
const animate = () => {
  const elapsedTime = clock.getElapsedTime();
  const deltaTime = elapsedTime - previousTime;
  previousTime = elapsedTime;
  camera.position.lerp(
    vector3
      .set(0.05 * Math.sin(elapsedTime), 0, 0.01 * Math.cos(elapsedTime))
      .add(camera.position),
    0.05
  );
  scene.userData.dynamicEnv &&
    scene.userData.dynamicEnv.children.forEach((item) => {
      if (item.userData.update) {
        item.userData.update(deltaTime, elapsedTime);
      }
    });
  scene.background.b = 0.02 * Math.sin(elapsedTime) + 0.04;
  rtCubeCamera.update(renderer, scene);
  composer.render(scene, camera);
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  controls.update();
};
const updateAllMaterials = () => {
  scene.getObjectByName("911").traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.castShadow = true;
      child.receiveShadow = true;
      child.material.envMap = scene.userData.dynamicMap;

      if (child.material.name === "rubber") {
        child.material.color.set("#222");
        child.material.roughness = 1;
        child.material.normalScale.set(4, 4);
        child.material.envMap = scene.userData.dynamicMap;
      }
      if (child.material.name === "window") {
        child.material.color.set("#222");
        child.material.roughness = 0;
        child.material.clearcoat = 0.1;
        child.material.envMap = scene.userData.dynamicMap;
      }
      if (child.material.name === "coat") {
        child.material.envMapIntensity = 4;
        child.material.roughness = 0.5;
        child.material.metalness = 1;
        child.material.envMap = scene.userData.dynamicMap;
      }
      if (child.material.name === "paint") {
        child.material.envMapIntensity = 2;
        child.material.roughness = 0.45;
        child.material.metalness = 0.8;
        child.material.envMap = scene.userData.dynamicMap;
        child.material.color.set("#b3b3ff");
      }
    }
  });

  // 更新阴影
  scene.getObjectByProperty("type", "SpotLight").shadow.needsUpdate = true;
};
function createDynamicEnv() {
  const group = new THREE.Group();
  group.name = "dynamicEnv";
  scene.userData.dynamicEnv = group;
  scene.add(group);
  const rect = new THREE.Mesh(
    new THREE.PlaneGeometry(2, 5),
    new THREE.MeshBasicMaterial({
      color: "#fff",
      side: THREE.DoubleSide,
    })
  );
  rect.position.set(3, 2, 0);
  rect.rotation.set(-Math.PI * 0.5, Math.PI * 0.1, 0);
  rect.name = "rect";
  rect.userData.update = (deltaTime, elapsedTime) => {
    rect.position.y = Math.abs(Math.sin(elapsedTime * 0.5)) + 1;
    rect.position.z = 0.5 * Math.sin(elapsedTime * 0.5);
  };

  const rect2 = new THREE.Mesh(
    new THREE.PlaneGeometry(5, 5),
    new THREE.MeshBasicMaterial({
      color: "#5c67ff",
      side: THREE.DoubleSide,
    })
  );
  rect2.rotation.set(-Math.PI * 0.2, -Math.PI * 0.3, -Math.PI * 0.2);
  rect2.position.set(-3.5, 0, 0);

  const sphere = new THREE.Mesh(
    new THREE.SphereGeometry(5, 32, 32),
    new THREE.MeshBasicMaterial({
      color: "#5a509f",
      side: THREE.BackSide,
    })
  );

  const cube = new THREE.Mesh(
    new THREE.BoxGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial({
      color: "#66edff",
      // side: THREE.FrontSide,
    })
  );
  cube.userData.update = (deltaTime, elapsedTime) => {
    cube.position.x = 1 * Math.sin(elapsedTime) - 1;
    cube.position.y = Math.sin(elapsedTime) + 1.5;
    cube.position.z = Math.cos(elapsedTime) - 1;
  };

  const ring = new THREE.Mesh(
    new THREE.CylinderGeometry(2, 2, 0.5, 16, 1, true),
    new THREE.MeshBasicMaterial({
      color: "#fafeff",
      side: THREE.DoubleSide,
    })
  );
  ring.rotation.set(Math.PI * 0.5, 0, 0);
  ring.userData.update = (deltaTime, elapsedTime) => {
    ring.position.z += 2 * deltaTime;
    if (ring.position.z > 4) {
      ring.position.z = -5;
    }
  };

  group.add(rect, rect2, sphere, cube, ring);

  group.children.forEach((item) => {
    item.layers.set(scene.userData.rtCubeCameraLayer);
  });
}
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
