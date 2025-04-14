<!--
 * @Author: caopeng
 * @Date: 2025-04-14 10:57:51
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-14 12:51:39
 * @Description: 请填写简介
-->
<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
let canvasRef = ref(null); // 定义一个ref引用，用于获取canvas元素
let scene = null; // 定义场景
let camera = null; // 定义相机
let renderer = null; // 定义渲染器
let controls = null; // 定义控制器
let timeUniform = { value: 0 };
let ripples = [];
let order = 0;
let drops = [];
let colorScene;
let normalTarget = new THREE.WebGLRenderTarget(
  window.innerWidth,
  window.innerHeight
);
let ball;
let i = 0;
let squareGeometry;
let minusMaterial;
let plusMaterial;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  const bgColor = new THREE.Color(0.5, 0.5, 0.5); // 设置背景颜色
  scene.background = bgColor;
  // 添加辅助坐标轴
  const axesHelper = new THREE.AxesHelper(15); // 创建一个长度为15的坐标轴
  scene.add(axesHelper); // 将坐标轴添加到场景中
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(15, 0, 15);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer();
  // 设置渲染器大小
  renderer.setSize(window.innerWidth, window.innerHeight);
  // 将渲染器添加到canvasRef中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);

  // 创建一个平面
  squareGeometry = new THREE.PlaneGeometry(10, 10);
  let gray50 = new THREE.Color(0.5, 0.5, 0.5);
  minusMaterial = new THREE.MeshBasicMaterial({
    color: gray50,
    blending: THREE.CustomBlending, // 设置混合模式
    blendEquation: THREE.ReverseSubtractEquation, // 设置混合方程
    blendSrc: THREE.SrcAlphaFactor, // 设置源因子
    blendDst: THREE.OneFactor, // 设置目标因子
    blendEquationAlpha: THREE.AddEquation, // 设置透明度混合方程
    depthTest: false, // 关闭深度测试
    depthWrite: false, // 关闭深度写入
    transparent: true, // 开启透明度
    side: THREE.DoubleSide, // 设置双面
  });
  let textureLoader = new THREE.TextureLoader();
  let texture = textureLoader.load("/texture/ripple.png");
  plusMaterial = new THREE.MeshBasicMaterial({
    map: texture, // 设置纹理贴图
    blending: THREE.CustomBlending, // 设置混合模式
    blendEquation: THREE.AddEquation, // 设置混合方程
    blendSrc: THREE.SrcAlphaFactor, // 设置源因子
    blendDst: THREE.OneFactor, // 设置目标因子
    depthTest: false, // 关闭深度测试
    depthWrite: false, // 关闭深度写入
    transparent: true, // 开启透明度
    side: THREE.DoubleSide, // 设置双面
  });

  normalTarget = new THREE.WebGLRenderTarget(
    window.innerWidth,
    window.innerHeight
  );
  normalTarget.texture.colorSpace = THREE.NoColorSpace;
  let normalTextureUniform = { value: normalTarget.texture };
  colorScene = new THREE.Scene();
  THREE.ColorManagement.enabled = true;
  const pmremGenerator = new THREE.PMREMGenerator(renderer);
  pmremGenerator.compileCubemapShader();

  const cubeLoader = new THREE.CubeTextureLoader();
  const envMap = cubeLoader.load(
    [
      "/texture/px.jpg",
      "/texture/nx.jpg",
      "/texture/py.jpg",
      "/texture/ny.jpg",
      "/texture/pz.jpg",
      "/texture/nz.jpg",
    ],
    function (texture) {
      const pmremTexture = pmremGenerator.fromCubemap(texture).texture;
      colorScene.environment = texture;
      colorScene.environmentRotation.set(Math.PI / 2, 0, Math.PI, "XYZ");
      colorScene.background = texture;
      colorScene.backgroundRotation.set(Math.PI / 2, 0, Math.PI, "XYZ");
    }
  );
  let waterGeometry = new THREE.PlaneGeometry(100, 100);
  let waterMaterial = new THREE.MeshStandardMaterial({
    color: 0x5a75a0,
    metalness: 1,
    roughness: 0.27,
    normalMap: new THREE.TextureLoader().load(
      "/texture/water_normal.png",
      (texture) => {
        texture.flipY = false;
      }
    ),
    normalMapType: THREE.ObjectSpaceNormalMap,
    side: THREE.DoubleSide,
  });
  waterMaterial.normalMap.wrapS = THREE.RepeatWrapping;
  waterMaterial.normalMap.wrapT = THREE.RepeatWrapping;
  waterMaterial.normalMap.repeat.set(10, 10);

  let resolutionUniform = {
    value: new THREE.Vector2(window.innerWidth, window.innerHeight),
  };
  waterMaterial.onBeforeCompile = (shader) => {
    shader.uniforms.time = timeUniform;
    shader.uniforms.resolution = resolutionUniform;
    shader.uniforms.normalDisturbance = normalTextureUniform;

    let chunk = "";
    for (let dir = 0.1; dir < 2 * Math.PI; dir += (2 * Math.PI) / 3) {
      chunk += `{
  				mat2 rot2d = mat2(${Math.cos(dir)}, ${-Math.sin(dir)}, ${Math.sin(
        dir
      )}, ${Math.cos(dir)});
  				vec3 subNormal = texture2D( normalMap, rot2d * vNormalMapUv + vec2(time*0.03, ${dir}) ).rgb * 2.0 - 1.0;
  				subNormal.xy = rot2d * subNormal.xy;
  				normal += subNormal;
  			}`;
    }
    shader.fragmentShader =
      "uniform float time;\n" +
      "uniform vec2 resolution;\n" +
      "uniform sampler2D normalDisturbance;\n" +
      shader.fragmentShader.replace(
        "\t#include <normal_fragment_maps>",
        chunk +
          `
  				vec3 ripple = texture2D( normalDisturbance, gl_FragCoord.xy / resolution ).rgb * 2.0 - 1.0;
  				normal += 3.0 * ripple;
  				#ifdef FLIP_SIDED
  					normal = - normal;
  				#endif
  				#ifdef DOUBLE_SIDED
  					normal = normal * faceDirection;
  				#endif
  				normal = normalize( normalMatrix * normal );
  				`
      );
  };
  let waterPlane = new THREE.Mesh(waterGeometry, waterMaterial);
  colorScene.add(waterPlane);

  ball = new THREE.Mesh(
    new THREE.SphereGeometry(0.1, 16, 16),
    new THREE.MeshStandardMaterial({ roughness: 0, metalness: 1 })
  );
  colorScene.add(ball);
};
const animate = () => {
  let t = performance.now() / 1000;
  let dt = t - timeUniform.value;
  timeUniform.value = t;
  requestAnimationFrame(animate);
  let x = Math.sin(Math.sqrt(5) * timeUniform.value) * 5;
  let y = Math.cos(timeUniform.value) * 5;
  let vx = Math.sqrt(5) * Math.cos(Math.sqrt(5) * timeUniform.value) * 5;
  let vy = Math.sin(timeUniform.value) * 5;
  ball.position.set(x, y, 0);

  if (i++ % 3 == 0) {
    makeRipple(x, y, (vx ** 2 + vy ** 2) ** 0.5 / 30);
  }
  if (i % 10 == 1) {
    makeDrop(Math.random() * 30 - 15, Math.random() * 30 - 15, 20);
  }
  updateRipples(dt);
  updateDrops(dt);

  // 渲染场景和相机
  // renderer.setRenderTarget(normalTarget);
  renderer.render(scene, camera);
  renderer.render(colorScene, camera);
  controls.update();
};
function updateDrops(dt) {
  for (let drop of drops) {
    drop.position.z += drop.userData.vz * dt;
    drop.userData.vz -= 9.81 * dt;
    if (drop.position.z < 0) {
      colorScene.remove(drop);
      drops.splice(drops.indexOf(drop), 1);
      makeRipple(drop.position.x, drop.position.y, 0.5);
    }
  }
}
function updateRipples(dt) {
  for (let ripple of ripples) {
    ripple.minus.scale.x += dt;
    ripple.minus.scale.y += dt;
    ripple.minus.material.opacity -= dt / 6;
    ripple.plus.scale.x += dt;
    ripple.plus.scale.y += dt;
    ripple.plus.material.opacity -= dt / 6;
    if (ripple.minus.material.opacity <= 0) {
      scene.remove(ripple.minus);
      scene.remove(ripple.plus);
      ripples.splice(ripples.indexOf(ripple), 1);
    }
  }
}
function makeRipple(x, y, strength) {
  let minusSquare = new THREE.Mesh(squareGeometry, minusMaterial.clone());
  scene.add(minusSquare);
  minusSquare.renderOrder = order++;
  minusSquare.position.set(x, y, 0);
  minusSquare.scale.set(0.1, 0.1, 1);
  minusSquare.material.opacity = strength;

  let plusSquare = new THREE.Mesh(squareGeometry, plusMaterial.clone());
  scene.add(plusSquare);
  plusSquare.renderOrder = order++;
  plusSquare.position.set(x, y, 0);
  plusSquare.scale.set(0.1, 0.1, 1);
  plusSquare.material.opacity = strength;
  ripples.push({ minus: minusSquare, plus: plusSquare });
}
function makeDrop(x, y, z) {
  let drop = new THREE.Mesh(
    new THREE.SphereGeometry(0.1, 16, 16),
    new THREE.MeshStandardMaterial({ roughness: 0, metalness: 1 })
  );
  drop.position.set(x, y, z);
  drop.userData.vz = 0;
  colorScene.add(drop);
  drops.push(drop);
}
</script>
<style scoped></style>
