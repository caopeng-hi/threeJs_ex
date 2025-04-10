     uniform sampler2D baseTexture;
     uniform sampler2D bloomTexture;
     uniform float bloomStrength;
     varying vec2 vUv;
     void main(){
     // 取原图
     vec4 baseEffect = texture2D(baseTexture, vUv);
     // 取 Bloom 生成的图
     vec4 bloomEffect = texture2D(bloomTexture, vUv);
     // 简单把它们做加法叠加，并乘以 bloomStrength
     gl_FragColor = baseEffect + bloomEffect * bloomStrength;
    }