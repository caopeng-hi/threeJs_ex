<template>
  <div ref="scrollRef" id="content" class="content">
    <p>
      Blackbird singing in the dead of <span>night</span><br />
      Take these broken<span>wings</span>and learn to fly<br />
      All your life<br />
      You were only<span>waiting</span>for this moment to arise<br />
      Blackbird<span>singing</span>in the dead of night<br />
      Take these sunken eyes and<span>learn</span>to see<br />
      All your life<br />
      You were only waiting for this<span>moment</span>to be free<br />
      Blackbird fly, blackbird fly<br />
      Into the light of a<span>dark</span>black night<br />
      Blackbird fly, blackbird fly<br />
      Into the light of a dark<span>black</span>night<br />
      Blackbird<span>singing</span>in the dead of night<br />
      Take these broken wings and<span>learn</span>to fly<br />All your life<br />
      You were only<span>waiting</span>for this moment to arise<br />
      You were only waiting for this<span>moment</span>to arise<br />
      You were only waiting for this moment to<span>arise</span><br />
    </p>
  </div>
  <div class="contentRef" ref="contentRef"></div>
</template>

<script setup>
// 引入 Three.js 库，用于创建 3D 场景和渲染
import * as THREE from "three";
// 引入 Vue 的响应式 API 和生命周期钩子
import { ref, onMounted } from "vue";
// 引入 GSAP 动画库
import { gsap } from "gsap";
// 引入 GSAP 的 ScrollTrigger 插件，用于实现滚动触发动画
import { ScrollTrigger } from "gsap/ScrollTrigger";

// 注册 ScrollTrigger 插件到 GSAP
gsap.registerPlugin(ScrollTrigger);

// 创建一个响应式引用，用于存储内容容器的 DOM 元素
const contentRef = ref(null);
// 创建一个响应式引用，用于存储滚动容器的 DOM 元素
const scrollRef = ref(null);

// 声明场景对象，用于存储 3D 场景
let scene;
// 声明相机对象，用于定义视角
let camera;
// 声明渲染器对象，用于将场景渲染到屏幕上
let renderer;
// 声明时间变量，用于存储当前时间
let time;

// 存储场景中的网格对象数组
let meshes = [];

// 存储一些设置参数，如相机距离和缩放周期
let settings = { cameraDistance: 5, scalePeriod: 8 };

// 存储滚动平滑器的进度，范围从 0 到 1
let scrollSmoother = {
  process: 0,
};

// 在组件挂载后执行的生命周期钩子
onMounted(() => {
  // 初始化 3D 场景
  init();
  // 开始动画循环
  animate();

  // 遍历所有的 span 元素
  document.querySelectorAll("span").forEach((span) => {
    // 为每个 span 元素创建 ScrollTrigger 实例
    ScrollTrigger.create({
      // 设置触发元素为当前 span 元素
      trigger: span,
      // 定义触发动画的起始位置
      start: "top 90%",
      // 定义触发动画的结束位置
      end: "bottom 10%",
      // 当滚动位置更新时执行的回调函数
      onUpdate: (self) => {
        // 计算当前进度与 0.5 的距离
        const dist = Math.abs(self.progress - 0.5);
        // 将距离映射到 80 到 100 的亮度范围
        const lightness = mapToRange(dist, 0, 0.5, 80, 100);
        // 设置 span 元素的 CSS 变量 --l 为计算得到的亮度值
        span.style.setProperty("--l", lightness + "%");
      },
    });
  });

  // 为窗口添加滚动事件监听器
  window.addEventListener(
    "scroll",
    () => {
      // 计算滚动容器的滚动百分比
      const scrollPercentage = calculateScrollPercentage(scrollRef.value);
      // 更新滚动平滑器的进度
      scrollSmoother.process = scrollPercentage;
    },
    false
  );
});

/**
 * 初始化 3D 场景的函数
 */
const init = () => {
  // 创建一个新的场景对象
  scene = new THREE.Scene();
  // 创建一个透视相机，设置视角和相机参数
  camera = new THREE.PerspectiveCamera(
    45, // 视角角度
    window.innerWidth / window.innerHeight, // 宽高比
    1, // 近裁剪面
    10000 // 远裁剪面
  );
  // 设置相机的初始位置
  camera.position.z = 5;

  // 创建一个 WebGL 渲染器，设置抗锯齿和透明度
  renderer = new THREE.WebGLRenderer({ antialias: false, alpha: true });
  // 设置渲染器的像素比例
  renderer.setPixelRatio(1.5);
  // 设置渲染器的大小为窗口大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器的 DOM 元素添加到内容容器中
  contentRef.value.appendChild(renderer.domElement);

  // 创建一个环境光，设置颜色和强度
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.1);
  // 将环境光添加到场景中
  scene.add(ambientLight);

  // 创建一个平行光，设置颜色和强度
  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.4);
  // 设置平行光的位置
  directionalLight.position.set(15, 3, 2);
  // 让平行光看向场景中心
  directionalLight.lookAt(0, 0, 0);
  // 将平行光添加到场景中
  scene.add(directionalLight);

  // 创建场景中的物体
  createItem();
};

/**
 * 创建场景中的物体的函数
 */
const createItem = () => {
  // 创建一个立方体的几何体，设置尺寸
  const geometry = new THREE.BoxGeometry(2, 2, 2);
  // 创建一个 Lambert 材质，设置颜色
  const material = new THREE.MeshLambertMaterial({ color: 0xffffff });
  // 定义要创建的物体数量
  const itemCount = 40;

  // 循环创建指定数量的物体
  for (let i = 0; i < itemCount; i++) {
    // 创建一个网格对象，将几何体和材质组合
    const mesh = new THREE.Mesh(geometry, material);
    // 随机设置物体的 Y 轴位置
    mesh.position.y = 13 * (Math.random() * 2 - 1);
    // 随机设置物体的 X 轴位置
    mesh.position.x = 3 * (Math.random() * 2 - 1);
    // 随机设置物体的 Z 轴位置
    mesh.position.z = 4 * (Math.random() * 2 - 1);
    // 随机设置物体的 Y 轴旋转角度
    mesh.rotation.y = Math.PI * Math.random();
    // 随机设置物体的旋转速度
    mesh.rotationSpeed = Math.random() * 0.01 + 0.005;
    // 将物体添加到场景中
    scene.add(mesh);
    // 将物体添加到网格对象数组中
    meshes.push(mesh);
  }
};

/**
 * 更新场景中物体状态的函数
 */
const updateItems = () => {
  // 定义缩放效果的振幅
  const amplitude = 0.05;
  // 从设置中获取缩放周期
  const period = settings.scalePeriod;
  // 定义基础缩放比例
  const baseScale = 0.2;

  // 计算当前的缩放效果
  const scaleEffect =
    baseScale + amplitude * Math.sin(Math.PI * 2 * (time / period));

  // 遍历所有网格对象
  meshes.forEach((mesh) => {
    // 设置网格对象的缩放比例
    mesh.scale.set(scaleEffect, scaleEffect, scaleEffect);
    // 更新网格对象的 X 轴旋转角度
    mesh.rotation.x += mesh.rotationSpeed;
  });

  // 定义相机的移动范围
  const cameraRange = 10;
  // 根据滚动平滑器的进度，计算相机的 Y 轴位置
  camera.position.y = mapToRange(
    scrollSmoother.process,
    0,
    1,
    cameraRange,
    -cameraRange
  );
};

/**
 * 将一个值从一个范围映射到另一个范围的函数
 * @param {number} value - 要映射的值
 * @param {number} inMin - 输入范围的最小值
 * @param {number} inMax - 输入范围的最大值
 * @param {number} outMin - 输出范围的最小值
 * @param {number} outMax - 输出范围的最大值
 * @returns {number} - 映射后的值
 */
const mapToRange = (value, inMin, inMax, outMin, outMax) => {
  // 计算映射后的值
  return ((value - inMin) * (outMax - outMin)) / (inMax - inMin) + outMin;
};

/**
 * 动画循环函数，用于不断更新场景并渲染
 */
const animate = () => {
  // 获取当前时间
  time = new THREE.Clock().getElapsedTime();
  // 更新场景中物体的状态
  updateItems();
  // 请求下一帧动画
  requestAnimationFrame(animate);
  // 渲染场景
  renderer.render(scene, camera);
};

/**
 * 计算页面滚动百分比的函数
 * @param {HTMLElement} element - 滚动容器元素
 * @returns {number} - 滚动百分比，范围从 0 到 1
 */
function calculateScrollPercentage(element) {
  // 获取滚动容器的高度
  const maxScroll = element.clientHeight;
  // 获取页面的滚动距离
  const scrollTop =
    document.documentElement.scrollTop || document.body.scrollTop;
  // 计算滚动百分比
  const percentage = maxScroll > 0 ? scrollTop / maxScroll : 0;
  // 确保百分比在 0 到 1 之间
  return Math.min(1, Math.max(0, percentage));
}
</script>

<style lang="scss" scoped>
.content {
  min-height: 100vh;
  background-color: #111;
  color: #fff;
  font-family: "Work Sans", sans-serif;
  padding: 3vw;
  padding-top: 9vh;
  font-size: 7.9vw;
  font-weight: 600;
  line-height: 1.2;
  span {
    --h: 0;
    --s: 100%;
    --l: 80%;
    @for$idx from 1 through 30 {
      &:nth-child(#{$idx}) {
        --h: #{$idx * 5 + 160};
      }
    }
    --color-light: hsl(var(--h), var(--s), var(--l));
    --color-dark: hsl(calc(var(--h) + 30), var(--s), var(--l));
    position: relative;
    color: var(--color-light);
    display: inline;
    background: linear-gradient(to right, var(--color-light), var(--color-dark)),
      no-repeat;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    -webkit-box-decoration-break: clone;
  }
}
.contentRef {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  transition: opacity 1s;
}
</style>
