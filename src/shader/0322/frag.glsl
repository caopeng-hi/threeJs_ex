varying vec2 vUv; // vu贴图
varying vec3 vNormal; //法线
varying vec3 vPosition; //顶点位置
uniform float uTime; //时间
uniform vec2 uMouseInfluence; //鼠标影响
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 /  3.0, 1.0 / 3.0,  3.0);
    vec3 p =  abs(fract(c.xxx + K.xyz) * 6.0 - K.www); 
    return c.z * mix(K.xxx,  clamp(p - K.xxx, 0.0, 1.0), c.y);
}
void main(){
    float hue = 0.6 + sin(vUv.y * 3.0 + uTime * 0.2) * 0.2;
    float sat = 0.7 + sin(uTime * 0.5) * 0.2;
    float val = 0.85;
    vec3 baseColor = hsv2rgb(vec3(hue, sat, val));
    float pattern = sin(vUv.y * 20.0 + uTime * 4.0) * cos(vUv.x * 15.0 + uTime * 3.0) * 0.5 + 0.5;
    pattern *= sin(vUv.y * 8.0 - uTime * 2.0) * 0.5 + 0.5;
    vec3 iridescence = vec3(
          sin(uTime * 0.7 + vUv.y * 8.0 + uMouseInfluence.x),
          cos(uTime * 0.6 + vUv.x * 7.0 + uMouseInfluence.y * 0.5),
          sin(uTime * 0.9 + vUv.y * 9.0)
    ) * 0.4;
    vec3 color = baseColor * pattern + iridescence;
    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    float diffuse = max(dot(vNormal, lightDir), 0.6);
    vec3 viewDir = normalize(-vPosition);
    vec3 halfVector = normalize(lightDir + viewDir);
    float specular = pow(max(dot(vNormal, halfVector), 0.0), 64.0);
    float edgeFactor = pow(1.0 - dot(vNormal, viewDir), 3.0);
     vec3 edgeGlow = vec3(0.2, 0.9, 0.8) * edgeFactor * (0.2 + length(uMouseInfluence) * 0.1);
    float pulse = sin(uTime * 3.0) * 0.5 + 0.5;
    edgeGlow *= 0.8 + pulse * 0.4;
    gl_FragColor = vec4(color * diffuse + specular * vec3(0.9, 1.0, 0.95) + edgeGlow, 1.0);
}