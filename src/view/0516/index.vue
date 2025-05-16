<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import * as CANNON from "cannon-es";
// 导入轨道控制器
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入GLTFLoader
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader";
import { RGBELoader } from "three/examples/jsm/loaders/RGBELoader";
// 导入后期处理
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass";
let scene, camera, renderer, controls, world, clock, composer, bloomPass;
const canvasRef = ref(null);
const ringAmount = 10;
const tankSize = { x: 14, y: 12, z: 2 };
const tankOffset = { x: 0, y: 6, z: 0 };
const ringList = ref([]);
// 存储所有刚体的数组
const bodies = [];
let buttonLeft;
let buttonRight;
let targets = [];
const leftUp = ref(false);
const rightUp = ref(false);
let bodyCom, meshCom, targetPosition, smoothPosition;
const leftActuatorPosition = ref([-5, -16, 0]);
const rightActuatorPosition = ref([5, -16, 0]);
onMounted(() => {
  init();
  animate();
  window.addEventListener("keydown", handleKeyDown);
  window.addEventListener("keyup", handleKeyUp);
});
const handleKeyDown = (e) => {
  if (e.key === "j") rightUp.current = true;
  if (e.key === "f") leftUp.current = true;
};

const handleKeyUp = (e) => {
  if (e.key === "j") rightUp.current = false;
  if (e.key === "f") leftUp.current = false;
};
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  // 1. 加载 HDR 环境贴图
  new RGBELoader().load("/img/tv_studio_small.hdr", (texture) => {
    // 2. 设置场景背景
    scene.background = texture;

    // 3. 设置环境光照
    scene.environment = texture;

    // 4. 模糊背景（需额外处理）
    texture.mapping = THREE.EquirectangularReflectionMapping;
    texture.minFilter = THREE.LinearFilter;
    texture.magFilter = THREE.LinearFilter;
    texture.generateMipmaps = false; // 禁用 mipmaps 以简化模糊
  });
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    35, // fov - 视野角度
    window.innerWidth / window.innerHeight, // 宽高比 - 通常设为窗口宽高比
    0.1, // near - 近裁剪面
    200 // far - 远裁剪面
  );
  // 设置相机位置
  camera.position.set(0, 0, 60);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  // 将渲染器添加到DOM中
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);

  // 1. 创建平行光
  const directionalLight = new THREE.DirectionalLight(0xffffff, 4);
  directionalLight.position.set(2, 4, -2);

  // 2. 启用阴影
  directionalLight.castShadow = true;

  // 3. 设置阴影贴图分辨率
  directionalLight.shadow.mapSize.width = 512;
  directionalLight.shadow.mapSize.height = 512;

  // 4. 设置阴影偏移（避免阴影痤疮）
  directionalLight.shadow.bias = 0.0001;

  // 5. 配置阴影相机（正交相机）
  directionalLight.shadow.camera.near = 1;
  directionalLight.shadow.camera.far = 50;
  directionalLight.shadow.camera.left = -50;
  directionalLight.shadow.camera.right = 50;
  directionalLight.shadow.camera.top = 50;
  directionalLight.shadow.camera.bottom = -50;

  // 6. 将光源添加到场景
  scene.add(directionalLight);
  // 初始化物理世界
  world = new CANNON.World({
    gravity: new CANNON.Vec3(0, -9.82, 0),
  });

  // 创建rings
  createRings();
  // 加载模型
  createModel();

  Actuator(leftActuatorPosition.value);
  Actuator(rightActuatorPosition.value);
  // 2. 创建效果合成器
  composer = new EffectComposer(renderer);

  // 3. 添加渲染通道（将场景渲染到后处理管道）
  const renderPass = new RenderPass(scene, camera);
  composer.addPass(renderPass);

  // 4. 添加泛光效果
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    0.5, // intensity
    0.9, // luminanceThreshold
    0.9 // luminanceSmoothing
  );
  composer.addPass(bloomPass);
};
const animate = () => {
  clock = new THREE.Clock();
  const delta = clock.getDelta();
  // 渲染场景和相机
  renderer.render(scene, camera);
  composer.render();
  requestAnimationFrame(animate);
  controls.update();
  world.step(1 / 60); // 更新物理世界
  update(delta, leftUp);
  update(delta, rightUp);
};
const createRings = () => {
  for (let id = 0; id < ringAmount; id += 1) {
    const position = [
      Math.random() * tankSize.x - tankSize.x / 2 + tankOffset.x,
      Math.random() * tankSize.y - tankSize.y / 2 + tankOffset.y,
      Math.random() * tankSize.z - tankSize.z / 2 + tankOffset.z,
    ];
    const rotation = [
      Math.random() * Math.PI,
      Math.random() * Math.PI,
      Math.random() * Math.PI,
    ];
    const colors = [0xee6688, 0x00dd44, 0x1122ff];
    const color = colors[Math.floor(Math.random() * colors.length)];
    ringList.value.push({ id, position, rotation, color });
  }
};
const createModel = () => {
  const gltfLoader = new GLTFLoader();
  const dracoLoader = new DRACOLoader();
  dracoLoader.setDecoderPath("./draco/");
  dracoLoader.setDecoderConfig({ type: "js" });
  dracoLoader.preload();
  gltfLoader.setDRACOLoader(dracoLoader);
  gltfLoader.load("/model/tank.glb", (gltf) => {
    const { nodes, scene: tank } = extractNodesAndScene(gltf);
    const physicsNode = tank.getObjectByName("Physics");
    buttonLeft = tank.getObjectByName("Button_Left");
    buttonRight = tank.getObjectByName("Button_Right");
    const baseScene = tank.getObjectByName("BaseScene");
    const targetsNode = tank.getObjectByName("Targets");
    if (!physicsNode) return;
    setupPhysicsObjects(physicsNode);

    if (targetsNode && targetsNode.children.length > 0) {
      targetsNode.children.forEach((child) => {
        targets.push([child.position.x, child.position.y, child.position.z]);
      });
    }
    console.log(baseScene, "baseScene");

    if (baseScene) {
      baseScene.traverse((child) => {
        if (child.isMesh) {
          child.castShadow = true;
          child.receiveShadow = true;
        }
      });
    }
    const group = new THREE.Group();
    // 2. 为每个物理刚体添加占位网格（可选，调试用）
    bodies.forEach((body) => {
      const boxMesh = new THREE.Mesh(
        new THREE.BoxGeometry(1, 1, 1), // 尺寸需根据刚体调整
        new THREE.MeshBasicMaterial({ visible: false }) // 不可见
      );

      // 同步位置和旋转
      boxMesh.position.copy(body.position);
      boxMesh.quaternion.copy(body.quaternion);

      group.add(boxMesh);
    });
    scene.add(tank);
    scene.add(group); // 添加到场景中
  });
};
function extractNodesAndScene(gltf) {
  const scene = gltf.scene;
  const nodes = {};

  // 递归遍历场景中的所有对象，按名称存储到 nodes 对象
  scene.traverse((child) => {
    if (child.name) {
      nodes[child.name] = child;
    }
  });

  return { nodes, scene };
}
// 遍历场景中的子对象，创建物理刚体
function setupPhysicsObjects(physicsNode) {
  physicsNode.children.forEach((obj) => {
    // 1. 隐藏原始模型
    obj.visible = false;

    // 2. 创建物理刚体（盒子形状）
    const size = new THREE.Vector3();
    obj.getWorldScale(size); // 获取世界坐标系下的缩放
    const halfExtents = new CANNON.Vec3(size.x, size.y, size.z); // Cannon.js 使用半边长

    const body = new CANNON.Body({
      mass: 0, // 静态物体
      shape: new CANNON.Box(halfExtents),
      position: new CANNON.Vec3(obj.position.x, obj.position.y, obj.position.z),
      quaternion: new CANNON.Quaternion().setFromEuler(
        obj.rotation.x,
        obj.rotation.y,
        obj.rotation.z
      ),
      material: new CANNON.Material({
        friction: 0.01,
        restitution: 0.2,
      }),
    });

    // 3. 命名刚体并保存
    body.name = obj.name;
    bodies.push(body);
    world.addBody(body);
  });
}
// 创建刚体物体升降器
const Actuator = (position) => {
  const size = 10;
  bodyCom = new CANNON.Body({
    mass: 0,
    shape: new CANNON.Box(new CANNON.Vec3(size / 2, size / 2, size / 2)),
    position: new CANNON.Vec3(...position),
  });
  world.addBody(bodyCom);

  // 可视化网格（线框）
  meshCom = new THREE.Mesh(
    new THREE.BoxGeometry(size, size, size),
    new THREE.MeshStandardMaterial({ wireframe: true, visible: false })
  );
  meshCom.position.copy(position);

  // 状态
  targetPosition = new THREE.Vector3(position[0], position[1], position[2]);
  smoothPosition = new THREE.Vector3(...position);
};
const update = (delta, flag) => {
  const targetY = flag ? -10 : -16;
  targetPosition.y = targetY;

  // 平滑阻尼
  smoothPosition.y +=
    (targetPosition.y - smoothPosition.y) * (1 - Math.exp(-10 * delta));

  // 更新物理和渲染
  bodyCom.position.copy(smoothPosition);
  meshCom.position.copy(smoothPosition);
};
</script>

<style lang="scss" scoped></style>
