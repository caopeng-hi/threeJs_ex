precision highp float;
varying vec2 vUv;
uniform vec2 uResolution;
uniform float uTime;
#define NUM_OCTAVES 5

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898,4.1414))) *43758.5453); 
}
float noise(vec2 p){ 
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    float res = mix( mix(rand(ip), rand(ip+vec2(1.0,0.0)), u.x), mix(rand(ip+vec2(0.0,1.0)), rand(ip+vec2(1.0,1.0)), u.x), u.y);
    return res*res;
 }
 float fbm(vec2 x){
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for(int i =0; i < NUM_OCTAVES; ++i) {
        v += a * noise(x);
        x = rot * x *2.0+ shift;
         a *=0.5;
    }
    return v;
}

void main () {
    vec2 shake = vec2(sin(uTime *1.5) *0.01, cos(uTime *2.7) *0.01);
    vec2 fragCoord = vUv * uResolution;
    vec2 p = ((fragCoord + shake * uResolution) - uResolution *0.5) / uResolution.y;
    p *= mat2(8.0,-6.0,6.0,8.0);
    vec2 v;
    vec4 o = vec4(0.0);
    float f =3.0+ fbm(p + vec2(uTime *7.0,0.0));
    for(float i =0.0; i <50.0; i++) {
        v = p + cos(i*i + (uTime + p.x*0.1)*0.03+ i*vec2(11.0,9.0)) *5.0 + vec2(sin(uTime*4.0+ i)*0.005, cos(uTime*4.5- i)*0.005);
        float tailNoise = fbm(v + vec2(uTime, i)) * (1.0- (i/50.0));
        vec4 currentContribution = (cos(sin(i)*vec4(1.0,2.0,3.0,1.0)) +1.0) * exp(sin(i*i + uTime)) / length(max(v, vec2(v.x*f*0.02, v.y)));
        float thinnessFactor = smoothstep(0.0,1.0, i/50.0);
        o += currentContribution * (1.0 + tailNoise*2.0) * thinnessFactor;
    }
    o = tanh(pow(o/1e2, vec4(1.5)));
    gl_FragColor = o;
}