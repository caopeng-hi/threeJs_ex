<!--
 * @Author: caopeng
 * @Date: 2025-04-14 16:09:17
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-14 16:16:23
 * @Description: 请填写简介
 * @FilePath: \api.md
-->

#### blendScreen(base,blend) [屏幕混合模式]

###### 1.原理

- 混合两种颜色，通常用于创建叠加效果。
- 对两个颜色（base 和 blend）分别取反相（1.0 - color），然后相乘，最后再反相回来。
- 结果会比原始颜色更亮，适合模拟“光叠加”效果（如光晕、发光物体）

是一种非线性增亮混合模式，广泛用于光照、特效和后期处理。在 Three.js 节点材质中

###### 2.特性

- 如果 base 或 blend 中有一个是白色（1.0），结果一定是白色
- 如果有一个是黑色（0.0），结果等于另一个颜色。
- 保留高光部分，抑制暗部（与 multiply 混合模式相反）。

数学公式：

```js
vec3 screenBlend(vec3 base, vec3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}
// 简化
result = 1.0 - (1.0 - base) * (1.0 - blend);
```

```js
import { blendScreen } from "three/tsl";
material.blendMode = blendScreen(base, blend);
```

###### 3.应用场景

- 1.光效叠加
  将发光纹理（如光晕）通过 blendScreen 叠加到场景中。

  ```js
  vec3 glow = texture(glowTexture, uv).rgb;
  vec3 finalColor = 1.0 - (1.0 - baseColor) * (1.0 - glow);
  ```

- 2.后期处理

  在后处理阶段混合高亮区域（如泛光效果）。

- 3.UI/遮罩

  实现“增亮”型遮罩（如模拟透光效果）
