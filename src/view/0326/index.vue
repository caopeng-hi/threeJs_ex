<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
// 从 Vue 导入 onMounted 钩子函数和 ref 响应式数据创建函数
import { onMounted, ref } from "vue";
// 导入 Three.js 库，用于创建 3D 场景、对象和渲染
import * as THREE from "three";
// 导入 Cannon-es 库，用于物理模拟
import * as CANNON from "cannon-es";
// 导入 OrbitControls 控件，用于在 Three.js 场景中实现相机的轨道控制
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入 RoundedBoxGeometry 几何体，用于创建带有圆角的盒子
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";

// 创建一个 ref 来引用 DOM 元素，用于渲染 Three.js 场景
const canvasRef = ref(null);

// 声明变量用于存储场景、相机、渲染器、控件、材质、物理世界和实例化的盒子网格
let scene,
  camera,
  renderer,
  controls,
  boxMaterial,
  physicsWorld,
  instancedBoxesMesh;

// 创建一个 THREE.Object3D 对象，用于在更新实例化网格时存储变换矩阵
let dummy = new THREE.Object3D();

// 存储所有盒子的物理体的数组
let boxesBodies = [];

/**
 * 定义参数对象，包含场景的各种配置参数
 * @property {number} boxesNumber - 场景中盒子的数量
 * @property {number} boxSize - 每个盒子的大小
 * @property {number} containerSize - 容器的大小
 * @property {number} gravity - 重力加速度
 */
const params = {
  boxesNumber: 100,
  boxSize: 0.03,
  containerSize: 1,
  gravity: 10,
};

/**
 * 当组件挂载后执行的生命周期钩子
 * 初始化场景、启动动画循环，并为画布添加双击事件监听器
 */
onMounted(() => {
  // 初始化 Three.js 场景
  initScene();
  // 启动动画循环
  animate();
  // 为画布添加双击事件监听器，当双击时调用 throwBoxes 函数
  canvasRef.value.addEventListener("dblclick", throwBoxes);
});

/**
 * 初始化 Three.js 场景的函数
 * 创建场景、相机、渲染器、控件，并设置物理世界和场景中的对象
 */
const initScene = () => {
  // 创建一个新的 Three.js 场景
  scene = new THREE.Scene();
  // 设置场景的背景颜色为白色
  scene.background = new THREE.Color(0xffffff);

  // 创建一个透视相机，设置视角、宽高比、近裁剪面和远裁剪面
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机的初始位置，并乘以一个缩放因子
  camera.position.set(0, 1, 0.5).multiplyScalar(5);

  // 创建一个 WebGL 渲染器，启用抗锯齿和透明度
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
  });
  // 设置渲染器的大小为窗口的大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 设置渲染器的像素比为设备的像素比
  renderer.setPixelRatio(window.devicePixelRatio);
  // 将渲染器的 DOM 元素添加到画布引用的元素中
  canvasRef.value.appendChild(renderer.domElement);

  // 创建一个轨道控制器，用于控制相机的视角
  controls = new OrbitControls(camera, renderer.domElement);
  // 禁用相机的缩放功能
  controls.enableZoom = false;
  // 禁用相机的平移功能
  controls.enablePan = false;
  // 设置相机的最小极角
  controls.minPolarAngle = 0.1 * Math.PI;
  // 设置相机的最大极角
  controls.maxPolarAngle = 0.9 * Math.PI;
  // 启用相机的自动旋转功能
  controls.autoRotate = true;
  // 设置相机的自动旋转速度
  controls.autoRotateSpeed = 19;
  // 启用相机的阻尼效果，使相机的移动更平滑
  controls.enableDamping = true;

  // 调用 throwBoxes 函数，为盒子施加初始冲量
  throwBoxes();

  // 初始化物理世界
  initPhysics();

  // 创建 6 个平面物理体，作为容器的边界
  for (let i = 0; i < 6; i++) {
    // 创建一个质量为 0 的平面物理体
    const body = new CANNON.Body({ mass: 0, shape: new CANNON.Plane() });
    // 将物理体添加到物理世界中
    physicsWorld.addBody(body);
    // 根据循环索引确定位置的正负号
    const posSign = i % 2 ? 1 : -1;

    if (i < 2) {
      // 设置平面在 x 轴上的位置
      body.position.x = posSign * 0.5 * params.containerSize;
      // 设置平面的旋转四元数
      body.quaternion.setFromEuler(0, (-posSign * Math.PI) / 2, 0);
    } else if (i < 4) {
      // 设置平面在 y 轴上的位置
      body.position.y = posSign * 0.5 * params.containerSize;
      // 设置平面的旋转四元数
      body.quaternion.setFromEuler((posSign * Math.PI) / 2, 0, 0);
    } else {
      // 设置平面在 z 轴上的位置
      body.position.z = posSign * 0.5 * params.containerSize;
      if (i > 4) {
        // 对于最后一个平面，设置额外的旋转
        body.quaternion.setFromEuler(0, Math.PI, 0);
      }
    }
  }

  // 创建一个基础材质，用于盒子的渲染
  boxMaterial = new THREE.MeshBasicMaterial({
    color: 0x000000,
    visible: false,
  });
  // 将材质设置为可见
  boxMaterial.visible = true;

  // 创建一个带有圆角的盒子几何体
  const boxGeometry = new RoundedBoxGeometry(
    params.boxSize,
    params.boxSize,
    params.boxSize,
    2,
    0.2 * params.boxSize
  );

  // 创建一个实例化的盒子网格，用于高效渲染多个相同的盒子
  instancedBoxesMesh = new THREE.InstancedMesh(
    boxGeometry,
    boxMaterial,
    params.boxesNumber
  );
  // 将实例化的盒子网格添加到场景中
  scene.add(instancedBoxesMesh);

  // 为每个盒子创建物理体，并添加到物理世界中
  for (let i = 0; i < params.boxesNumber; i++) {
    // 创建一个质量为 1 的盒子物理体
    boxesBodies[i] = new CANNON.Body({
      mass: 1,
      shape: new CANNON.Box(
        new CANNON.Vec3(
          0.6 * params.boxSize,
          0.6 * params.boxSize,
          0.6 * params.boxSize
        )
      ),
    });
    // 将物理体添加到物理世界中
    physicsWorld.addBody(boxesBodies[i]);
  }

  // 创建一个盒子几何体，用于表示容器的边界
  const wallGeometry = new THREE.BoxGeometry(
    params.containerSize,
    params.containerSize,
    params.containerSize
  );
  // 创建一个边缘几何体，用于渲染容器的边框
  const wallEdges = new THREE.EdgesGeometry(wallGeometry);
  // 创建一个线段对象，用于渲染容器的边框
  const wallLine = new THREE.LineSegments(
    wallEdges,
    new THREE.LineBasicMaterial({ color: 0x000000 })
  );
  // 将容器的边框添加到场景中
  scene.add(wallLine);
};

/**
 * 动画循环函数，用于更新场景和渲染画面
 * 递归调用 requestAnimationFrame 实现动画效果
 */
const animate = () => {
  // 请求下一帧动画
  requestAnimationFrame(animate);
  // 更新轨道控制器的状态
  controls.update();
  // 使用渲染器渲染场景和相机视角
  renderer.render(scene, camera);
  // 执行物理世界的固定步长更新
  physicsWorld.fixedStep();

  // 更新每个盒子的变换矩阵
  for (let i = 0; i < params.boxesNumber; i++) {
    // 将盒子的物理位置复制到 dummy 对象
    dummy.position.copy(boxesBodies[i].position);
    // 将盒子的物理旋转四元数复制到 dummy 对象
    dummy.quaternion.copy(boxesBodies[i].quaternion);
    // 更新 dummy 对象的变换矩阵
    dummy.updateMatrix();
    // 将 dummy 对象的变换矩阵应用到实例化网格的对应实例
    instancedBoxesMesh.setMatrixAt(i, dummy.matrix);
  }
  // 标记实例化网格的变换矩阵需要更新
  instancedBoxesMesh.instanceMatrix.needsUpdate = true;

  // 创建一个三维向量表示重力方向
  const gravity = new THREE.Vector3(0, -params.gravity, 0);
  // 根据相机的旋转方向调整重力方向
  gravity.applyQuaternion(camera.quaternion);
  // 将调整后的重力方向应用到物理世界
  physicsWorld.gravity = new CANNON.Vec3(gravity.x, gravity.y, gravity.z);
};

/**
 * 初始化物理世界的函数
 * 创建一个 Cannon-es 物理世界，并设置重力和接触材料的属性
 */
function initPhysics() {
  // 创建一个新的 Cannon-es 物理世界
  physicsWorld = new CANNON.World({
    allowSleep: true,
    gravity: new CANNON.Vec3(0, -params.gravity, 0),
  });
  // 设置物理世界的默认接触材料的摩擦力
  physicsWorld.defaultContactMaterial.friction = 0.1;
  // 设置物理世界的默认接触材料的弹性系数
  physicsWorld.defaultContactMaterial.restitution = 0.9;
}

/**
 * 为所有盒子施加随机冲量的函数
 * 当用户双击画布时调用该函数，使盒子开始运动
 */
function throwBoxes() {
  // 遍历所有盒子的物理体
  boxesBodies.forEach((body) => {
    // 定义冲量的大小
    const force = 7;
    // 为每个盒子施加一个随机方向的冲量
    body.applyImpulse(
      new CANNON.Vec3(
        Math.random() > 0.5 ? -force : force,
        Math.random() > 0.5 ? -force : force,
        Math.random() > 0.5 ? -force : force
      )
    );
  });
}
</script>

<style lang="scss" scoped></style>
