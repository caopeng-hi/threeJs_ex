

        uniform sampler2D tDiffuse;
        uniform float darkness;
        uniform float offset;
        varying vec2 vUv;

        void main() {
          vec4 color = texture2D(tDiffuse, vUv);
          vec2 uv = (vUv - 0.5) * 2.0;
          float vignetteAmount = smoothstep(offset, offset - 0.05, length(uv));
          color.rgb *= mix(1.0, darkness, 1.0 - vignetteAmount);
          gl_FragColor = color;
        }