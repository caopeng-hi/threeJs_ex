<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import { ref, onMounted, onBeforeUnmount } from "vue";
// 导入轨道控制器（允许用户用鼠标交互控制场景）
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";

// Vue ref引用，用于挂载Three.js渲染器DOM元素
const canvasRef = ref(null);

// Three.js相关变量声明
let scene, camera, renderer, controls; // 场景、相机、渲染器、控制器
let colors = ["#da6b00", "#8555d4", "#4ad3b5", "#ffffff"]; // 球体颜色数组
let radius = 5; // 球体基础半径
let mouse = new THREE.Vector2(); // 存储标准化鼠标坐标(x,y)
let vector = new THREE.Vector3(); // 3D向量，用于坐标转换
let canvasMouse = new THREE.Vector3(0, 0, 0); // 画布空间中的3D鼠标位置
let spheresInfo = {}; // 存储所有球体信息的对象
let sphereIndex = 0; // 球体唯一标识索引
let floorDimensions = 350; // 地板尺寸
let floorLevel = -100; // 地板Y轴位置
let floor; // 地板网格对象
let dotsPerInterval; // 每帧生成的球体数量
let geometry, material; // 几何体和材质引用
let interval = null; // 定时器引用

// 组件挂载后执行初始化
onMounted(() => {
  init(); // 初始化3D场景
  animate(); // 启动动画循环
  // 设置定时器，每15毫秒生成新球体
  interval = setInterval(initShaper, 15);

  // 监听鼠标移动事件
  window.addEventListener("mousemove", mouseMove, false);

  // 点击事件：切换球体生成状态
  document.addEventListener("click", handelClick, false);
  // 监听窗口大小变化
  window.addEventListener("resize", handelResize, false);
});

// 初始化3D场景
const init = () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();

  // 创建透视相机
  camera = new THREE.PerspectiveCamera(
    45, // 视场角
    window.innerWidth / window.innerHeight, // 宽高比
    0.1, // 近裁剪面
    1000 // 远裁剪面
  );
  camera.position.z = 600; // 设置相机初始位置

  // 创建WebGL渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true, // 开启抗锯齿
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio); // 适配设备像素比
  renderer.setClearColor("#4e4d70"); // 设置清除颜色
  canvasRef.value.appendChild(renderer.domElement); // 挂载到DOM

  // 添加环境光
  const ambientLight = new THREE.AmbientLight("#ffffff", 0.5);
  scene.add(ambientLight);

  // 创建轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建地板
  geometry = new THREE.BoxGeometry(floorDimensions, 5, floorDimensions);
  material = new THREE.MeshLambertMaterial({
    color: "#000000",
    depthWrite: false, // 禁用深度写入
    transparent: true, // 开启透明度
    opacity: 1, // 完全不透明
  });
  floor = new THREE.Mesh(geometry, material);
  floor.position.y = floorLevel - radius / 2; // 设置地板位置
  floor.position.z = 0;
  scene.add(floor);
};

// 动画循环
const animate = () => {
  requestAnimationFrame(animate); // 循环调用自身
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
};

// 生成球体
const initShaper = () => {
  dotsPerInterval = 2; // 每帧生成2个球体
  // 生成新球体
  for (let i = 0; i < dotsPerInterval; i++) {
    initDot();
  }
  // 更新所有现有球体位置
  for (const key in spheresInfo) {
    drawDot(spheresInfo[key]);
  }
};

// 初始化单个球体
const initDot = () => {
  let info = {};
  info.color = colors[random(0, 4)]; // 随机颜色
  info.radius = radius; // 基础半径
  info.radiusStart = info.radius; // 初始半径
  info.radiusDeincrement = info.radius * -0.002; // 半径衰减速度

  // 设置初始位置（基于鼠标位置或默认值）
  info.startX = canvasMouse.x || 0;
  info.startY = canvasMouse.y || 100;
  info.startZ = canvasMouse.z || 0;

  // 确保初始位置不低于地板
  if (info.startY < floorLevel - info.radiusStart / 2) {
    info.startY = floorLevel - info.radiusStart / 2;
  }

  // 随机运动方向
  info.isXNegative = random(1, 2);
  info.isZNegative = random(1, 2);

  // 设置各轴初速度
  info.vx =
    info.isXNegative === 1 ? random(0, 50) * -0.15 : random(0, 50) * 0.15;
  info.vxMult = random(10, 20) * 0.15; // X轴速度乘数
  info.vy = random(-10, 20); // Y轴初速度
  info.vyMult = random(4, 6) * -0.1; // Y轴反弹乘数
  info.vz =
    info.isZNegative === 1 ? random(-25, 25) * -0.4 : random(-25, 25) * 0.4;
  info.vzMult = random(10, 20) * 0.1; // Z轴速度乘数

  // 分配唯一ID并存储球体信息
  sphereIndex++;
  spheresInfo[sphereIndex] = info;
  info.ID = sphereIndex;

  // 物理参数
  info.bounced = false; // 是否反弹过
  info.startGravity = 1; // 初始重力
  info.gravity = info.startGravity; // 当前重力

  // 创建球体网格
  const geometry = new THREE.CircleGeometry(info.radius, 20); // 圆形几何体
  const material = new THREE.MeshBasicMaterial({
    color: info.color, // 使用随机颜色
  });
  const sphere = new THREE.Mesh(geometry, material);
  scene.add(sphere);
  info.sphere = sphere; // 存储网格引用
};

// 更新球体位置和状态
const drawDot = (info) => {
  // 更新球体大小（逐渐缩小）
  info.sphere.scale.x += info.radiusDeincrement;
  info.sphere.scale.y += info.radiusDeincrement;
  info.sphere.scale.z += info.radiusDeincrement;

  // 更新位置（基于速度）
  info.sphere.position.x = info.startX += info.vx * 0.6;
  info.sphere.position.y = info.startY -= info.vy * 0.5;
  info.sphere.position.z = info.startZ -= info.vz * 0.6;

  // 碰撞检测（与地板）
  if (info.sphere.position.y < floorLevel - info.radiusStart / 2) {
    if (!info.bounced) {
      // 首次碰撞，反弹
      info.vx *= info.vxMult;
      info.vz *= info.vzMult;
    } else {
      // 后续碰撞，减速
      info.vx *= 0.95;
      info.vz *= 0.95;
    }

    // 边界检测
    if (
      !(
        info.sphere.position.x > floorDimensions / 2 ||
        info.sphere.position.x < -floorDimensions / 2 ||
        info.sphere.position.z > floorDimensions / 2 ||
        info.sphere.position.z < -floorDimensions / 2
      )
    ) {
      // 在地板范围内反弹
      info.vy *= info.vyMult;
      info.sphere.position.y =
        floorLevel + info.radiusStart * info.sphere.scale.x;
    } else {
      // 超出地板范围，减弱重力
      info.gravity = info.startGravity / 4;
      info.sphere.position.y =
        (info.startY -= info.vy * 0.01) +
        (20 - info.radiusStart * info.sphere.scale.x);
    }
    info.bounced = true;
  }

  // 应用重力
  info.vy += info.gravity;

  // 球体过小则移除
  if (info.sphere.scale.y <= 0.1) {
    delete spheresInfo[info.ID];
    scene.remove(info.sphere);
  }
};

// 鼠标移动事件处理
const mouseMove = (event) => {
  // 将鼠标坐标标准化到[-1,1]范围
  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

  // 将2D鼠标坐标转换为3D世界坐标
  vector = new THREE.Vector3(mouse.x || 0, mouse.y || 0, 0);
  vector.unproject(camera);
  const dir = vector.sub(camera.position).normalize();
  const distance = -camera.position.z / dir.z;
  canvasMouse = camera.position.clone().add(dir.multiplyScalar(distance));
};

// 生成[min,max)范围内的随机整数
const random = (min, max) => {
  return Math.floor(Math.random() * max) + min;
};
const handelClick = () => {
  if (interval) {
    clearInterval(interval); // 停止生成球体
    interval = null;
  } else {
    interval = setInterval(initShaper, 15); // 恢复生成球体
  }
};
const handelResize = () => {
  // 更新相机
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  // 更新渲染器
  renderer.setSize(window.innerWidth, window.innerHeight);
};
onBeforeUnmount(() => {
  window.removeEventListener("mousemove", mouseMove);
  document.removeEventListener("click", handelClick);
  window.removeEventListener("resize", handelResize);
});
</script>
<style lang="scss" scoped></style>
