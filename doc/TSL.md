## 学习 TSL 日记 【threeJs shader language】

### 介绍

#### 1. 什么是 TSL ？

TSL 是一种用于编写 Three.js 着色器的语言。它是一种基于 JavaScript 的语言，用 js 链式编程和函数式编程来代替之前复杂的 GLSL 语法。

#### 2. TSL 的优势

- TSL 易于学习，学习曲线平缓。
- TSL 方便调试。
- TSL 支持 webGPU，会检查设备是否支持 webGPU，如果不支持会降级到 webGL。

### 案例

    创建一个标准材质，并加载颜色贴图，然后在着色器中使用颜色贴图。

```js
/**
 * Old
 * webGL shader language
 *
 * 使用.onBeforeCompile() 方法，在着色器编译之前，将颜色贴图传递给着色器。
 * 然后在着色器中使用颜色贴图。
 */
const colorMap = new THREE.TextureLoader().load("./assets/color.jpg"); // 加载颜色贴图
const material = new THREE.MeshStandardMaterial(); // 创建一个标准材质
material.map = colorMap; // 设置材质的颜色贴图
material.onBeforeCompile = (shader) => {
  shader.uniforms.detailMap = { value: detailMap }; // 传递uniforms给着色器

  let token = "#define STANDARD"; // 定义一个 token，用于在着色器中插入代码

  let insert = `
		uniform sampler2D detailMap;
	`;

  shader.fragmentShader = shader.fragmentShader.replace(token, token + insert);

  token = "#include <map_fragment>";

  insert = `
		diffuseColor *= texture2D( detailMap, vMapUv * 10.0 );
	`;
  shader.fragmentShader = shader.fragmentShader.replace(token, token + insert);
};
```

上述代码任何更改都会使. onBeforeCompile 变得越来越复杂，因为需要不断的增 token 和 replace 去讲 glsl 代码放到正确的位置，我们今天在社区中得到的结果是无数类型的参数化材料，它们不相互通信，需要定期更新才能运行，限制了以简单方式创建独特材料重用模块的创造力。

```js
/**
 * New
 * threeJs shader language 【TSL】
 *
 * 使用 texture() 方法，将颜色贴图传递给着色器。
 */
import { texture, uv } from "three/tsl";
const detailMap = new THREE.TextureLoader().load("./assets/color.jpg"); // 加载颜色贴图
const detail = texture(detailMap, uv().mul(10)); // 传递颜色贴图

const material = new THREE.MeshStandardNodeMaterial(); // 创建一个标准材质
material.colorNode = texture(colorMap).mul(detail); // 设置材质的颜色贴图
```

上述代码直接使用 texture 和 uv 两个方法，可以获取到物体的 uv 坐标和特图，更加直观和简单。

TSL 还能够将代码编码到不同的输出中，例如 WGSL/GLSL-WebGPU/WebGL，此外还可以自动优化着色器图形，并通过可以插入到每个节点中的代码。这允许开发人员专注于生产力，并将图形管理部分留给节点系统。

图形着色器的另一个重要特性是我们将不再需要关心创建组件的顺序，因为节点系统只会声明和包含它一次

假设您将 positionWorld 导入代码中，即使另一个组件使用它，为获取位置世界而执行的计算也只会执行一次，就像任何其他节点一样，例如：normalWorld、ModelPoition 等。

### TSL 结构

所有 TSL 组件都是从 Node 类扩展而来的。Node 允许它与任何其他组件进行通信，值转换可以是自动的或手动的，Node 可以接收父节点期望的产出值并修改自己的输出片段。可以在着色器构建过程中使用树摇动来调制它们，Node 将拥有几何、材质、渲染器以及后端等重要信息，这些信息会影响输出的类型和值。

负责创建代码的主要类是 NodeBuilder。该类可以扩展到任何输出编程语言，因此如果您愿意，您可以将 TSL 用于第三种语言。目前 NodeBuilder 有两个扩展类，针对 WebGPU 的 WGSLNodeBuilder 和针对 WebGL2 的 GLSLNodeBuilder。

构建过程基于三个支柱：设置、分析和生成
| 支柱 | 描述 |
| ---- | :-----------------: |
| `设置` | 可以使用`TSL`给 node 设置自定义的 shader 代码并且输出 |
| 分析 | 此过程将检查创建的节点，以便为生成片段创建有用的信息，例如是否需要创建用于优化节点的缓存/变量 |
| 生成 | 每个节点将返回一个字符串输出。任何节点也将能够在着色器流中创建代码，支持多行。 |
