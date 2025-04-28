<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>
<script setup>
import { onMounted, ref } from "vue";
// 导入Three.js核心库和Vue组合式API
import * as THREE from "three";
// 导入Controls库
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { RectAreaLightHelper } from "three/examples/jsm/helpers/RectAreaLightHelper";
import { TextGeometry } from "three/addons/geometries/TextGeometry.js";
import { FontLoader } from "three/addons/loaders/FontLoader.js";
// 导入Reflector
import { Reflector } from "three/addons/objects/Reflector.js";
// 导入着色器
import vertexShader from "../../shader/0425/vert.glsl?raw";
import fragmentShader from "../../shader/0425/frag.glsl?raw";
// 导入雨着色器
import rainVertShader from "../../shader/0425/rainVert.glsl?raw";
import rainFragShader from "../../shader/0425/rainFrag.glsl?raw";
import { PackedMipMapGenerator } from "../../utils/PackedMipMapGenerator.ts";
import { FBO } from "../../utils/FBO.ts";
const canvasRef = ref(null);
let scene, camera, renderer, controls, mipmapper, mirrorFBO;
const config = {
  text: "hello world",
  color: "#ef77eb",
  rain: {
    count: 1000,
    speed: 1.5,
    debug: false,
  },
};
onMounted(() => {
  init();
  animate();
});
const init = () => {
  THREE.ColorManagement.enabled = false;
  // 创建场景
  scene = new THREE.Scene();

  // 创建相机
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  // 设置相机位置
  camera.position.set(0, 2, 9);
  const lookAt = new THREE.Vector3(0, 2, 0);
  camera.lookAt(lookAt);
  camera.updateMatrixWorld();
  scene.add(camera);
  // 创建渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
  renderer.useLegacyLights = true;
  canvasRef.value.appendChild(renderer.domElement);
  // 创建控制器
  controls = new OrbitControls(camera, renderer.domElement);

  // 添加灯光
  const pointLight1 = new THREE.PointLight(config.color, 12, 0, 0.8);
  pointLight1.position.set(0, 2, 0);
  scene.add(pointLight1);

  const pointLight2 = new THREE.PointLight("#81C8F2", 12, 0, 0.8);
  pointLight2.position.set(0, 25, 0);
  scene.add(pointLight2);

  // 矩形灯光
  const rectLight1 = new THREE.RectAreaLight("#89D7FF", 66, 19.1, 0.2);
  rectLight1.position.set(0, 8, -10);
  rectLight1.rotation.set(
    THREE.MathUtils.degToRad(90),
    THREE.MathUtils.degToRad(180),
    0
  );
  scene.add(rectLight1);
  // 添加矩形灯光辅助器
  const rectLightHelper = new RectAreaLightHelper(rectLight1);
  rectLight1.add(rectLightHelper);

  // 添加贴图图片
  const textureLoader = new THREE.TextureLoader();
  const aspTex = textureLoader.load("/texture/0425/asphalt-normal.jpg");
  aspTex.rotation = THREE.MathUtils.degToRad(90);
  aspTex.wrapS = aspTex.wrapT = THREE.RepeatWrapping;
  aspTex.repeat.set(5, 8);
  // 添加地面
  const wallMat = new THREE.MeshPhongMaterial({
    color: new THREE.Color("#111111"),
    normalMap: aspTex,
    normalScale: new THREE.Vector2(0.5, 0.5),
    shininess: 200,
  });
  const wall = new THREE.Mesh(new THREE.BoxGeometry(25, 20, 0.5), wallMat);
  scene.add(wall);
  wall.position.y = 10;
  wall.position.z = -10.3;

  const wall2 = new THREE.Mesh(new THREE.BoxGeometry(0.5, 20, 20), wallMat);
  scene.add(wall2);
  wall2.position.y = 10;
  wall2.position.x = -12;

  const wall3 = new THREE.Mesh(new THREE.BoxGeometry(0.5, 20, 20), wallMat);
  scene.add(wall3);
  wall3.position.y = 10;
  wall3.position.x = 12;

  // text3D加载器
  const loader = new FontLoader();
  loader.load("font/helvetiker_regular.typeface.json", function (font) {
    const geometry = new TextGeometry(config.text, {
      font: font,
      size: 3,
      depth: 0.2,
      curveSegments: 120,
      bevelEnabled: false, //webgl_geometry_text
    });
    geometry.center(); // 居中
    const material = new THREE.MeshBasicMaterial({
      color: config.color,
    });
    const text = new THREE.Mesh(geometry, material);
    scene.add(text);
    text.position.y = 1.54;
  });

  // 创建雨地面
  // 加载地面纹理
  const fNormalTex = textureLoader.load("/texture/0425/floor-normal.jpg");
  const fOpacityTex = textureLoader.load("/texture/0425/floor-opacity.jpg");
  const fRoughnessTex = textureLoader.load("/texture/0425/floor-roughness.jpg");
  fNormalTex.wrapS = fNormalTex.wrapT = THREE.MirroredRepeatWrapping;
  fOpacityTex.wrapS = fOpacityTex.wrapT = THREE.MirroredRepeatWrapping;
  fRoughnessTex.wrapS = fRoughnessTex.wrapT = THREE.MirroredRepeatWrapping;

  // custom reflector
  const plan = new THREE.PlaneGeometry(25, 100);
  // // 反射镜面
  const mirror = new Reflector(plan);
  mirror.position.z = -25;
  mirror.rotation.x = -Math.PI / 2;
  mirror.material.uniforms = {
    ...mirror.material.uniforms,
    ...{
      uNormalTexture: {
        value: fNormalTex,
      },
      uOpacityTexture: {
        value: fOpacityTex,
      },
      uRoughnessTexture: {
        value: fRoughnessTex,
      },
      uRainCount: {
        value: config.count,
      },
      uTexScale: {
        value: new THREE.Vector2(1, 4),
      },
      uTexOffset: {
        value: new THREE.Vector2(1, -0.5),
      },
      uDistortionAmount: {
        value: 0.25,
      },
      uBlurStrength: {
        value: 8,
      },
      uMipmapTextureSize: {
        value: new THREE.Vector2(window.innerWidth, window.innerHeight),
      },
    },
  };
  mirror.material.vertexShader = vertexShader;
  mirror.material.fragmentShader = fragmentShader;
  mipmapper = new PackedMipMapGenerator();
  mirrorFBO = mirror.getRenderTarget();
  const mipmapFBO = new FBO();

  // mirror.material.uniforms.tDiffuse.value = mipmapFBO.rt.texture;
  scene.add(mirror);

  // 雨
  const rNormalTex = textureLoader.load("/texture/0425/rain-normal.png");
  rNormalTex.flipY = false;
  const rainMat = new THREE.ShaderMaterial({
    vertexShader: rainVertShader,
    fragmentShader: rainFragShader,
    uniforms: {
      ...{
        uSpeed: {
          value: speed,
        },
        uHeightRange: {
          value: 20,
        },
        uNormalTexture: {
          value: rNormalTex,
        },
        uBgRt: {
          value: null,
        },
        uRefraction: {
          value: 0.1,
        },
        uBaseBrightness: {
          value: 0.1,
        },
      },
    },
  });
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
</script>
<style scoped>
.canvasRef {
  width: 100%;
  height: 100%;
}
</style>
