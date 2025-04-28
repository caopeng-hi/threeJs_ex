/*
 * @Author: caopeng
 * @Date: 2025-04-28 16:51:12
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-28 16:53:59
 * @Description: 请填写简介
 */
import * as THREE from "three";
class FBO {
  rt: THREE.WebGLRenderTarget;
  constructor(config = {}) {
    const samples = 0;
    const depth = false;
    const rt = new THREE.WebGLRenderTarget(
      this.actualWidth,
      this.actualHeight,
      {
        minFilter: THREE.LinearFilter,
        magFilter: THREE.LinearFilter,
        type: THREE.HalfFloatType,
        samples: 0,
        depth: false,
      }
    );
    this.rt = rt;

    if (depth) {
      rt.depthTexture = new THREE.DepthTexture(
        this.actualWidth,
        this.actualHeight,
        THREE.FloatType
      );
    }

    if (samples) {
      rt.samples = samples;
    }
  }
  get actualWidth() {
    return window.innerWidth * window.devicePixelRatio;
  }
  get actualHeight() {
    return window.innerHeight * window.devicePixelRatio;
  }
}

export { FBO };
