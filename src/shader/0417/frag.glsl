uniform float uTime;
uniform float uIndex;
uniform float uCurrentIndex;
uniform float uNextIndex;
uniform float uProgress;
uniform vec3 uColor;
uniform float uMinY;
uniform float uMaxY;

varying vec3 vPosition;
varying vec3 vNormal;

void main(){
    if(uIndex != uCurrentIndex && uIndex != uNextIndex) {
        discard;
    }
  float lines = 20.0;
  float offset = vPosition.y - uTime * 0.2;
  float density = mod(offset * lines, 1.0);
  density = pow(density, 3.0);

  vec3 viewDirection = normalize(vPosition - cameraPosition);
  float fresnel = 1.0 - abs(dot(normalize(vNormal), viewDirection));
  fresnel = pow(fresnel, 2.0);

    float falloff = smoothstep(0.8, 0.0, fresnel);

  float holographic = density * fresnel;
  holographic += fresnel * 1.25;
  holographic *= falloff;

  float normalizedY = (vPosition.y - uMinY) / (uMaxY - uMinY);

  if(uIndex == uCurrentIndex && normalizedY < uProgress) {
    discard;
  }
  if(uIndex == uNextIndex && normalizedY > uProgress) {
    discard;
  }
  gl_FragColor = vec4(uColor, holographic);

  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}