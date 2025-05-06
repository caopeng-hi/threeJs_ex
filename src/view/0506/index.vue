<!--
 * @Author: caopeng
 * @Date: 2025-05-06 11:43:36
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-05-06 17:54:14
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
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import anime from "animejs";
import { createNoise3D, createNoise4D } from "simplex-noise";
const canvasRef = ref(null); // 定义一个ref对象来引用canvas元素
let scene, camera, renderer, controls, clock; // 定义场景、相机、渲染器和控制器变量
let composer, bloomPass;
let particlesGeometry, particlesMaterial, particleSystem;
let currentPositions, sourcePositions, targetPositions, swarmPositions;
let particleSizes, particleOpacities, particleEffectStrengths;
let noise3D, noise4D;

let morphTimeline = null;
let isInitialized = false;
let isMorphing = false;
const CONFIG = {
  particleCount: 15000,
  shapeSize: 14,
  swarmDistanceFactor: 1.5,
  swirlFactor: 4.0,
  noiseFrequency: 0.1,
  noiseTimeScale: 0.04,
  noiseMaxStrength: 2.8,
  colorScheme: "fire",
  morphDuration: 4000,
  particleSizeRange: [0.08, 0.25],
  starCount: 18000,
  bloomStrength: 1.3,
  bloomRadius: 0.5,
  bloomThreshold: 0.05,
  idleFlowStrength: 0.25,
  idleFlowSpeed: 0.08,
  idleRotationSpeed: 0.02,
  morphSizeFactor: 0.5,
  morphBrightnessFactor: 0.6,
};
const SHAPES = [
  { name: "Sphere", generator: generateSphere },
  { name: "Cube", generator: generateCube },
  { name: "Pyramid", generator: generatePyramid },
  { name: "Torus", generator: generateTorus },
  { name: "Galaxy", generator: generateGalaxy },
  { name: "Wave", generator: generateWave },
];
let currentShapeIndex = 0;

const morphState = { progress: 0.0 };

const COLOR_SCHEMES = {
  fire: { startHue: 0, endHue: 45, saturation: 0.95, lightness: 0.6 },
  neon: { startHue: 300, endHue: 180, saturation: 1.0, lightness: 0.65 },
  nature: { startHue: 90, endHue: 160, saturation: 0.85, lightness: 0.55 },
  rainbow: { startHue: 0, endHue: 360, saturation: 0.9, lightness: 0.6 },
};
const tempVec = new THREE.Vector3();
const sourceVec = new THREE.Vector3();
const targetVec = new THREE.Vector3();
const swarmVec = new THREE.Vector3();
const noiseOffset = new THREE.Vector3();
const flowVec = new THREE.Vector3();
const bezPos = new THREE.Vector3();
const swirlAxis = new THREE.Vector3();
const currentVec = new THREE.Vector3();
onMounted(() => {
  init();
  animate();
});
// 初始化函数
function init() {
  // 创建场景
  scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(0x000308, 0.03);
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, 0, 5);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
    powerPreference: "high-performance",
  }); // 开启抗锯齿
  renderer.setSize(window.innerWidth, window.innerHeight); // 设置渲染器大小
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // 设置像素比
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.1;
  // 将渲染器添加到canvas元素中
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.minDistance = 5;
  controls.maxDistance = 80;
  controls.autoRotate = true;
  controls.autoRotateSpeed = 0.3;

  scene.add(new THREE.AmbientLight(0x404060));
  const dirLight1 = new THREE.DirectionalLight(0xffffff, 1.5);
  dirLight1.position.set(15, 20, 10);
  scene.add(dirLight1);
  const dirLight2 = new THREE.DirectionalLight(0x88aaff, 0.9);
  dirLight2.position.set(-15, -10, -15);
  scene.add(dirLight2);

  clock = new THREE.Clock();
  noise3D = createNoise3D(() => Math.random());
  noise4D = createNoise4D(() => Math.random());

  const starVertices = [];
  const starSizes = [];
  const starColors = [];
  const starGeometry = new THREE.BufferGeometry();

  for (let i = 0; i < CONFIG.starCount; i++) {
    tempVec.set(
      THREE.MathUtils.randFloatSpread(400),
      THREE.MathUtils.randFloatSpread(400),
      THREE.MathUtils.randFloatSpread(400)
    );
    if (tempVec.length() < 100) tempVec.setLength(100 + Math.random() * 300);
    starVertices.push(tempVec.x, tempVec.y, tempVec.z);
    starSizes.push(Math.random() * 0.15 + 0.05);
    const color = new THREE.Color();
    if (Math.random() < 0.1) {
      color.setHSL(Math.random(), 0.7, 0.65);
    } else {
      color.setHSL(0.6, Math.random() * 0.1, 0.8 + Math.random() * 0.2);
    }
    starColors.push(color.r, color.g, color.b);
  }
  starGeometry.setAttribute(
    "position",
    new THREE.Float32BufferAttribute(starVertices, 3)
  );
  starGeometry.setAttribute(
    "color",
    new THREE.Float32BufferAttribute(starColors, 3)
  );
  starGeometry.setAttribute(
    "size",
    new THREE.Float32BufferAttribute(starSizes, 1)
  );

  const starMaterial = new THREE.ShaderMaterial({
    uniforms: { pointTexture: { value: createStarTexture() } },
    vertexShader: `
                      attribute float size; varying vec3 vColor; varying float vSize;
                      void main() {
                           vColor = color; vSize = size; vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
                           gl_PointSize = size * (400.0 / -mvPosition.z); gl_Position = projectionMatrix * mvPosition;
                      }`,
    fragmentShader: `
                      uniform sampler2D pointTexture; varying vec3 vColor; varying float vSize;
                      void main() {
                           float alpha = texture2D(pointTexture, gl_PointCoord).a; if (alpha < 0.1) discard;
                           gl_FragColor = vec4(vColor, alpha * 0.9);
                      }`,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    transparent: true,
    vertexColors: true,
  });
  scene.add(new THREE.Points(starGeometry, starMaterial));

  targetPositions = SHAPES.map((shape) =>
    shape.generator(CONFIG.particleCount, CONFIG.shapeSize)
  );
  particlesGeometry = new THREE.BufferGeometry();

  currentPositions = new Float32Array(targetPositions[0]);
  sourcePositions = new Float32Array(targetPositions[0]);
  swarmPositions = new Float32Array(CONFIG.particleCount * 3);
  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(currentPositions, 3)
  );

  particleSizes = new Float32Array(CONFIG.particleCount);
  particleOpacities = new Float32Array(CONFIG.particleCount);
  particleEffectStrengths = new Float32Array(CONFIG.particleCount);
  for (let i = 0; i < CONFIG.particleCount; i++) {
    particleSizes[i] = THREE.MathUtils.randFloat(
      CONFIG.particleSizeRange[0],
      CONFIG.particleSizeRange[1]
    );
    particleOpacities[i] = 1.0;
    particleEffectStrengths[i] = 0.0;
  }
  particlesGeometry.setAttribute(
    "size",
    new THREE.BufferAttribute(particleSizes, 1)
  );
  particlesGeometry.setAttribute(
    "opacity",
    new THREE.BufferAttribute(particleOpacities, 1)
  );
  particlesGeometry.setAttribute(
    "aEffectStrength",
    new THREE.BufferAttribute(particleEffectStrengths, 1)
  );

  const colors = new Float32Array(CONFIG.particleCount * 3);
  updateColorArray(colors, currentPositions);
  particlesGeometry.setAttribute("color", new THREE.BufferAttribute(colors, 3));

  particlesMaterial = new THREE.ShaderMaterial({
    uniforms: {
      pointTexture: { value: createStarTexture() },
    },
    vertexShader: `
                      attribute float size;
                      attribute float opacity;
                      attribute float aEffectStrength;
                      varying vec3 vColor;
                      varying float vOpacity;
                      varying float vEffectStrength;

                      void main() {
                           vColor = color;
                           vOpacity = opacity;
                           vEffectStrength = aEffectStrength;

                           vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);

                           float sizeScale = 1.0 - vEffectStrength * ${CONFIG.morphSizeFactor.toFixed(
                             2
                           )};
                           gl_PointSize = size * sizeScale * (400.0 / -mvPosition.z);

                           gl_Position = projectionMatrix * mvPosition;
                      }
                 `,
    fragmentShader: `
                      uniform sampler2D pointTexture;
                      varying vec3 vColor;
                      varying float vOpacity;
                      varying float vEffectStrength;

                      void main() {
                           float alpha = texture2D(pointTexture, gl_PointCoord).a;
                           if (alpha < 0.05) discard;

                           vec3 finalColor = vColor * (1.0 + vEffectStrength * ${CONFIG.morphBrightnessFactor.toFixed(
                             2
                           )});

                           gl_FragColor = vec4(finalColor, alpha * vOpacity);
                      }
                 `,
    blending: THREE.AdditiveBlending,
    depthTest: true,
    depthWrite: false,
    transparent: true,
    vertexColors: true,
  });

  particleSystem = new THREE.Points(particlesGeometry, particlesMaterial);
  scene.add(particleSystem);
  composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));
  bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    CONFIG.bloomStrength,
    CONFIG.bloomRadius,
    CONFIG.bloomThreshold
  );
  composer.addPass(bloomPass);
}
function animate() {
  requestAnimationFrame(animate); // 循环调用animate函数

  const elapsedTime = clock.getElapsedTime();
  const deltaTime = clock.getDelta();
  const positions = particlesGeometry.attributes.position.array;
  const effectStrengths = particlesGeometry.attributes.aEffectStrength.array;
  if (isMorphing) {
    updateMorphAnimation(positions, effectStrengths, elapsedTime, deltaTime);
  } else {
    updateIdleAnimation(positions, effectStrengths, elapsedTime, deltaTime);
  }
  particlesGeometry.attributes.position.needsUpdate = true;
  if (isMorphing || particlesGeometry.attributes.aEffectStrength.needsUpdate) {
    particlesGeometry.attributes.aEffectStrength.needsUpdate = true;
  }
  composer.render(deltaTime);
  renderer.render(scene, camera); // 渲染场景
  controls.update(); // 更新控制器
}
function generateSphere(count, size) {
  const points = new Float32Array(count * 3);
  const phi = Math.PI * (Math.sqrt(5) - 1);
  for (let i = 0; i < count; i++) {
    const y = 1 - (i / (count - 1)) * 2;
    const radius = Math.sqrt(1 - y * y);
    const theta = phi * i;
    const x = Math.cos(theta) * radius;
    const z = Math.sin(theta) * radius;
    points[i * 3] = x * size;
    points[i * 3 + 1] = y * size;
    points[i * 3 + 2] = z * size;
  }
  return points;
}
function generateCube(count, size) {
  const points = new Float32Array(count * 3);
  const halfSize = size / 2;
  for (let i = 0; i < count; i++) {
    const face = Math.floor(Math.random() * 6);
    const u = Math.random() * size - halfSize;
    const v = Math.random() * size - halfSize;
    switch (face) {
      case 0:
        points.set([halfSize, u, v], i * 3);
        break;
      case 1:
        points.set([-halfSize, u, v], i * 3);
        break;
      case 2:
        points.set([u, halfSize, v], i * 3);
        break;
      case 3:
        points.set([u, -halfSize, v], i * 3);
        break;
      case 4:
        points.set([u, v, halfSize], i * 3);
        break;
      case 5:
        points.set([u, v, -halfSize], i * 3);
        break;
    }
  }
  return points;
}
function generatePyramid(count, size) {
  const points = new Float32Array(count * 3);
  const halfBase = size / 2;
  const height = size * 1.2;
  const apex = new THREE.Vector3(0, height / 2, 0);
  const baseVertices = [
    new THREE.Vector3(-halfBase, -height / 2, -halfBase),
    new THREE.Vector3(halfBase, -height / 2, -halfBase),
    new THREE.Vector3(halfBase, -height / 2, halfBase),
    new THREE.Vector3(-halfBase, -height / 2, halfBase),
  ];
  const baseArea = size * size;
  const sideFaceHeight = Math.sqrt(Math.pow(height, 2) + Math.pow(halfBase, 2));
  const sideFaceArea = 0.5 * size * sideFaceHeight;
  const totalArea = baseArea + 4 * sideFaceArea;
  const baseWeight = baseArea / totalArea;
  const sideWeight = sideFaceArea / totalArea;
  for (let i = 0; i < count; i++) {
    const r = Math.random();
    let p = new THREE.Vector3();
    let u, v;
    if (r < baseWeight) {
      u = Math.random();
      v = Math.random();
      p.lerpVectors(baseVertices[0], baseVertices[1], u);
      const p2 = new THREE.Vector3().lerpVectors(
        baseVertices[3],
        baseVertices[2],
        u
      );
      p.lerp(p2, v);
    } else {
      const faceIndex = Math.floor((r - baseWeight) / sideWeight);
      const v1 = baseVertices[faceIndex];
      const v2 = baseVertices[(faceIndex + 1) % 4];
      u = Math.random();
      v = Math.random();
      if (u + v > 1) {
        u = 1 - u;
        v = 1 - v;
      }
      p.addVectors(v1, tempVec.subVectors(v2, v1).multiplyScalar(u));
      p.add(tempVec.subVectors(apex, v1).multiplyScalar(v));
    }
    points.set([p.x, p.y, p.z], i * 3);
  }
  return points;
}
function generateTorus(count, size) {
  const points = new Float32Array(count * 3);
  const R = size * 0.7;
  const r = size * 0.3;
  for (let i = 0; i < count; i++) {
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.random() * Math.PI * 2;
    const x = (R + r * Math.cos(phi)) * Math.cos(theta);
    const y = r * Math.sin(phi);
    const z = (R + r * Math.cos(phi)) * Math.sin(theta);
    points[i * 3] = x;
    points[i * 3 + 1] = y;
    points[i * 3 + 2] = z;
  }
  return points;
}
function generateGalaxy(count, size) {
  const points = new Float32Array(count * 3);
  const arms = 4;
  const armWidth = 0.6;
  const bulgeFactor = 0.3;
  for (let i = 0; i < count; i++) {
    const t = Math.pow(Math.random(), 1.5);
    const radius = t * size;
    const armIndex = Math.floor(Math.random() * arms);
    const armOffset = (armIndex / arms) * Math.PI * 2;
    const rotationAmount = (radius / size) * 6;
    const angle = armOffset + rotationAmount;
    const spread = (Math.random() - 0.5) * armWidth * (1 - radius / size);
    const theta = angle + spread;
    const x = radius * Math.cos(theta);
    const z = radius * Math.sin(theta);
    const y =
      (Math.random() - 0.5) * size * 0.1 * (1 - (radius / size) * bulgeFactor);
    points[i * 3] = x;
    points[i * 3 + 1] = y;
    points[i * 3 + 2] = z;
  }
  return points;
}
function generateWave(count, size) {
  const points = new Float32Array(count * 3);
  const waveScale = size * 0.4;
  const frequency = 3;
  for (let i = 0; i < count; i++) {
    const u = Math.random() * 2 - 1;
    const v = Math.random() * 2 - 1;
    const x = u * size;
    const z = v * size;
    const dist = Math.sqrt(u * u + v * v);
    const angle = Math.atan2(v, u);
    const y =
      Math.sin(dist * Math.PI * frequency) *
      Math.cos(angle * 2) *
      waveScale *
      (1 - dist);
    points[i * 3] = x;
    points[i * 3 + 1] = y;
    points[i * 3 + 2] = z;
  }
  return points;
}

function createStarTexture() {
  const size = 64;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext("2d");
  const gradient = context.createRadialGradient(
    size / 2,
    size / 2,
    0,
    size / 2,
    size / 2,
    size / 2
  );
  gradient.addColorStop(0, "rgba(255,255,255,1)");
  gradient.addColorStop(0.2, "rgba(255,255,255,0.8)");
  gradient.addColorStop(0.5, "rgba(255,255,255,0.3)");
  gradient.addColorStop(1, "rgba(255,255,255,0)");
  context.fillStyle = gradient;
  context.fillRect(0, 0, size, size);
  return new THREE.CanvasTexture(canvas);
}
function updateMorphAnimation(
  positions,
  effectStrengths,
  elapsedTime,
  deltaTime
) {
  const t = morphState.progress;
  const targets = targetPositions[currentShapeIndex];
  const effectStrength = Math.sin(t * Math.PI);
  const currentSwirl = effectStrength * CONFIG.swirlFactor * deltaTime * 50;
  const currentNoise = effectStrength * CONFIG.noiseMaxStrength;

  for (let i = 0; i < CONFIG.particleCount; i++) {
    const i3 = i * 3;
    sourceVec.fromArray(sourcePositions, i3);
    swarmVec.fromArray(swarmPositions, i3);
    targetVec.fromArray(targets, i3);

    const t_inv = 1.0 - t;
    const t_inv_sq = t_inv * t_inv;
    const t_sq = t * t;
    bezPos.copy(sourceVec).multiplyScalar(t_inv_sq);
    bezPos.addScaledVector(swarmVec, 2.0 * t_inv * t);
    bezPos.addScaledVector(targetVec, t_sq);

    if (currentSwirl > 0.01) {
      tempVec.subVectors(bezPos, sourceVec);
      swirlAxis
        .set(
          noise3D(i * 0.02, elapsedTime * 0.1, 0),
          noise3D(0, i * 0.02, elapsedTime * 0.1 + 5),
          noise3D(elapsedTime * 0.1 + 10, 0, i * 0.02)
        )
        .normalize();
      tempVec.applyAxisAngle(
        swirlAxis,
        currentSwirl * (0.5 + Math.random() * 0.5)
      );
      bezPos.copy(sourceVec).add(tempVec);
    }

    if (currentNoise > 0.01) {
      const noiseTime = elapsedTime * CONFIG.noiseTimeScale;
      noiseOffset.set(
        noise4D(
          bezPos.x * CONFIG.noiseFrequency,
          bezPos.y * CONFIG.noiseFrequency,
          bezPos.z * CONFIG.noiseFrequency,
          noiseTime
        ),
        noise4D(
          bezPos.x * CONFIG.noiseFrequency + 100,
          bezPos.y * CONFIG.noiseFrequency + 100,
          bezPos.z * CONFIG.noiseFrequency + 100,
          noiseTime
        ),
        noise4D(
          bezPos.x * CONFIG.noiseFrequency + 200,
          bezPos.y * CONFIG.noiseFrequency + 200,
          bezPos.z * CONFIG.noiseFrequency + 200,
          noiseTime
        )
      );
      bezPos.addScaledVector(noiseOffset, currentNoise);
    }

    positions[i3] = bezPos.x;
    positions[i3 + 1] = bezPos.y;
    positions[i3 + 2] = bezPos.z;

    effectStrengths[i] = effectStrength;
  }
  particlesGeometry.attributes.aEffectStrength.needsUpdate = true;
}

function updateIdleAnimation(
  positions,
  effectStrengths,
  elapsedTime,
  deltaTime
) {
  const breathScale = 1.0 + Math.sin(elapsedTime * 0.5) * 0.015;
  const timeScaled = elapsedTime * CONFIG.idleFlowSpeed;
  const freq = 0.1;

  let needsEffectStrengthReset = false;

  for (let i = 0; i < CONFIG.particleCount; i++) {
    const i3 = i * 3;
    sourceVec.fromArray(sourcePositions, i3);
    tempVec.copy(sourceVec).multiplyScalar(breathScale);
    flowVec.set(
      noise4D(tempVec.x * freq, tempVec.y * freq, tempVec.z * freq, timeScaled),
      noise4D(
        tempVec.x * freq + 10,
        tempVec.y * freq + 10,
        tempVec.z * freq + 10,
        timeScaled
      ),
      noise4D(
        tempVec.x * freq + 20,
        tempVec.y * freq + 20,
        tempVec.z * freq + 20,
        timeScaled
      )
    );
    tempVec.addScaledVector(flowVec, CONFIG.idleFlowStrength);
    currentVec.fromArray(positions, i3);
    currentVec.lerp(tempVec, 0.05);
    positions[i3] = currentVec.x;
    positions[i3 + 1] = currentVec.y;
    positions[i3 + 2] = currentVec.z;

    if (effectStrengths[i] !== 0.0) {
      effectStrengths[i] = 0.0;
      needsEffectStrengthReset = true;
    }
  }
  if (needsEffectStrengthReset) {
    particlesGeometry.attributes.aEffectStrength.needsUpdate = true;
  }
}
</script>

<style lang="scss" scoped></style>
