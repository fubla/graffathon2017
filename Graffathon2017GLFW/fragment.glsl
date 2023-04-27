/**
*	Credits to Jamie Wong, http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/
*   and to Inigo Quilez, http://iquilezles.org for much of the code in this file
*/

#version 330 core
out vec4 fragColor;
  
in vec4 vertexColor; // the input variable from the vertex shader (same name and same type)  
in vec4 gl_FragCoord;

uniform vec2 windowSize;
uniform float timeValue;

const int MAX_OBJECTS = 5;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
}; 

float objectArray[MAX_OBJECTS];
  
uniform Material material;

/**
* My arbitrary distance functions
*/

float length1(vec3 point) {
	return abs(point.x) + abs(point.y) + abs(point.z);
}

float length3(vec3 point) {
	return pow( abs(pow(point.x, 3.0)) + abs(pow(point.y, 3.0)) + abs(pow(point.z, 3.0)), 1.0/3.0 );
}

float length4(vec3 point) {
	return pow( pow(point.x, 4.0) + pow(point.y, 4.0) + pow(point.z, 4.0), 1.0/4.0 );
}

// polynomial smooth min (k = 0.1);
// credits to Inigo Quilez, http://iquilezles.org
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

/**
*	Booleans, all credits go to Jamie Wong,
*   http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/
*/

float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float smoothUnionSDF(float distA, float distB) {
    return smin(distA, distB, 0.1);
}

float unionSDF(float distA, float distB){
	    return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

mat4 translateX(float x){
	return mat4(
        vec4(1, 0, 0, x),
        vec4(0, 1, 0, 0),
        vec4(0, 0, 1, 0),
        vec4(0, 0, 0, 1)
    );
}

/**
*	Rotation matrices, credits to Jamie Wong,
*   http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/
*	also some additions on my own
*/
mat4 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(1, 0, 0, 0),
        vec4(0, c, -s, 0),
        vec4(0, s, c, 0),
        vec4(0, 0, 0, 1)
    );
}

mat4 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(c, 0, s, 0),
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1)
    );
}

mat4 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(c,-s, 0, 0),
        vec4(s, c, 0, 0),
        vec4(0, 0, 1, 0),
        vec4(0, 0, 0, 1)
    );
}

/**
*	Modeling primitives
*/

float sphereSDF(vec3 samplePoint, float radius) {
    return length(samplePoint) - radius;
}

float boxSDF(vec3 samplePoint, vec3 dimensions)
{
  return length(max(abs(samplePoint) - dimensions, 0.0));
}

float roundBoxSDF( vec3 samplePoint, vec3 dimensions, float radius)
{
  return boxSDF(samplePoint, dimensions) - radius;
}

float repete( vec3 p, vec3 c )
{
    vec3 q = mod(p,c)-0.5*c;
    return sphereSDF( q , 0.07);
}

float sceneSDF(vec3 samplePoint, out int objectId) {

    float sphereDist = sphereSDF(samplePoint + vec3(0.0, -0.5, 0.0), 0.5);
	objectArray[0] = sphereDist;
	float wall1 = boxSDF(samplePoint + vec3(0.0, -3.0, 2.0), vec3(4.0, 3.0, 0.2));
	objectArray[1] = wall1;
	float wall2 = boxSDF(samplePoint + vec3(-2.0, -3.0, 0.0), vec3(0.2, 3.0, 4.0));
	objectArray[2] = wall2;
	float theFloor = boxSDF(samplePoint + vec3(0.0, 0.0, 0.0), vec3(4.0, 0.0, 4.0));
	objectArray[3] = theFloor;
	float walls = unionSDF(wall1, wall2);
	objectArray[4] = walls;
	float minDist = MAX_DIST;
	int minIndex = -1;

	for(int i = 0; i < 5; i++) {
        if(objectArray[i] < minDist) {
            minIndex = i;
            minDist = objectArray[i];
        }
	}
	objectId = minIndex;
	return  objectArray[minIndex];
}

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the eye to march before giving up
 */
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end, out int objectId) {
	float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection, objectId);
        if (dist < EPSILON) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}
            

/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * fragCoord: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p) {
    int objectId;
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z), objectId) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z), objectId),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z), objectId) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z), objectId),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON), objectId) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON), objectId)
    ));
}

/**
 * Lighting contribution of a single point light source via Phong illumination.
 * 
 * The vec3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */

 /*float shadow(vec3 p, vec3 dir, float mint, float maxt )
{
    for( float t=mint; t < maxt; )
    {
        float h = sceneSDF(p + dir*t);
        if( h<EPSILON )
            return 0.0;
        t += h;
    }
    return 1.0;
}
*/

float softShadow(vec3 p, vec3 dir, float mint, float maxt, float k)
{
    float res = 1.0;
    int objectId;
    for( float t=mint; t < maxt; )
    {
        float h = sceneSDF(p + dir*t, objectId);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
	float shadowing = softShadow(p, L, 0.1, length(lightPos - p), 8.0);

    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    } 
    
    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return shadowing*lightIntensity * (k_d * dotLN);
    }
	return shadowing * lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

/**
 * Lighting via Phong illumination.
 * 
 * The vec3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(0.0,
                          4.0,
                          1.0);
    vec3 light1Intensity = vec3(0.2, 0.2, 0.2);
    

    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    
    vec3 light2Pos = vec3(0.5 + 0.2*sin(0.1 * timeValue),
                          1.0 + 0.2*cos(0.1 * timeValue),
                          2.0);
    vec3 light2Intensity = vec3(0.3, 0.3, 0.3);

	color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);

	vec3 light3Pos = vec3(-3.0 + 0.2*sin(0.1 * timeValue),
                          2.0 + 0.2*cos(0.1 * timeValue),
                          3.0);

    vec3 light3Intensity = vec3(0.3, 0.3, 0.3);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light3Pos,
                                  light3Intensity);    
    return color;
}

/**
 * Return a transformation matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction.
 */
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);
	return mat4(
		vec4(s, 0.0),
		vec4(u, 0.0),
		vec4(-f, 0.0),
		vec4(0.0, 0.0, 0.0, 1)
	);
}

void main()
{
    vec3 eye = vec3(-3.0, 0.1*sin(timeValue) + 3.0, 5.0);
    vec3 dir = rayDirection(45.0, windowSize.xy, gl_FragCoord.xy);
    vec3 dirX = rayDirection(45.0, windowSize.xy, gl_FragCoord.xy + vec2(1,0));
    vec3 dirY = rayDirection(45.0, windowSize.xy, gl_FragCoord.xy + vec2(0,1));

	mat4 cameraTransform = viewMatrix(eye, vec3(-0.9, 1.1, 0.5), vec3(0.0, 1.0, 0.0));
	
	vec3 thatDir = (cameraTransform * vec4(dir, 0.0)).xyz;
    
    int objectId;

    float dist = shortestDistanceToSurface(eye, thatDir, MIN_DIST, MAX_DIST, objectId);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * thatDir;
    
    float div = 2.0 / float(objectId+1);
    vec3 K_a = material.ambient * div;
    vec3 K_d = material.diffuse * div;
    vec3 K_s = material.specular * div;
    float shininess = material.shininess * div;
    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    fragColor = vec4(color, 1.0);
} 
