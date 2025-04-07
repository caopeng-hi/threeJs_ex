  uniform vec2 u_resolution;
  uniform vec2 u_mouse;
  uniform float u_time;
  uniform sampler2D u_noise;

  #define PI 3.141592653589793
  #define TAU 6.

  const float multiplier = 15.5;
  const float zoomSpeed = 10.;
  const int layers = 10;
  const int octaves = 5;

   vec2 hash2(vec2 p){
    vec2 o = texture2D( u_noise, (p+0.5)/256.0, -100.0 ).xy;
    return o;
  }

  mat2 rotate2d(float _angle){
      return mat2(cos(_angle),sin(_angle), -sin(_angle),cos(_angle));
  }
    vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0), 6.0)-3.0)-1.0,0.0,1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
  }

  float hash(vec2 p){
    float o = texture2D( u_noise, (p+0.5)/256.0, -100.0 ).x;
    return o;
  }

  float noise(vec2 uv) {
    vec2 id = floor(uv);
    vec2 subuv = fract(uv);
    vec2 u = subuv * subuv * (3. - 2. * subuv);
    float a = hash(id);
    float b = hash(id + vec2(1., 0.));
    float c = hash(id + vec2(0., 1.));
    float d = hash(id + vec2(1., 1.));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
  }

   float fbm(in vec2 uv) {
    float s = .0;
    float m = .0;
    float a = .5;
    for(int i = 0; i < octaves; i++) {
      s += a * noise(uv);
      m += a;
      a *= .5;
      uv *= 2.;
    }
    return s / m;
  }

   vec3 domain(vec2 z){
    return vec3(hsb2rgb(vec3(atan(z.y,z.x)/TAU,1.,1.)));
  }

   vec3 colour(vec2 z) {
      return domain(z);
  }

vec3 render(vec2 uv, float scale, vec3 colour) {
    vec2 id = floor(uv);
    vec2 subuv = fract(uv);
    vec2 rand = hash2(id);
    float bokeh = abs(scale) * 1.;
    
    float particle = 0.;
    
    if(length(rand) > 1.3) {
      vec2 pos = subuv-.5;
      float field = length(pos);
      particle = smoothstep(.3, 0., field);
      particle += smoothstep(.4 * bokeh, 0.34 * bokeh, field);
    }
    return vec3(particle*2.);
  }

  vec3 renderLayer(int layer, int layers, vec2 uv, inout float opacity, vec3 colour, float n) {
    vec2 _uv = uv;
    float scale = mod((u_time + zoomSpeed / float(layers) * float(layer)) / zoomSpeed, -1.);
    uv *= 20.; 
    uv *= scale*scale; 
    uv = rotate2d(u_time / 10.) * uv; 
    uv += vec2(25. + sin(u_time*.1)) * float(layer); 
    vec3 pass = render(uv * multiplier, scale, colour) * .2; 
    opacity = 1. + scale;
    float _opacity = opacity;
    float endOpacity = smoothstep(0., 0.4, scale * -1.);
    opacity += endOpacity;
    return pass * _opacity * endOpacity;
  }
void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy);
    if(u_resolution.y < u_resolution.x) {
        uv /= u_resolution.y;
      } else {
        uv /= u_resolution.x;
      }

    float n = fbm((uv + vec2(sin(u_time*.1), u_time*.1)) * 2. - 2.);
    vec3 colour = vec3(0.);
    colour = n * mix(vec3(0., .5, 1.5)*-1.5, clamp(vec3(1., .5, .25)*2., 0., 1.), n);
    float opacity = 1.;
    float opacity_sum = 1.;
    for(int i = 1; i <= layers; i++) {
        colour -= renderLayer(i, layers, uv, opacity, colour, n);
        opacity_sum += opacity;
    }
    colour /= opacity_sum;
    gl_FragColor = vec4(clamp(colour * 20., 0., 1.),1.0);
}