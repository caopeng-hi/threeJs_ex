<template>
  <div class="contentRef" ref="contentRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
// 引入控制器
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 引入顶点着色器
import vertexShader from "../../shader/0322/vert.glsl?raw";
// 引入片元着色器
import fragmentShader from "../../shader/0322/frag.glsl?raw";
// 引入管道着色器
import veinVertexShader from "../../shader/0322/veinVert.glsl?raw";
import veinFragmentShader from "../../shader/0322/veinFrag.glsl?raw";
// 引入多面体着色器
import shardVertexShader from "../../shader/0322/shardVert.glsl?raw";
import shardFragmentShader from "../../shader/0322/shardFrag.glsl?raw";
// 引入粒子着色器
import partVertexShader from "../../shader/0322/partVert.glsl?raw";
import partFragmentShader from "../../shader/0322/partFrag.glsl?raw";
// 引入射线着色器
import rayVertexShader from "../../shader/0322/rayVert.glsl?raw";
import rayFragmentShader from "../../shader/0322/rayFrag.glsl?raw";
// 引入EffectComposer 后期处理
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";
// 引入RenderPass
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
// 引入UnrealBloomPass
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass";
// 引入ShaderPass
import { ShaderPass } from "three/examples/jsm/postprocessing/ShaderPass";
// 引入OutlinePass
import { OutputPass } from "three/examples/jsm/postprocessing/OutputPass";

const contentRef = ref(null);
let scene, camera, renderer, controls, clock, particleField, rayParticles;
let prismCore = new THREE.Group();
let energyVeins = new THREE.Group();
let crystalShards = new THREE.Group();
let rayParticleCount = 1000;
let targetRotation = new THREE.Vector2(0, 0);
let composer;
onMounted(() => {
  init();
  animate();
});
const init = () => {
  // 创建场景
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);
  // 添加坐标辅助线
  const axesHelper = new THREE.AxesHelper(5);
  scene.add(axesHelper);
  // 增减指数雾气
  scene.fog = new THREE.FogExp2(0x000000, 0.035);
  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 1.8, 4.0);
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  renderer.toneMapping = THREE.ACESFilmicToneMapping; // 设置色调映射
  renderer.toneMappingExposure = 1.5; // 设置色调映射曝光
  contentRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.autoRotate = true;
  controls.autoRotateSpeed = 0.5;
  controls.minDistance = 1.8;
  controls.maxDistance = 6.5;
  controls.enablePan = false;

  clock = new THREE.Clock();
  // 添加环境光
  const light = new THREE.AmbientLight(0x302050, 0.8);
  scene.add(light);
  // 添加半球光
  const hemisphereLight = new THREE.HemisphereLight(0x606090, 0x080820, 0.5);
  scene.add(hemisphereLight);
  // 添加点光源
  const pointLight = new THREE.PointLight(0xffa0e0, 2.5, 10);
  pointLight.position.set(1.5, 1.5, 1.5);
  // 添加点光源2
  const pointLight2 = new THREE.PointLight(0x80c0ff, 1.8, 8);
  pointLight2.position.set(-2, -1, 1);
  scene.add(pointLight2);

  // 创建管道
  const veinGeometry = new THREE.TubeGeometry(
    createSpline(),
    64,
    0.08,
    8,
    false
  );
  // 创建管道材质材质
  const veinMaterial = new THREE.ShaderMaterial({
    vertexShader: veinVertexShader,
    fragmentShader: veinFragmentShader,
    uniforms: {
      time: { value: 0 },
      mouseInfluence: { value: new THREE.Vector2(0, 0) },
    },
    side: THREE.DoubleSide,
  });
  for (let i = 0; i < 16; i++) {
    const vein = new THREE.Mesh(veinGeometry, veinMaterial);
    vein.rotation.y = (i / 16) * Math.PI * 2;
    vein.scale.set(0.9 + Math.random() * 0.2, 1, 0.9 + Math.random() * 0.2);
    vein.userData = { pulseOffset: Math.random() * Math.PI * 2 };
    energyVeins.add(vein);
  }
  // 添加扭结几何体
  scene.add(energyVeins);
  // 创建粒子
  const shardGeometries = [
    new THREE.OctahedronGeometry(0.1, 0), // 八面体
    new THREE.TetrahedronGeometry(0.12, 0), // 四面体
    new THREE.DodecahedronGeometry(0.09, 0), // 十二面体
  ];
  // 添加多面体
  const shardCount = 350;
  for (let i = 0; i < shardCount; i++) {
    const geoIndex = Math.floor(Math.random() * shardGeometries.length);
    const hue = (i / shardCount) * 0.7 + 0.1 + Math.random() * 0.2;
    const shard = new THREE.Mesh(
      shardGeometries[geoIndex],
      createShardMaterial(hue)
    );
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.random() * Math.PI * 2;
    const torusRadius = 1.8;
    const tubeRadius = 0.4;
    shard.position.set(
      (torusRadius + tubeRadius * Math.cos(phi)) * Math.cos(theta),
      tubeRadius * Math.sin(phi),
      (torusRadius + tubeRadius * Math.cos(phi)) * Math.sin(theta)
    );
    shard.rotation.set(
      Math.random() * Math.PI,
      Math.random() * Math.PI,
      Math.random() * Math.PI
    );
    shard.scale.multiplyScalar(0.8 + Math.random() * 0.4);
    shard.userData = {
      orbitSpeed: 0.05 + Math.random() * 0.05,
      theta: theta,
      phi: phi,
      radius: torusRadius + Math.random() * 0.2,
      pulseSpeed: 0.5 + Math.random() * 1.0,
    };
    crystalShards.add(shard);
  }
  scene.add(crystalShards);

  //添加粒子几何体
  const particleCount = 5000;
  const particlesGeometry = new THREE.BufferGeometry();
  const positions = new Float32Array(particleCount * 3);
  const colors = new Float32Array(particleCount * 3);
  const sizes = new Float32Array(particleCount);

  for (let i = 0; i < particleCount; i++) {
    const i3 = i * 3;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.random() * Math.PI * 2;
    const torusRadius = 2;
    const tubeRadius = 0.8;
    positions[i3] =
      (torusRadius + tubeRadius * Math.cos(phi)) * Math.cos(theta);
    positions[i3 + 1] = tubeRadius * Math.sin(phi);
    positions[i3 + 2] =
      (torusRadius + tubeRadius * Math.cos(phi)) * Math.sin(theta);
    const hue = (theta / (Math.PI * 2)) * 0.7 + 0.2;
    const sat = 0.6 + Math.random() * 0.4;
    const light = 0.6 + Math.random() * 0.4;
    const color = new THREE.Color().setHSL(hue, sat, light);
    colors[i3] = color.r;
    colors[i3 + 1] = color.g;
    colors[i3 + 2] = color.b;
    sizes[i] = 0.02 + Math.random() * 0.04;
  }
  particlesGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(positions, 3)
  );
  particlesGeometry.setAttribute("color", new THREE.BufferAttribute(colors, 3));
  particlesGeometry.setAttribute("size", new THREE.BufferAttribute(sizes, 1));
  // 创建粒子材质
  const particleMaterial = new THREE.ShaderMaterial({
    vertexShader: partVertexShader,
    fragmentShader: partFragmentShader,
    uniforms: { time: { value: 0 } },
    transparent: true,
    vertexColors: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  // 创建粒子场
  particleField = new THREE.Points(particlesGeometry, particleMaterial);
  scene.add(particleField);

  // 创建射线几何体
  const rayGeometry = new THREE.BufferGeometry();
  const rayPositions = new Float32Array(rayParticleCount * 3);
  const rayColors = new Float32Array(rayParticleCount * 3);
  const raySizes = new Float32Array(rayParticleCount);
  const rayVelocities = new Float32Array(rayParticleCount * 3);
  const rayLifeProgress = new Float32Array(rayParticleCount);
  for (let i = 0; i < rayParticleCount; i++) {
    const i3 = i * 3;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.random() * Math.PI;
    const radius = 1.2;
    rayPositions[i3] = Math.sin(phi) * Math.cos(theta) * radius;
    rayPositions[i3 + 1] = Math.sin(phi) * Math.sin(theta) * radius;
    rayPositions[i3 + 2] = Math.cos(phi) * radius;
    const vel = new THREE.Vector3(
      rayPositions[i3],
      rayPositions[i3 + 1],
      rayPositions[i3 + 2]
    )
      .normalize()
      .multiplyScalar(0.05 + Math.random() * 0.03);
    rayVelocities[i3] = vel.x;
    rayVelocities[i3 + 1] = vel.y;
    rayVelocities[i3 + 2] = vel.z;
    const t = Math.random();
    const emberColor = new THREE.Color().lerpColors(
      new THREE.Color(1.0, 0.1, 0.0),
      new THREE.Color(1.0, 1.0, 0.2),
      t
    );
    rayColors[i3] = emberColor.r;
    rayColors[i3 + 1] = emberColor.g;
    rayColors[i3 + 2] = emberColor.b;
    raySizes[i] = 0.08 + Math.random() * 0.06;
    rayLifeProgress[i] = Math.random();
  }
  rayGeometry.setAttribute(
    "position",
    new THREE.BufferAttribute(rayPositions, 3)
  );
  rayGeometry.setAttribute("color", new THREE.BufferAttribute(rayColors, 3));
  rayGeometry.setAttribute("size", new THREE.BufferAttribute(raySizes, 1));
  rayGeometry.setAttribute(
    "velocity",
    new THREE.BufferAttribute(rayVelocities, 3)
  );
  rayGeometry.setAttribute(
    "lifeProgress",
    new THREE.BufferAttribute(rayLifeProgress, 1)
  );
  // 创建射线材质
  const rayMaterial = new THREE.ShaderMaterial({
    vertexShader: rayVertexShader,
    fragmentShader: rayFragmentShader,
    uniforms: { time: { value: 0 } },
    transparent: true,
    vertexColors: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  rayParticles = new THREE.Points(rayGeometry, rayMaterial);
  scene.add(rayParticles);
  // 合成效果
  composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    0.4,
    0.3,
    0.6
  );
  composer.addPass(bloomPass);
  const chromaticAberrationShader = {
    uniforms: {
      tDiffuse: { value: null },
      amount: { value: 0.003 },
      time: { value: 0 },
    },
    vertexShader: `   varying vec2 vUv; void main() {  vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);  }  `,
    fragmentShader: `  uniform sampler2D tDiffuse;  uniform float amount; uniform float time;  varying vec2 vUv; void main() { float  aberrationAmount = amount * (0.8 + sin(time * 1.2) * 0.2); float angle = time * 0.2;  vec2 dir = vec2(cos(angle), sin(angle)) * aberrationAmount;  vec4 colorR = texture2D(tDiffuse, vUv + dir);  vec4 colorG = exture2D(tDiffuse, vUv);  vec4 colorB = texture2D(tDiffuse, vUv - dir); gl_FragColor = vec4(colorR.r, colorG.g, colorB.b, 1.0);  }  `,
  };
  const chromaticAberrationPass = new ShaderPass(chromaticAberrationShader);
  composer.addPass(chromaticAberrationPass);
  const vignetteShader = {
    uniforms: {
      tDiffuse: { value: null },
      darkness: { value: 1.2 },
      offset: { value: 0.9 },
    },
    vertexShader: ` varying vec2 vUv;void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }  `,
    fragmentShader: `uniform sampler2D tDiffuse; uniform float darkness;  uniform float offset;    varying vec2 vUv; void main() {  vec4 color =  texture2D(tDiffuse, vUv);  vec2 uv = (vUv - 0.5) * 2.0; float vignetteAmount = smoothstep(offset, offset - 0.05, length(uv)); color.rgb *= mix(1.0, darkness, 1.0 - vignetteAmount);  gl_FragColor = color;  } `,
  };
  composer.addPass(new ShaderPass(vignetteShader));
  composer.addPass(new OutputPass());
};
const animate = () => {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
  const time = clock.getElapsedTime();
  prismCore.children.forEach((prism) => {
    prism.material.uniforms.uTime.value = time;
    prism.material.uniforms.uMouseInfluence.value.lerp(targetRotation, 0.05);
  });
};
// 创建几何体
const createPrism = () => {
  // 创建几何体
  const prismGeometry = new THREE.BoxGeometry(1, 1, 1, 8, 16, 8);
  // 创建材质
  const prismMaterial = new THREE.ShaderMaterial({
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
    uniforms: {
      uTime: { value: 0 },
      uMouseInfluence: { value: new THREE.Vector2(0, 0) },
    },
    side: THREE.DoubleSide,
  });
  // 创建网格
  for (let i = 0; i < 8; i++) {
    const prism = new THREE.Mesh(prismGeometry, prismMaterial);
    prism.rotation.y = (i / 8) * Math.PI * 2;
    prism.rotation.z = Math.PI / 4;
    prism.scale.set(
      0.8 + Math.sin(i * 0.5) * 0.2,
      1,
      0.8 + Math.cos(i * 0.5) * 0.2
    );
    prismCore.add(prism);
  }
  scene.add(prismCore);
};
const createSpline = () => {
  const points = [];
  const segments = 24;
  const radius = 1;
  const height = 2;
  const spiralTurns = 4;
  for (let i = 0; i <= segments; i++) {
    const t = i / segments;
    const angle = t * Math.PI * 2 * spiralTurns;
    const r = radius * (0.8 + Math.sin(t * Math.PI * 3) * 0.2);
    points.push(
      new THREE.Vector3(
        Math.cos(angle) * r,
        t * height - height / 2,
        Math.sin(angle) * r
      )
    );
  }
  return new THREE.CatmullRomCurve3(points);
};
const createShardMaterial = (hue) => {
  const color = new THREE.Color().setHSL(hue, 0.9, 0.6);
  return new THREE.ShaderMaterial({
    vertexShader: shardVertexShader,
    fragmentShader: shardFragmentShader,
    uniforms: {
      time: { value: 0 },
      uniqueOffset: { value: Math.random() * Math.PI * 2 },
      color: { value: color },
    },
    side: THREE.DoubleSide,
  });
};
</script>

<style lang="scss" scoped>
.contentRfef {
  width: 100vw;
  height: 100vh;
  margin: 0;
  overflow: hidden;
  background-color: #000;
}
</style>
