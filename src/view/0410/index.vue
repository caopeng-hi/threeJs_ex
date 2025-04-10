<!--
 * @Author: caopeng
 * @Date: 2025-04-10 11:25:16
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-10 14:30:42
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入Vue组合式API
import { onMounted, onUnmounted, ref } from "vue";
// 引入pane调试工具
import { Pane } from "tweakpane";
// 引入公共噪声函数
import snoise from "../../shader/common/noise.glsl?raw";
let renderer,
  camera,
  controls,
  scene,
  composer,
  bloomPass,
  outputPass,
  renderPass;
let scale = 1.0;
let cubeTexture;
// 定义要在面板上调试的参数
let tweaks = {
  dissolveProgress: -7.0, // 对应后面溶解效果的进度
};
const pane = new Pane();
const canvasRef = ref(null);
const dissolveUniformData = {
  uEdgeColor: { value: new THREE.Color(0x4d9bff) }, // 边缘颜色
  uFreq: { value: 0.25 }, // 噪声频率
  uAmp: { value: 16.0 }, // 噪声振幅
  uProgress: { value: -7.0 }, // 溶解进度
  uEdge: { value: 0.8 }, // 溶解边缘宽度
};
const init = async () => {
  // 创建场景并设置背景色
  scene = new THREE.Scene();

  let cubeTexturePaths = generateCubeUrls("./img/", ".png");

  // 异步加载立方体贴图
  const cubeTextureLoader = new THREE.CubeTextureLoader();
  cubeTexture = cubeTextureLoader.load(cubeTexturePaths);

  scene.background = cubeTexture;
  scene.environment = cubeTexture;
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 1, 14); // 适当拉远一点，能看到球体全貌
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;

  // 1. 创建球体几何
  const sphere = new THREE.SphereGeometry(4.5, 140, 140);
  let meshGeo = sphere;

  // 2. 创建材质
  const phyMat = new THREE.MeshPhysicalMaterial();
  phyMat.color = new THREE.Color(0x636363); // 初始颜色为灰色
  phyMat.metalness = 2.0; // 金属度(可以根据需求调试)
  phyMat.roughness = 0.0; // 粗糙度(越低越光滑)
  phyMat.side = THREE.DoubleSide; // 双面渲染

  // 3. 组合几何体和材质，生成网格
  let mesh = new THREE.Mesh(meshGeo, phyMat);
  scene.add(mesh);
  phyMat.onBeforeCompile = (shader) => {
    setupUniforms(shader, dissolveUniformData);
    setupDissolveShader(shader);
  };
  // 绑定并监听事件
  let progressBinding = pane
    .addBinding(tweaks, "dissolveProgress", {
      min: -20,
      max: 20,
      step: 0.0001,
      label: "Progress",
    })
    .on("change", (obj) => {
      dissolveUniformData.uProgress.value = obj.value;
    });
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
onMounted(() => {
  init();
  animate();
});
// 定义一个函数，用来生成六张立方体纹理的路径
function generateCubeUrls(prefix, postfix) {
  return [
    prefix + "posx" + postfix,
    prefix + "negx" + postfix,
    prefix + "posy" + postfix,
    prefix + "negy" + postfix,
    prefix + "posz" + postfix,
    prefix + "negz" + postfix,
  ];
}
function setupUniforms(shader, uniforms) {
  const keys = Object.keys(uniforms);
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    shader.uniforms[key] = uniforms[key];
  }
}
function setupDissolveShader(shader) {
  // 顶点着色器：添加一个变量 vPos 用来传递顶点坐标到片段着色器
  shader.vertexShader = shader.vertexShader.replace(
    "#include <common>",
    `#include <common>
    varying vec3 vPos;`
  );
  shader.vertexShader = shader.vertexShader.replace(
    "#include <begin_vertex>",
    `#include <begin_vertex>
    vPos = position;`
  );

  // 片段着色器：插入定义好的噪声 snoise，以及自定义 uniform
  shader.fragmentShader = shader.fragmentShader.replace(
    "#include <common>",
    `#include <common>
    varying vec3 vPos;

    uniform float uFreq;
    uniform float uAmp;
    uniform float uProgress;
    uniform float uEdge;
    uniform vec3  uEdgeColor;

    ${snoise} // 这里注入我们的 snoise 函数
   `
  );

  // 在片段着色器中加入溶解逻辑
  shader.fragmentShader = shader.fragmentShader.replace(
    "#include <dithering_fragment>",
    `#include <dithering_fragment>

   float noise = snoise(vPos * uFreq) * uAmp;

   // 如果噪声值小于进度阈值，直接 discard(丢弃该像素)
   if (noise < uProgress) discard;

   // 计算边缘范围  uProgress + uEdge
   float edgeWidth = uProgress + uEdge;

   // 当噪声值处于 [uProgress, edgeWidth] 时，渲染成特定边缘颜色
   if (noise > uProgress && noise < edgeWidth) {
     gl_FragColor = vec4(uEdgeColor, noise);
   } else {
     // 其它区域保持原本颜色（这里承接了物理材质默认的颜色）
     gl_FragColor = vec4(gl_FragColor.xyz, 1.0);
   }
   `
  );
}
</script>
<style scoped></style>
