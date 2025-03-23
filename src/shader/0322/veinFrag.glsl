varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;
uniform float uTime;
void main(){
     vec3 color1 = vec3(0.9, 0.4, 0.8);
     vec3 color2 = vec3(0.4, 0.2, 0.9);
     float t = sin(uTime * 0.5) * 0.5 + 0.5;
     vec3 baseColor = mix(color1, color2, t);
     float pulse = sin(vUv.y * 50.0 - uTime * 8.0) * 0.5 + 0.5;
     pulse *= sin(vUv.y * 20.0 + uTime * 4.0) * 0.5 + 0.5;
     float secondaryPulse = sin(vUv.y * 30.0 - uTime * 6.0 + vUv.x * 5.0) * 0.5 + 0.5;
     pulse = mix(pulse, secondaryPulse, 0.3);
     vec3 color = baseColor * pulse;
     vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
     float diffuse = max(dot(vNormal, lightDir), 0.7);
     vec3 viewDir = normalize(-vPosition);
     vec3 halfVector = normalize(lightDir + viewDir);
     float specular = pow(max(dot(vNormal, halfVector), 0.0), 128.0);
     vec3 accent = vec3(1.0, 0.4, 0.8) * sin(uTime * 4.0 + vUv.y * 12.0) * 0.3;
     float energyFlow = pow(sin(vUv.y * 60.0 - uTime * 10.0) * 0.5 + 0.5, 4.0) * 0.6;
     gl_FragColor = vec4(color * diffuse + specular * vec3(1.0, 0.8, 0.9) + accent + vec3(energyFlow), 1.0);
}