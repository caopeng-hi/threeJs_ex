// https://stackoverflow.com/questions/13501081/efficient-bicubic-filtering-code-in-glsl
vec4 sampleBicubic(float v){
    vec4 n=vec4(1.,2.,3.,4.)-v;
    vec4 s=n*n*n;
    vec4 o;
    o.x=s.x;
    o.y=s.y-4.*s.x;
    o.z=s.z-4.*s.y+6.*s.x;
    o.w=6.-o.x-o.y-o.z;
    return o;
}

vec4 sampleBicubic(sampler2D tex,vec2 st,vec2 texResolution){
    vec2 pixel=1./texResolution;
    st=st*texResolution-.5;
    
    vec2 fxy=fract(st);
    st-=fxy;
    
    vec4 xcubic=sampleBicubic(fxy.x);
    vec4 ycubic=sampleBicubic(fxy.y);
    
    vec4 c=st.xxyy+vec2(-.5,1.5).xyxy;
    
    vec4 s=vec4(xcubic.xz+xcubic.yw,ycubic.xz+ycubic.yw);
    vec4 offset=c+vec4(xcubic.yw,ycubic.yw)/s;
    
    offset*=pixel.xxyy;
    
    vec4 sample0=texture(tex,offset.xz);
    vec4 sample1=texture(tex,offset.yz);
    vec4 sample2=texture(tex,offset.xw);
    vec4 sample3=texture(tex,offset.yw);
    
    float sx=s.x/(s.x+s.y);
    float sy=s.z/(s.z+s.w);
    
    return mix(mix(sample3,sample2,sx),mix(sample1,sample0,sx),sy);
}

// With original size argument
vec4 packedTexture2DLOD(sampler2D tex,vec2 uv,int level,vec2 originalPixelSize){
    float floatLevel=float(level);
    vec2 atlasSize;
    atlasSize.x=floor(originalPixelSize.x*1.5);
    atlasSize.y=originalPixelSize.y;
    // we stop making mip maps when one dimension == 1
    float maxLevel=min(floor(log2(originalPixelSize.x)),floor(log2(originalPixelSize.y)));
    floatLevel=min(floatLevel,maxLevel);
    // use inverse pow of 2 to simulate right bit shift operator
    vec2 currentPixelDimensions=floor(originalPixelSize/pow(2.,floatLevel));
    vec2 pixelOffset=vec2(
        floatLevel>0.?originalPixelSize.x:0.,
        floatLevel>0.?currentPixelDimensions.y:0.
    );
    // "minPixel / atlasSize" samples the top left piece of the first pixel
    // "maxPixel / atlasSize" samples the bottom right piece of the last pixel
    vec2 minPixel=pixelOffset;
    vec2 maxPixel=pixelOffset+currentPixelDimensions;
    vec2 samplePoint=mix(minPixel,maxPixel,uv);
    samplePoint/=atlasSize;
    vec2 halfPixelSize=1./(2.*atlasSize);
    samplePoint=min(samplePoint,maxPixel/atlasSize-halfPixelSize);
    samplePoint=max(samplePoint,minPixel/atlasSize+halfPixelSize);
    return sampleBicubic(tex,samplePoint,originalPixelSize);
}

vec4 packedTexture2DLOD(sampler2D tex,vec2 uv,float level,vec2 originalPixelSize){
    float ratio=mod(level,1.);
    int minLevel=int(floor(level));
    int maxLevel=int(ceil(level));
    vec4 minValue=packedTexture2DLOD(tex,uv,minLevel,originalPixelSize);
    vec4 maxValue=packedTexture2DLOD(tex,uv,maxLevel,originalPixelSize);
    return mix(minValue,maxValue,ratio);
}

// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p){
    vec3 p3=fract(vec3(p.xyx)*.1031);
    p3+=dot(p3,p3.yzx+19.19);
    return fract((p3.x+p3.y)*p3.z);
}

vec2 hash22(vec2 p){
    vec3 p3=fract(vec3(p.xyx)*vec3(.1031,.1030,.0973));
    p3+=dot(p3,p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// https://gist.github.com/companje/29408948f1e8be54dd5733a74ca49bb9
float map(float value,float min1,float max1,float min2,float max2){
    return min2+(value-min1)*(max2-min2)/(max1-min1);
}

uniform vec3 color;
uniform sampler2D tDiffuse;
varying vec2 vUv;
varying vec4 vMirrorCoord;
varying vec3 vWorldPosition;

uniform sampler2D uRoughnessTexture;
uniform sampler2D uNormalTexture;
uniform sampler2D uOpacityTexture;
uniform vec2 uTexScale;
uniform vec2 uTexOffset;
uniform float uDistortionAmount;
uniform float uBlurStrength;
uniform float iTime;
uniform float uRainCount;
uniform vec2 uMipmapTextureSize;

#define MAX_RADIUS 1
#define DOUBLE_HASH 0

void main(){
    vec2 p=vUv;
    vec2 texUv=p*uTexScale;
    texUv+=uTexOffset;
    float floorOpacity=texture(uOpacityTexture,texUv).r;
    vec3 floorNormal=texture(uNormalTexture,texUv).rgb*2.-1.;
    floorNormal=normalize(floorNormal);
    float roughness=texture(uRoughnessTexture,texUv).r;
    
    vec2 reflectionUv=vMirrorCoord.xy/vMirrorCoord.w;
    
    // https://www.shadertoy.com/view/ldfyzl
    vec2 rippleUv=75.*p*uTexScale;
    
    vec2 p0=floor(rippleUv);
    
    float rainStrength=map(uRainCount,0.,10000.,3.,.5);
    if(rainStrength==3.){
        rainStrength=50.;
    }
    
    vec2 circles=vec2(0.);
    for(int j=-MAX_RADIUS;j<=MAX_RADIUS;++j)
    {
        for(int i=-MAX_RADIUS;i<=MAX_RADIUS;++i)
        {
            vec2 pi=p0+vec2(i,j);
            #if DOUBLE_HASH
            vec2 hsh=hash22(pi);
            #else
            vec2 hsh=pi;
            #endif
            vec2 p=pi+hash22(hsh);
            
            float t=fract(.8*iTime+hash12(hsh));
            vec2 v=p-rippleUv;
            float d=length(v)-(float(MAX_RADIUS)+1.)*t+(rainStrength*.1*t);
            
            float h=1e-3;
            float d1=d-h;
            float d2=d+h;
            float p1=sin(31.*d1)*smoothstep(-.6,-.3,d1)*smoothstep(0.,-.3,d1);
            float p2=sin(31.*d2)*smoothstep(-.6,-.3,d2)*smoothstep(0.,-.3,d2);
            circles+=.5*normalize(v)*((p2-p1)/(2.*h)*(1.-t)*(1.-t));
        }
    }
    circles/=float((MAX_RADIUS*2+1)*(MAX_RADIUS*2+1));
    
    float intensity=.05*floorOpacity;
    vec3 n=vec3(circles,sqrt(1.-dot(circles,circles)));
    
    vec2 rainUv=intensity*n.xy;
    
    vec2 finalUv=reflectionUv+floorNormal.xy*uDistortionAmount-rainUv;
    
    float level=roughness*uBlurStrength;
    
    vec3 col=packedTexture2DLOD(tDiffuse,finalUv,level,uMipmapTextureSize).rgb;
    
    gl_FragColor=vec4(col,1.);
    
    // vec4 base=texture2DProj(tDiffuse,vec4(finalUv,1.,1.));
    // gl_FragColor=vec4(base.rgb,1.);
}