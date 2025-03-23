        uniform sampler2D tDiffuse;
        uniform float amount;
        uniform float time;
        varying vec2 vUv;

        void main() {
          float aberrationAmount = amount * (0.8 + sin(time * 1.2) * 0.2);
          float angle = time * 0.2;
          vec2 dir = vec2(cos(angle), sin(angle)) * aberrationAmount;
          vec4 colorR = texture2D(tDiffuse, vUv + dir);
          vec4 colorG = texture2D(tDiffuse, vUv);
          vec4 colorB = texture2D(tDiffuse, vUv - dir);
          gl_FragColor = vec4(colorR.r, colorG.g, colorB.b, 1.0);
        }