varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;
uniform float uTime;
uniform vec2  uMouseInfluence;

void main(){
  vUv = uv;
  vNormal = normal;
  vPosition = position;
  float waveX = sin(uTime * 2.5 + position.y * 8.0 + position.x * 2.0) * 0.12;
  float waveZ = cos(uTime * 2.2 + position.y * 7.0 + position.z * 2.0) * 0.12;
  vec3 transformed = position;
  transformed.x += waveX + uMouseInfluence.x * 0.05 * sin(position.y * 10.0);
  transformed.z += waveZ + uMouseInfluence.y * 0.05 * cos(position.y * 10.0);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(transformed, 1.0);
 }