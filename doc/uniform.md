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
