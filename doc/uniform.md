#### uniform(boolean | number | Color | Vector2 | Vector3 | Vector4 | Matrix3 | Matrix4, type = null) [给着色器器传递数据]

##### Example

```js
/**
 *  GLSL
 */
// 声明
const material = new THREE.ShaderMaterial({
  uniforms: {
    uTime: { value: 0 }, // 时间
    uMouse: { value: new THREE.Vector2(0, 0) }, // 鼠标
    uResolution: { value: new THREE.Vector2(0, 0) }, // 分辨率
  },
  vertexShader,
  fragmentShader,
});
// 使用   片元着色器或者顶点着色器中
uniform float uTime; // 时间
uniform vec2 uMouse; // 鼠标
uniform vec2 uResolution; // 分辨率
```

```js
/**
 *  WGSL
 */
const posY = uniform(mesh.position.y);

posY.value = mesh.position.y;

material.colorNode = posY;
```

##### uniform.on\*Update()

###### uniform.onObjectUpdate( function )

一个自定义回调函数，用于在 特定对象（如 THREE.Object3D）更新时 动态修改 uniform 变量的值。它通常用于 基于场景对象状态（如位置、旋转、缩放等）动态调整着色器参数。

- 作用

  1. 自动绑定到对象更新事件：当关联的 THREE.Object3D（如 Mesh、Camera、Light）发生变化（位置、旋转、缩放等）时，触发回调

  2. 动态更新 uniform：在回调中计算新的 uniform 值，使其与对象状态同步

  3. 避免手动每帧更新：相比 uniform.onUpdate()（每帧调用），onObjectUpdate() 仅在对象变化时触发，性能更优

###### uniform..onRenderUpdate( function )

一个自定义回调函数，主要作用是在每次渲染时调用指定的回调函数，以更新与渲染相关的参数

- 作用

1.  共享材质的属性。例如，在动画或交互式场景中，根据用户输入或时间变化更新材质的纹理或颜色

2.  雾效果（如雾的颜色、密度等）。 在渲染过程中，如果需要根据场景的变化（如相机位置、时间等）动态调整雾的密度或颜色，onRenderUpdate 可以提供灵活的支持

3.  色调映射相关的参数。在复杂的渲染场景中，可能需要根据场景的光照条件或画面内容动态调整色调映射参数，以优化视觉效果。onRenderUpdate 可以用于实现这一功能。

通过这个函数，可以动态调整渲染过程中的参数，确保渲染结果符合预期的视觉效果。

- 示例

```js
uniform.onRenderUpdate(function () {
  // 假设 fogDensity 是一个全局变量，根据时间或其他条件动态变化
  let fogDensity = calculateFogDensity();
  this.uniforms.fogDensity.value = fogDensity;
});

/**
 * 在这个示例中，calculateFogDensity 是一个自定义函数，用于计算雾的密度。
 * 通过 onRenderUpdate 回调，每次渲染时都会更新雾的密度，从而实现动态效果。
 */
```

###### uniform.onFrameUpdate( function )

一个自定义回调函数，是一个与渲染帧更新相关的函数，通常用于在每一帧渲染时动态更新与渲染相关的参数

- 作用

  1. 动态变化的材质属性（如颜色、纹理等）。

  ```js
  /**
   *  在动画或交互式场景中，可能需要根据时间或用户输入动态调整材质的属性。例如，实现材质颜色的渐变或纹理的动态变化：
   */
  uniform.onFrameUpdate(function (time) {
    // 假设 time 是当前帧的时间戳
    const color = new THREE.Color().setHSL(time % 1, 0.5, 0.5);
    this.uniforms.materialColor.value = color;
  });
  ```

  2. 场景中的光照参数（如光源位置、强度等）。

  ```js
  /**
   * 在需要根据场景变化动态调整光源属性时，可以使用 onFrameUpdate。例如，模拟一天中光照强度的变化
   */
  uniform.onFrameUpdate(function (time) {
    const lightIntensity = Math.sin(time) * 0.5 + 0.5; // 光照强度在 0.5 到 1 之间变化
    this.uniforms.lightIntensity.value = lightIntensity;
  });
  ```

  3. 相机或视图相关的参数（如视角、视距等）。

  ```js
  /**
   * 在某些交互式场景中，可能需要根据用户操作或动画需求动态调整相机的视角或视距,
   * 每一帧都会更新相机位置，从而确保渲染效果与相机视角保持一致。
   */
  uniform.onFrameUpdate(function (cameraPosition) {
    this.uniforms.cameraPosition.value = cameraPosition;
  });
  ```
