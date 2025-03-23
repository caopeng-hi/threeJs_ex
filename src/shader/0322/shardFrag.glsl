 varying vec2  vUv;
 varying vec3  vNormal;
 varying vec3  vPosition;
 uniform float uTime;
 uniform float uUniqueOffset;
 uniform vec3  uColor;

void main(){
        vec3 baseColor = uColor;
        float facet = abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
        facet = pow(facet, 1.5) * 0.8 + 0.2;
        vec3 iridescence = vec3(
          sin(uTime * 0.7 + facet * 10.0 + uUniqueOffset),
          cos(uTime * 0.8 + facet * 8.0 + uUniqueOffset * 0.5),
          sin(uTime * 0.9 + facet * 12.0 + uUniqueOffset * 0.7)
        ) * 0.5;
        vec3 color = baseColor * facet + iridescence;
        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
        vec3 viewDir = normalize(-vPosition);
        vec3 halfVector = normalize(lightDir + viewDir);
        float specular = pow(max(dot(vNormal, halfVector), 0.0), 128.0);
        vec3 glow = baseColor * 0.3 * (sin(uTime * 3.0 + uUniqueOffset) * 0.5 + 0.5);
        float innerRefraction = pow(1.0 - abs(dot(vNormal, viewDir)), 4.0) * 0.6;
        vec3 refractionColor = mix(baseColor, vec3(1.0), 0.8) * innerRefraction;
        gl_FragColor = vec4(color + specular * vec3(1.0, 0.9, 0.7) + glow + refractionColor, 1.0);
}