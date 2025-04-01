<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
import { ref, onMounted } from "vue";
// 导入轨道控制器（允许用户用鼠标交互控制场景）
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入GSAP动画库
import gsap from "gsap";

// Vue ref引用，用于挂载Three.js渲染器DOM元素
let canvasRef = ref(null);

// Three.js相关变量声明
let scene, camera, renderer, controls; // 场景、相机、渲染器、控制器
let tubeMaterial; // 管道材质
let curve; // 曲线路径
let tubeMesh; // 管道网格对象
let splineMesh; // 样条曲线网格（仅用于计算）
let currentTubeGeometry; // 当前管道几何体引用

// 纹理动画参数配置
const textureParams = {
  offsetX: 0, // 纹理X轴偏移
  offsetY: 0, // 纹理Y轴偏移
  repeatX: 10, // 纹理X轴重复次数
  repeatY: 4, // 纹理Y轴重复次数
};

// 相机抖动效果参数
const cameraShake = {
  x: 0, // X轴抖动幅度
  y: 0, // Y轴抖动幅度
};

// 鼠标交互状态跟踪
let mouse = {
  position: new THREE.Vector2(0, 0), // 当前鼠标位置
  ratio: new THREE.Vector2(0, 0), // 标准化后的鼠标位置(0-1)
  target: new THREE.Vector2(0, 0), // 鼠标目标位置
};

// 组件挂载后执行初始化
onMounted(() => {
  // 初始化鼠标位置（屏幕中心）
  mouse = {
    position: new THREE.Vector2(
      window.innerWidth * 0.5,
      window.innerHeight * 0.5
    ),
    ratio: new THREE.Vector2(0, 0),
    target: new THREE.Vector2(
      window.innerWidth * 0.5,
      window.innerHeight * 0.5
    ),
  };

  init(); // 初始化3D场景
  animate(); // 启动动画循环
});

// 场景初始化函数
const init = () => {
  // 创建场景
  scene = new THREE.Scene();

  // 设置透视相机
  camera = new THREE.PerspectiveCamera(
    15, // 视场角(FOV)
    window.innerWidth / window.innerHeight, // 宽高比
    0.01, // 近裁剪面
    1000 // 远裁剪面
  );
  camera.rotation.y = Math.PI; // 旋转相机180度
  camera.position.z = 0.35; // 设置相机Z轴位置

  // 创建WebGL渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true }); // 开启抗锯齿
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);

  // 初始化轨道控制器
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建曲线路径点
  const points = [];
  for (let i = 0; i < 5; i++) {
    points.push(new THREE.Vector3(0, 0, 3 * (i / 4)));
  }
  points[4].y = -0.06; // 设置最后一个点的Y轴位置

  // 创建Catmull-Rom样条曲线
  curve = new THREE.CatmullRomCurve3(points);
  curve.type = "catmullrom";

  // 创建曲线网格（仅用于计算，不添加到场景中）
  const curvePoints = curve.getPoints(70); // 获取70个采样点
  const positionArray = new Float32Array(curvePoints.length * 3);
  for (let i = 0; i < curvePoints.length; i++) {
    positionArray[i * 3] = curvePoints[i].x;
    positionArray[i * 3 + 1] = curvePoints[i].y;
    positionArray[i * 3 + 2] = curvePoints[i].z;
  }

  // 创建样条曲线几何体
  const splineGeometry = new THREE.BufferGeometry();
  splineGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(positionArray, 3)
  );
  splineMesh = new THREE.Line(splineGeometry, new THREE.LineBasicMaterial());

  // 创建管道几何体
  const tubeGeometry = new THREE.TubeGeometry(
    curve, // 路径曲线
    70, // 分段数
    0.02, // 半径
    30, // 径向分段数
    false // 是否闭合
  );

  // 加载纹理并创建管道材质
  const loader = new THREE.TextureLoader();
  loader.crossOrigin = "Anonymous"; // 允许跨域加载
  loader.load("/img.jpg", function (texture) {
    // 创建管道材质
    tubeMaterial = new THREE.MeshBasicMaterial({
      side: THREE.BackSide, // 只渲染背面
      map: texture, // 应用纹理
    });
    // 设置纹理重复和镜像模式
    tubeMaterial.map.wrapS = THREE.MirroredRepeatWrapping;
    tubeMaterial.map.wrapT = THREE.MirroredRepeatWrapping;
    tubeMaterial.map.repeat.set(textureParams.repeatX, textureParams.repeatY);

    // 创建管道网格并添加到场景
    tubeMesh = new THREE.Mesh(tubeGeometry, tubeMaterial);
    scene.add(tubeMesh);
  });

  // 使用GSAP创建纹理动画时间线
  const hyperSpace = gsap.timeline({ repeat: -1 }); // 无限循环
  hyperSpace.to(textureParams, {
    duration: 4,
    repeatX: 0.3,
    ease: "power1.inOut",
  });
  hyperSpace.to(
    textureParams,
    {
      duration: 12,
      offsetX: 8, // X轴偏移动画
      ease: "power2.inOut",
    },
    0 // 立即开始
  );
  hyperSpace.to(
    textureParams,
    {
      duration: 6,
      repeatX: 10, // X轴重复次数动画
      ease: "power2.inOut",
    },
    "-=5" // 相对于前一个动画提前5秒开始
  );

  // 相机抖动动画
  const shake = gsap.timeline({ repeat: -1, repeatDelay: 5 });
  shake.to(
    cameraShake,
    {
      duration: 2,
      x: -0.01, // X轴抖动
      ease: "rough({template: none, strength: 0.5, points: 100, taper: none, randomize: true, clamp: false})",
    },
    4 // 延迟4秒开始
  );
  shake.to(cameraShake, {
    duration: 2,
    x: 0, // 恢复原位
    ease: "rough({template: none, strength: 0.5, points: 100, taper: none, randomize: true, clamp: false})",
  });

  // 保存当前几何体引用
  currentTubeGeometry = tubeGeometry;
};

// 动画循环函数
const animate = () => {
  // 更新纹理参数
  if (tubeMaterial) {
    tubeMaterial.map.offset.x = textureParams.offsetX; // 应用X轴偏移
    tubeMaterial.map.offset.y += 0.001; // 持续增加Y轴偏移
    tubeMaterial.map.repeat.set(textureParams.repeatX, textureParams.repeatY); // 更新重复参数
  }

  // 平滑更新相机位置（跟随鼠标）
  mouse.position.x += (mouse.target.x - mouse.position.x) / 50;
  mouse.position.y += (mouse.target.y - mouse.position.y) / 50;
  // 计算标准化鼠标位置(0-1)
  mouse.ratio.x = mouse.position.x / window.innerWidth;
  mouse.ratio.y = mouse.position.y / window.innerHeight;
  // 应用相机位置（包含抖动效果）
  camera.position.x = mouse.ratio.x * 0.044 - 0.025 + cameraShake.x;
  camera.position.y = mouse.ratio.y * 0.044 - 0.025;

  // 根据鼠标位置更新曲线控制点
  if (curve && curve.points) {
    curve.points[2].x = 0.6 * (1 - mouse.ratio.x) - 0.3;
    curve.points[3].x = 0;
    curve.points[4].x = 0.6 * (1 - mouse.ratio.x) - 0.3;

    curve.points[2].y = 0.6 * (1 - mouse.ratio.y) - 0.3;
    curve.points[3].y = 0;
    curve.points[4].y = 0.6 * (1 - mouse.ratio.y) - 0.3;
  }

  // 重新生成管道几何体
  if (curve) {
    const newTubeGeometry = new THREE.TubeGeometry(curve, 70, 0.02, 30, false);

    // 高效更新几何体数据（避免频繁创建新几何体）
    if (tubeMesh && currentTubeGeometry) {
      const oldPositions = currentTubeGeometry.getAttribute("position");
      const newPositions = newTubeGeometry.getAttribute("position");

      if (oldPositions.count === newPositions.count) {
        // 直接复制顶点数据（性能优化）
        oldPositions.copy(newPositions);
        oldPositions.needsUpdate = true;
      } else {
        // 顶点数不同时替换整个几何体
        tubeMesh.geometry = newTubeGeometry;
        currentTubeGeometry = newTubeGeometry;
      }
    }
  }

  // 更新样条曲线数据（用于计算）
  if (splineMesh && curve) {
    const curvePoints = curve.getPoints(70);
    const positions = splineMesh.geometry.getAttribute("position");

    if (positions && positions.count === curvePoints.length) {
      for (let i = 0; i < curvePoints.length; i++) {
        positions.setXYZ(
          i,
          curvePoints[i].x,
          curvePoints[i].y,
          curvePoints[i].z
        );
      }
      positions.needsUpdate = true;
    }
  }

  // 继续动画循环
  requestAnimationFrame(animate);
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
};
</script>
<style></style>
