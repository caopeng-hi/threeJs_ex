<template>
  <div class="canvasRef" ref="canvasRef"></div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import * as THREE from "three";
import * as CANNON from "cannon-es";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
// 导入RoundedBoxGeometry
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";
const canvasRef = ref(null);
let scene,
  camera,
  renderer,
  controls,
  boxMaterial,
  physicsWorld,
  instancedBoxesMesh;
let dummy = new THREE.Object3D();
let boxesBodies = [];
const params = {
  boxesNumber: 100,
  boxSize: 0.03,
  containerSize: 1,
  gravity: 10,
};
onMounted(() => {
  initScene();
  animate();
  canvasRef.value.addEventListener("dblclick", throwBoxes);
});

const initScene = () => {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xffffff);
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 1, 0.5).multiplyScalar(5);
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(window.devicePixelRatio);
  canvasRef.value.appendChild(renderer.domElement);
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableZoom = false;
  controls.enablePan = false;
  controls.minPolarAngle = 0.1 * Math.PI;
  controls.maxPolarAngle = 0.9 * Math.PI;
  controls.autoRotate = true;
  controls.autoRotateSpeed = 19;
  controls.enableDamping = true;
  throwBoxes();
  initPhysics();
  for (let i = 0; i < 6; i++) {
    const body = new CANNON.Body({ mass: 0, shape: new CANNON.Plane() });
    physicsWorld.addBody(body);
    const posSign = i % 2 ? 1 : -1;
    if (i < 2) {
      body.position.x = posSign * 0.5 * params.containerSize;
      body.quaternion.setFromEuler(0, (-posSign * Math.PI) / 2, 0);
    } else if (i < 4) {
      body.position.y = posSign * 0.5 * params.containerSize;
      body.quaternion.setFromEuler((posSign * Math.PI) / 2, 0, 0);
    } else {
      body.position.z = posSign * 0.5 * params.containerSize;
      if (i > 4) {
        body.quaternion.setFromEuler(0, Math.PI, 0);
      }
    }
  }

  boxMaterial = new THREE.MeshBasicMaterial({
    color: 0x000000,
    visible: false,
  });
  boxMaterial.visible = true;

  const boxGeometry = new RoundedBoxGeometry(
    params.boxSize,
    params.boxSize,
    params.boxSize,
    2,
    0.2 * params.boxSize
  );
  instancedBoxesMesh = new THREE.InstancedMesh(
    boxGeometry,
    boxMaterial,
    params.boxesNumber
  );
  scene.add(instancedBoxesMesh);

  for (let i = 0; i < params.boxesNumber; i++) {
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
    physicsWorld.addBody(boxesBodies[i]);
  }
  const wallGeometry = new THREE.BoxGeometry(
    params.containerSize,
    params.containerSize,
    params.containerSize
  );
  const wallEdges = new THREE.EdgesGeometry(wallGeometry);
  const wallLine = new THREE.LineSegments(
    wallEdges,
    new THREE.LineBasicMaterial({ color: 0x000000 })
  );
  scene.add(wallLine);
};
const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
  physicsWorld.fixedStep();
  for (let i = 0; i < params.boxesNumber; i++) {
    dummy.position.copy(boxesBodies[i].position);
    dummy.quaternion.copy(boxesBodies[i].quaternion);
    dummy.updateMatrix();
    instancedBoxesMesh.setMatrixAt(i, dummy.matrix);
  }
  instancedBoxesMesh.instanceMatrix.needsUpdate = true;

  const gravity = new THREE.Vector3(0, -params.gravity, 0);
  gravity.applyQuaternion(camera.quaternion);
  physicsWorld.gravity = new CANNON.Vec3(gravity.x, gravity.y, gravity.z);
};
function initPhysics() {
  physicsWorld = new CANNON.World({
    allowSleep: true,
    gravity: new CANNON.Vec3(0, -params.gravity, 0),
  });
  physicsWorld.defaultContactMaterial.friction = 0.1;
  physicsWorld.defaultContactMaterial.restitution = 0.9;
}
function throwBoxes() {
  boxesBodies.forEach((body) => {
    const force = 7;
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
