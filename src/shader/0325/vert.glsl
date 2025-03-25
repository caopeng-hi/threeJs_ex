uniform float uDuration;
uniform float uElapsedTime;
uniform float uSize;
uniform float uNoise;
uniform vec2 uMousePosition;
uniform float uMouseRadius;
uniform float uMouseStrength;

varying float pointDisplacement;
varying vec3 vColor;

attribute vec3 minPosition;
attribute vec3 maxPosition;
attribute vec3 color;
attribute vec2 noiseValue;

	float exponentialInOut( float k ){
			    if( k <= 0.0 ){
			        return 0.0;
			    }
			    else if( k >= 1.0 ){
			        return 1.0;
			    }
			    else if( ( k *= 2.0 ) < 1.0 ){
			        return 0.5 * pow( 1024.0, k - 1.0 );
			    }
			    return 0.5 * ( - pow( 2.0, - 10.0 * ( k - 1.0 ) ) + 2.0 );
	}

void main(){
    vColor = color;
    float t = clamp(uElapsedTime / uDuration, 0.0, 1.0);
    float progress = exponentialInOut( t );
    vec3 delta = minPosition - maxPosition;
	vec3 explosingPosition = position + delta * progress;
    vec3 interactionPosition = explosingPosition;
    float distanceToCenter = clamp(distance(vec2(interactionPosition.x, interactionPosition.y), uMousePosition) / uMouseRadius, 0.0, 1.0);
    float distanceToPoint = distance(vec2(interactionPosition.x, interactionPosition.y), uMousePosition);
    vec3 vectorToPoint = normalize(interactionPosition - vec3(uMousePosition, 0.0));
    vectorToPoint.x = vectorToPoint.x / (pow(distanceToCenter, uMouseStrength));
	vectorToPoint.y = vectorToPoint.y / (pow(distanceToCenter, uMouseStrength));
    pointDisplacement = (abs(vectorToPoint.x) + abs(vectorToPoint.y)) / 2.0;
	float xAnim = interactionPosition.x + vectorToPoint.x * uMouseRadius * distanceToCenter;
	float yAnim = interactionPosition.y + vectorToPoint.y * uMouseRadius * distanceToCenter;
	interactionPosition = vec3(xAnim, yAnim, interactionPosition.z);
    vec3 noisePosition = interactionPosition;
    float noiseX = interactionPosition.x + cos(noiseValue.x * (uElapsedTime / 100.0)) * progress * uNoise * min((uMouseRadius / 4.0) / distanceToPoint, 1.0);
    float noiseY = interactionPosition.y + cos(noiseValue.y * (uElapsedTime / 100.0)) * progress * uNoise * min((uMouseRadius / 4.0) / distanceToPoint, 1.0);
    noisePosition = vec3(noiseX, noiseY, interactionPosition.z);
    vec4 mvPosition = modelViewMatrix * vec4( noisePosition, 1.0 );
    gl_PointSize = uSize;
	gl_Position = projectionMatrix * mvPosition;
}