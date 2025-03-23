 attribute float size;
 attribute vec3 velocity;
 attribute float lifeProgress;
 varying vec3 vColor;
 varying float vLife;
 uniform float uTime;


 void main(){
        vColor = color;
        float progress = mod(lifeProgress + uTime * 0.5, 1.0);
        vLife = 1.0 - progress;
        vec3 animatedPosition = position + velocity * progress * 4.0;
        float flicker = sin(uTime * 15.0 + lifeProgress * 25.0) * 0.3 + 1.0;
        vec4 mvPosition = modelViewMatrix * vec4(animatedPosition, 1.0);
        gl_PointSize = size * vLife * flicker * (500.0 / -mvPosition.z);
        gl_Position = projectionMatrix * mvPosition;
 }