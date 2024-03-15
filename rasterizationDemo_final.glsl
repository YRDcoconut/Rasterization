// filename: cw2_student.uclcg
// tabGroup: Coursework
// thumbnail: cw2_thumb.png
// displayname: Coursework 2 - 2023/2024
// shortDescription: Coursework 2 - Rasterization
// author: None
// isHidden: false 
function setup()
{
	UI = {};
	UI.tabs = [];
	UI.titleLong = 'Rasterization Demo';
	UI.titleShort = 'rasterizationDemo';
	UI.numFrames = 1000;
	UI.maxFPS = 25;
	UI.renderWidth = 200;
	UI.renderHeight = 100;

	UI.tabs.push(
		{
		visible: true,
		type: `x-shader/x-fragment`,
		title: `Rasterization`,
		id: `RasterizationDemoFS`,
		initialValue: ` 
#define SOLUTION_RASTERIZATION
#define SOLUTION_CLIPPING
#define SOLUTION_INTERPOLATION
#define SOLUTION_ZBUFFERING
#define SOLUTION_BLENDING
//#define SOLUTION_AALIAS

precision highp float;
uniform float time;

// Polygon / vertex functionality
const int MAX_VERTEX_COUNT = 8;

uniform ivec2 viewport;

struct Vertex {
    vec4 position;
    vec4 color;
};

struct Polygon {
    // Numbers of vertices, i.e., points in the polygon
    int vertexCount;
    // The vertices themselves
    Vertex vertices[MAX_VERTEX_COUNT];
};

// Appends a vertex to a polygon
void appendVertexToPolygon(inout Polygon polygon, Vertex element) {
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i == polygon.vertexCount) {
            polygon.vertices[i] = element;
        }
    }
    polygon.vertexCount++;
}

// Copy Polygon source to Polygon destination
void copyPolygon(inout Polygon destination, Polygon source) {
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        destination.vertices[i] = source.vertices[i];
    }
    destination.vertexCount = source.vertexCount;
}

// Get the i-th vertex from a polygon, but when asking for the one behind the last, get the first again
Vertex getWrappedPolygonVertex(Polygon polygon, int index) {
    if (index >= polygon.vertexCount) index -= polygon.vertexCount;
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i == index) return polygon.vertices[i];
    }
}

// Creates an empty polygon
void makeEmptyPolygon(out Polygon polygon) {
  polygon.vertexCount = 0;
}

// Clipping part

#define ENTERING 0
#define LEAVING 1
#define OUTSIDE 2
#define INSIDE 3

int getCrossType(Vertex poli1, Vertex poli2, Vertex wind1, Vertex wind2) {
#ifdef SOLUTION_CLIPPING
    // TODO
	//Similar to the methodology employed in the edge() function, 
	//we employ the cross product to determine on which side of the window boundary a point lies.
	
	//Utilizing the formula for cross product in 2D space 
	//vec A cross product vec B = A.x * B.y - B.x * A.y
	vec2 bound = wind2.position.xy - wind1.position.xy;
	vec2 edge1 = poli1.position.xy - wind1.position.xy;
	vec2 edge2 = poli2.position.xy - wind1.position.xy;
	
	float side1 = bound.x * edge1.y - edge1.x * bound.y;
	float side2 = bound.x * edge2.y - edge2.x * bound.y;
	
	if (side1 < 0.0 && side2 < 0.0) return INSIDE;
	if (side1 > 0.0 && side2 < 0.0) return ENTERING;
	if (side1 < 0.0 && side2 > 0.0) return LEAVING;
	if (side1 > 0.0 && side2 > 0.0) return OUTSIDE;

	
#else
    return INSIDE;
#endif
}

// This function assumes that the segments are not parallel or collinear.
Vertex intersect2D(Vertex a, Vertex b, Vertex c, Vertex d) {
#ifdef SOLUTION_CLIPPING
    // TODO
	//Calculate the point of intersection between a edge formed by two vertices and a given boundary
	//We initially compute the intersection point in 2D space
	Vertex intersection;
	
	vec2 edge = b.position.xy - a.position.xy;
	vec2 bound = d.position.xy - c.position.xy;
	
	//Considering the scenario wherein the slope is non-existent
	if (abs(edge.x) < 0.001 && abs(bound.x) > 0.001){
		intersection.position.x = a.position.x;
		float sBound = bound.y / bound.x;
		float bBound = c.position.y - sBound * c.position.x;
		intersection.position.y = intersection.position.x * sBound + bBound;		
	}
	
	else if (abs(edge.x) > 0.001 && abs(bound.x) < 0.001){
		intersection.position.x = c.position.x;
		float sEdge = edge.y / edge.x;
		float bEdge = a.position.y - sEdge * a.position.x;
		intersection.position.y = intersection.position.x * sEdge + bEdge;		
	}
	
	else {
		//edge and boundary can be represented using linear equation 
		//The intersected point can be found when line(edge) = line(boundary)

		//Compute the slope s and intercept b of edge and boundary
		float sEdge = edge.y / edge.x;
		float sBound = bound.y / bound.x;
		float bEdge = a.position.y - sEdge * a.position.x;
		float bBound = c.position.y - sBound * c.position.x;

		//Compute the coordinates of the intersection point

		intersection.position.x = (bBound - bEdge) / (sEdge - sBound);
		intersection.position.y = intersection.position.x * sEdge + bEdge;
	}
	
	
	//Interpolate a 3D property, it needs to be perspectively-correct
	//Notice the interpolation is non-linear here
	//We employ the magnitude to ascertain proportional values s and t, 
	//ensuring it still work when the edges are perpendicular to the coordinate axes
	float s = length(intersection.position.xy - a.position.xy) / length(a.position.xy - b.position.xy);
	intersection.position.z = 1.0 / ((1.0 / a.position.z) + s * ((1.0 / b.position.z) - (1.0 / a.position.z)));
	//Add w -> Homogeneous coordinate
	intersection.position.w = 1.0;
	
	//Then we interpolate the color
	//Computer t, which is a proportional parameter of 3D world depth z
	float t = length(intersection.position.z - a.position.z) / length(a.position.z - b.position.z);
	//intersection.color = (1.0 - t) * a.color + t * b.color;
	intersection.color = a.color;
	//Notice that when we do interpolation using fuction 'interpolateVertex', we pass 'projectedPolygon'
	//to this fuction, they are unclipped triangles. So actually we use the color of triangle vertices while interpolation
	//the colors of intersection points do not influnce the interpolation color at all.
	//I pass other values to 'intersection.color', the code still work, nothing changes
	
	return intersection;
#else
    return a;
#endif
}

void sutherlandHodgmanClip(Polygon unclipped, Polygon clipWindow, out Polygon result) {
    Polygon clipped;
    copyPolygon(clipped, unclipped);

    // Loop over the clip window
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i >= clipWindow.vertexCount) break;

        // Make a temporary copy of the current clipped polygon
        Polygon oldClipped;
        copyPolygon(oldClipped, clipped);

        // Set the clipped polygon to be empty
        makeEmptyPolygon(clipped);

        // Loop over the current clipped polygon
        for (int j = 0; j < MAX_VERTEX_COUNT; ++j) {
            if (j >= oldClipped.vertexCount) break;
            
            // Handle the j-th vertex of the clipped polygon. This should make use of the function 
            // intersect() to be implemented above.
#ifdef SOLUTION_CLIPPING
            // TODO
			Vertex wind1 = getWrappedPolygonVertex(clipWindow, i);
			Vertex wind2 = getWrappedPolygonVertex(clipWindow, i+1);
			
			Vertex poli1 = getWrappedPolygonVertex(oldClipped, j);
			Vertex poli2 = getWrappedPolygonVertex(oldClipped, j+1);
			
			int crossType = getCrossType(poli1, poli2, wind1, wind2);
			
			if (crossType == INSIDE){
				//Add only poli2
				appendVertexToPolygon(clipped, poli2);
			}
			
			if (crossType == OUTSIDE){
				//Do nothing				
			}
			
			if (crossType == ENTERING){
				//Add intersection and poli2
				appendVertexToPolygon(clipped, intersect2D(poli1, poli2, wind1, wind2));
				appendVertexToPolygon(clipped, poli2);
			}
			
			if (crossType == LEAVING){
				//Add only intersection
				appendVertexToPolygon(clipped, intersect2D(poli1, poli2, wind1, wind2));
			}
			
#else
            appendVertexToPolygon(clipped, getWrappedPolygonVertex(oldClipped, j));
#endif
        }
    }

    // Copy the last version to the output
    copyPolygon(result, clipped);
}

// SOLUTION_RASTERIZATION and culling part

#define INNER_SIDE 0
#define OUTER_SIDE 1

// Assuming a clockwise (vertex-wise) polygon, returns whether the input point 
// is on the inner or outer side of the edge (ab)
int edge(vec2 point, Vertex a, Vertex b) {
#ifdef SOLUTION_RASTERIZATION
    // TODO
	 //We can use cross product to decide whether a point is on the inner side or 
	 //outerside of the edge in 2D space. vec A cross product vec B = |A||B|sinTheta
	 //here Theta represents the angle of rotation from A to B, can have positive or negative values 
	 
	//Calculate the edge vector from a to b
	vec2 ab = b.position.xy - a.position.xy;
	//Calculate the vector from a to point
	vec2 ap = point - a.position.xy;
	//Utilizing the formula for cross product in 2D space 
	//vec A cross product vec B = A.x * B.y - B.x * A.y
	float side = ab.x * ap.y - ap.x * ab.y;
	
	
	if (side < 0.0) return INNER_SIDE;
	
#endif
    return OUTER_SIDE;
}

// Returns if a point is inside a polygon or not
bool isPointInPolygon(vec2 point, Polygon polygon) {
    // Don't evaluate empty polygons
    if (polygon.vertexCount == 0) return false;
    // Check against each edge of the polygon
    bool rasterise = true;
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i < polygon.vertexCount) {
#ifdef SOLUTION_RASTERIZATION
            // TODO
	Vertex a = getWrappedPolygonVertex(polygon, i);
	Vertex b = getWrappedPolygonVertex(polygon, i+1);
	int side = edge(point, a, b);
	if (side != INNER_SIDE){
		rasterise = false;
	}
#else
            rasterise = false;
#endif
        }
    }
    return rasterise;
}

bool isPointOnPolygonVertex(vec2 point, Polygon polygon) {
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i < polygon.vertexCount) {
          	ivec2 pixelDifference = ivec2(abs(polygon.vertices[i].position.xy - point) * vec2(viewport));
          	int pointSize = viewport.x / 200;
            if( pixelDifference.x <= pointSize && pixelDifference.y <= pointSize) {
              return true;
            }
        }
    }
    return false;
}

float triangleArea(vec2 a, vec2 b, vec2 c) {
    // https://en.wikipedia.org/wiki/Heron%27s_formula
    float ab = length(a - b);
    float bc = length(b - c);
    float ca = length(c - a);
    float s = (ab + bc + ca) / 2.0;
    return sqrt(max(0.0, s * (s - ab) * (s - bc) * (s - ca)));
}

Vertex interpolateVertex(vec2 point, Polygon polygon) {
    vec4 colorSum = vec4(0.0);
    vec4 positionSum = vec4(0.0);
    float weight_sum = 0.0;
	float weight_corr_sum = 0.0;
    
	for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i < polygon.vertexCount) {
#if defined(SOLUTION_INTERPOLATION) || defined(SOLUTION_ZBUFFERING)
            // TODO
			//Given a point and the target polygon, we need to construct a triangle
			//to calculate the weight of the point
			Vertex a = getWrappedPolygonVertex(polygon, i);
			Vertex b = getWrappedPolygonVertex(polygon, i+1);
			Vertex c = getWrappedPolygonVertex(polygon, i+2);
			
			vec2 a_xy = a.position.xy;
			vec2 b_xy = b.position.xy;
			vec2 c_xy = c.position.xy;
						
			float weight_a = triangleArea(point, b_xy, c_xy);
			float weight_b = triangleArea(point, a_xy, c_xy);
			float weight_c = triangleArea(point, b_xy, a_xy);
			
			float weight_corr_a = weight_a / a.position.z;
			float weight_corr_b = weight_b / b.position.z;
			float weight_corr_c = weight_c / c.position.z;
#endif

#ifdef SOLUTION_ZBUFFERING
            // TODO
			weight_corr_sum += weight_corr_a + weight_corr_b + weight_corr_c;
#endif

#ifdef SOLUTION_INTERPOLATION
            // TODO
			colorSum += a.color * weight_a + b.color * weight_b + c.color * weight_c;
        positionSum += a.position * weight_a + b.position * weight_b + c.position * weight_c;
			weight_sum += weight_a + weight_b + weight_c;
#endif
        }
    }
    Vertex result = polygon.vertices[0];
  
#ifdef SOLUTION_INTERPOLATION
    // TODO
	result.color = colorSum / weight_sum;
   result.position = positionSum / weight_sum;
#endif
#ifdef SOLUTION_ZBUFFERING
    // TODO
	result.color = colorSum / weight_corr_sum;
	result.position = positionSum / weight_corr_sum;
#endif

  return result;
}

// Projection part

// Used to generate a projection matrix.
mat4 computeProjectionMatrix() {
    mat4 projectionMatrix = mat4(1);
  
  	float aspect = float(viewport.x) / float(viewport.y);  
  	float imageDistance = 2.0;
		
	float xMin = -0.5;
	float yMin = -0.5;
	float xMax = 0.5;
	float yMax = 0.5;

	
    mat4 regPyr = mat4(1.0);
    float d = imageDistance; 
		
    float w = xMax - xMin;
    float h = (yMax - yMin) / aspect;
    float x = xMax + xMin; 
    float y = yMax + yMin; 
	
    regPyr[0] = vec4(d / w, 0, 0, 0);
    regPyr[1] = vec4(0, d / h, 0, 0);
	regPyr[2] = vec4(-x/w, -y/h, 1, 0);
	regPyr[3] = vec4(0,0,0,1);
	
    // Scale by 1/D
    mat4 scaleByD = mat4(1.0/d);
    scaleByD[3][3] = 1.0;

	// Perspective Division
	mat4 perspDiv = mat4(1.0);
	perspDiv[2][3] = 1.0;
	
    projectionMatrix = perspDiv * scaleByD * regPyr;
	
  
    return projectionMatrix;
}

// Used to generate a simple "look-at" camera. 
mat4 computeViewMatrix(vec3 VRP, vec3 TP, vec3 VUV) {
    mat4 viewMatrix = mat4(1);

	// The VPN is pointing away from the TP. Can also be modeled the other way around.
    vec3 VPN = TP - VRP;
  
    // Generate the camera axes.
    vec3 n = normalize(VPN);
    vec3 u = normalize(cross(VUV, n));
    vec3 v = normalize(cross(n, u));

    viewMatrix[0] = vec4(u[0], v[0], n[0], 0);
    viewMatrix[1] = vec4(u[1], v[1], n[1], 0);
    viewMatrix[2] = vec4(u[2], v[2], n[2], 0);
    viewMatrix[3] = vec4(-dot(VRP, u), -dot(VRP, v), -dot(VRP, n), 1);
    return viewMatrix;
}

vec3 getCameraPosition() {  
    //return 10.0 * vec3(sin(time * 1.3), 0, cos(time * 1.3));
	return 10.0 * vec3(sin(0.0), 0, cos(0.0));
}

// Takes a single input vertex and projects it using the input view and projection matrices
vec4 projectVertexPosition(vec4 position) {

  // Set the parameters for the look-at camera.
    vec3 TP = vec3(0, 0, 0);
  	vec3 VRP = getCameraPosition();
    vec3 VUV = vec3(0, 1, 0);
  
    // Compute the view matrix.
    mat4 viewMatrix = computeViewMatrix(VRP, TP, VUV);

  // Compute the projection matrix.
    mat4 projectionMatrix = computeProjectionMatrix();
  
    vec4 projectedVertex = projectionMatrix * viewMatrix * position;
    projectedVertex.xyz = (projectedVertex.xyz / projectedVertex.w);
    return projectedVertex;
}

// Projects all the vertices of a polygon
void projectPolygon(inout Polygon projectedPolygon, Polygon polygon) {
    copyPolygon(projectedPolygon, polygon);
    for (int i = 0; i < MAX_VERTEX_COUNT; ++i) {
        if (i < polygon.vertexCount) {
            projectedPolygon.vertices[i].position = projectVertexPosition(polygon.vertices[i].position);
        }
    }
}

#define BLEND_GL_ZERO 0
#define BLEND_GL_ONE 1
#define BLEND_GL_SRC_ALPHA 2
#define BLEND_GL_ONE_MINUS_SRC_ALPHA 3


// Returns the blend factor based on the symbol passed
#ifdef SOLUTION_BLENDING
float getBlendFactor(int symbol, float originalAlpha){
	float blendFactor;
	if (symbol == 0) {
		blendFactor = 0.0;
	} else if (symbol == 1) {
		blendFactor = 1.0;
	} else if (symbol == 2) {
		blendFactor = originalAlpha;
	} else if (symbol == 3) {
		blendFactor = 1.0 - originalAlpha;
	}

	return blendFactor;
}
#endif


// Draws a polygon by projecting, clipping, ratserizing and interpolating it
void drawPolygon(
  vec2 point, 
  Polygon clipWindow, 
  Polygon oldPolygon, 
  inout vec4 color, 
  inout float depth)
{
    Polygon projectedPolygon;
    projectPolygon(projectedPolygon, oldPolygon);  
  
    Polygon clippedPolygon;
    sutherlandHodgmanClip(projectedPolygon, clipWindow, clippedPolygon);

    if (isPointInPolygon(point, clippedPolygon)) {
      
        Vertex interpolatedVertex = interpolateVertex(point, projectedPolygon);
		
		// Set your BLEND symbols here
		//int src_blend_mode = BLEND_GL_ONE;
		//int dst_blend_mode = BLEND_GL_ZERO;
		//int src_blend_mode = BLEND_GL_ONE;
		//int dst_blend_mode = BLEND_GL_ONE;
		int src_blend_mode = BLEND_GL_SRC_ALPHA;
		int dst_blend_mode = BLEND_GL_ONE_MINUS_SRC_ALPHA;
		
#ifdef SOLUTION_ZBUFFERING
		// TODO 
		if (interpolatedVertex.position.z >= depth)return;
		
#ifdef SOLUTION_BLENDING
		// TODO
		float srcAlpha = getBlendFactor(src_blend_mode, interpolatedVertex.color.a);
		float dstAlpha = getBlendFactor(dst_blend_mode, interpolatedVertex.color.a);
		depth = interpolatedVertex.position.z; 
		color = srcAlpha * interpolatedVertex.color + dstAlpha * color; //GL_ADD
#else
			// TODO
		color = interpolatedVertex.color;
     depth = interpolatedVertex.position.z;
#endif
			// TODO
#else
		color = interpolatedVertex.color;
    	depth = interpolatedVertex.position.z;      
#endif
		
   }
  
   if (isPointOnPolygonVertex(point, clippedPolygon)) {
        color = vec4(1);
   }
}

// Main function calls

void drawScene(vec2 pixelCoord, inout vec4 color) {
    color = vec4(0.3, 0.3, 0.3, 1.0);
  
  	// Convert from GL pixel coordinates 0..N-1 to our screen coordinates -1..1
    vec2 point = 2.0 * pixelCoord / vec2(viewport) - vec2(1.0);

    Polygon clipWindow;
    clipWindow.vertices[0].position = vec4(-0.65,  0.95, 1.0, 1.0);
    clipWindow.vertices[1].position = vec4( 0.65,  0.75, 1.0, 1.0);
    clipWindow.vertices[2].position = vec4( 0.75, -0.65, 1.0, 1.0);
    clipWindow.vertices[3].position = vec4(-0.75, -0.85, 1.0, 1.0);
    clipWindow.vertexCount = 4;
  
  	// Draw the area outside the clip region to be dark
    color = isPointInPolygon(point, clipWindow) ? vec4(vec3(0.5), 1.0) : color;

    const int triangleCount = 3;
    Polygon triangles[triangleCount];
  
	triangles[0].vertexCount = 3;
    triangles[0].vertices[0].position = vec4(-3, -2, 0.0, 1.0);
    triangles[0].vertices[1].position = vec4(4, 0, 3.0, 1.0);
    triangles[0].vertices[2].position = vec4(-1, 2, 0.0, 1.0);
    triangles[0].vertices[0].color = vec4(1.0, 1.0, 0.2, 1.0);
    triangles[0].vertices[1].color = vec4(0.8, 0.8, 0.8, 1.0);
    triangles[0].vertices[2].color = vec4(0.5, 0.2, 0.5, 1.0);
  
	triangles[1].vertexCount = 3;
    triangles[1].vertices[0].position = vec4(3.0, 2.0, -2.0, 1.0);
  	triangles[1].vertices[2].position = vec4(0.0, -2.0, 3.0, 1.0);
    triangles[1].vertices[1].position = vec4(-1.0, 2.0, 4.0, 1.0);
    triangles[1].vertices[1].color = vec4(0.2, 1.0, 0.1, 0.5);
    triangles[1].vertices[2].color = vec4(1.0, 1.0, 1.0, 0.5);
    triangles[1].vertices[0].color = vec4(0.1, 0.2, 1.0, 0.5);
	
	triangles[2].vertexCount = 3;	
	triangles[2].vertices[0].position = vec4(-1.0, -2.0, 0.0, 1.0);
  	triangles[2].vertices[1].position = vec4(-4.0, 2.0, 0.0, 1.0);
    triangles[2].vertices[2].position = vec4(-4.0, -2.0, 0.0, 1.0);
    triangles[2].vertices[1].color = vec4(0.2, 1.0, 0.1, 1.0);
    triangles[2].vertices[2].color = vec4(1.0, 1.0, 1.0, 1.0);
    triangles[2].vertices[0].color = vec4(0.1, 0.2, 1.0, 1.0);
	
    float depth = 10000.0;
	
    // Project and draw all the triangles
    for (int i = 0; i < triangleCount; i++) {
        drawPolygon(point, clipWindow, triangles[i], color, depth);
    }   
}

void main() {
	
	vec4 color = vec4(0.0);
	
#ifdef SOLUTION_AALIAS
	vec4 sumColor;
	const float range = 1.0; //The lager 'range', the higher quality and the lower speed
   float sampleCount = 0.0;
	
    for (float x = -0.5 - 1.0 * range; x <= 0.5 + 1.0 * range; x += 1.0) {
        for (float y = -0.5 - 1.0 * range; y <= 0.5 + 1.0 * range; y += 1.0) {
            vec2 sampleCoord = gl_FragCoord.xy + vec2(x, y);
            drawScene(sampleCoord, color);
			sumColor += color;
        sampleCount += 1.0;
        }
    }
    color = sumColor / sampleCount;	
#else
    drawScene(gl_FragCoord.xy, color);
#endif
	
	gl_FragColor.rgba = color;
}`,
		description: ``,
		wrapFunctionStart: ``,
		wrapFunctionEnd: ``
	});

	UI.tabs.push(
		{
		visible: false,
		type: `x-shader/x-vertex`,
		title: `RasterizationDemoTextureVS - GL`,
		id: `RasterizationDemoTextureVS`,
		initialValue: `attribute vec3 position;
    attribute vec2 textureCoord;

    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;

    varying highp vec2 vTextureCoord;
  
    void main(void) {
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        vTextureCoord = textureCoord;
    }
`,
		description: ``,
		wrapFunctionStart: ``,
		wrapFunctionEnd: ``
	});

	UI.tabs.push(
		{
		visible: false,
		type: `x-shader/x-vertex`,
		title: `RasterizationDemoVS - GL`,
		id: `RasterizationDemoVS`,
		initialValue: `attribute vec3 position;

    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;

    void main(void) {
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
`,
		description: ``,
		wrapFunctionStart: ``,
		wrapFunctionEnd: ``
	});

	UI.tabs.push(
		{
		visible: false,
		type: `x-shader/x-fragment`,
		title: `RasterizationDemoTextureFS - GL`,
		id: `RasterizationDemoTextureFS`,
		initialValue: `
        varying highp vec2 vTextureCoord;

        uniform sampler2D uSampler;

        void main(void) {
            gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
        }
`,
		description: ``,
		wrapFunctionStart: ``,
		wrapFunctionEnd: ``
	});

	 return UI; 
}//!setup

var gl;
function initGL(canvas) {
    try {
        gl = canvas.getContext("webgl");
        gl.viewportWidth = canvas.width;
        gl.viewportHeight = canvas.height;
    } catch (e) {
    }
    if (!gl) {
        alert("Could not initialise WebGL, sorry :-(");
    }
}

function evalJS(id) {
    var jsScript = document.getElementById(id);
    eval(jsScript.innerHTML);
}

function getShader(gl, id) {
    var shaderScript = document.getElementById(id);
    if (!shaderScript) {
        return null;
    }

    var str = "";
    var k = shaderScript.firstChild;
    while (k) {
        if (k.nodeType == 3) {
            str += k.textContent;
        }
        k = k.nextSibling;
    }

    var shader;
    if (shaderScript.type == "x-shader/x-fragment") {
        shader = gl.createShader(gl.FRAGMENT_SHADER);
    } else if (shaderScript.type == "x-shader/x-vertex") {
        shader = gl.createShader(gl.VERTEX_SHADER);
    } else {
        return null;
    }

    gl.shaderSource(shader, str);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        alert(gl.getShaderInfoLog(shader));
        return null;
    }

    return shader;
}

function RasterizationDemo() {
}

RasterizationDemo.prototype.initShaders = function() {

    this.shaderProgram = gl.createProgram();

    gl.attachShader(this.shaderProgram, getShader(gl, "RasterizationDemoVS"));
    gl.attachShader(this.shaderProgram, getShader(gl, "RasterizationDemoFS"));
    gl.linkProgram(this.shaderProgram);

    if (!gl.getProgramParameter(this.shaderProgram, gl.LINK_STATUS)) {
        alert("Could not initialise shaders");
    }

    gl.useProgram(this.shaderProgram);

    this.shaderProgram.vertexPositionAttribute = gl.getAttribLocation(this.shaderProgram, "position");
    gl.enableVertexAttribArray(this.shaderProgram.vertexPositionAttribute);

    this.shaderProgram.projectionMatrixUniform = gl.getUniformLocation(this.shaderProgram, "projectionMatrix");
    this.shaderProgram.modelviewMatrixUniform = gl.getUniformLocation(this.shaderProgram, "modelViewMatrix");
}

RasterizationDemo.prototype.initTextureShaders = function() {

    this.textureShaderProgram = gl.createProgram();

    gl.attachShader(this.textureShaderProgram, getShader(gl, "RasterizationDemoTextureVS"));
    gl.attachShader(this.textureShaderProgram, getShader(gl, "RasterizationDemoTextureFS"));
    gl.linkProgram(this.textureShaderProgram);

    if (!gl.getProgramParameter(this.textureShaderProgram, gl.LINK_STATUS)) {
        alert("Could not initialise shaders");
    }

    gl.useProgram(this.textureShaderProgram);

    this.textureShaderProgram.vertexPositionAttribute = gl.getAttribLocation(this.textureShaderProgram, "position");
    gl.enableVertexAttribArray(this.textureShaderProgram.vertexPositionAttribute);

    this.textureShaderProgram.textureCoordAttribute = gl.getAttribLocation(this.textureShaderProgram, "textureCoord");
    gl.enableVertexAttribArray(this.textureShaderProgram.textureCoordAttribute);
    //gl.vertexAttribPointer(this.textureShaderProgram.textureCoordAttribute, 2, gl.FLOAT, false, 0, 0);

    this.textureShaderProgram.projectionMatrixUniform = gl.getUniformLocation(this.textureShaderProgram, "projectionMatrix");
    this.textureShaderProgram.modelviewMatrixUniform = gl.getUniformLocation(this.textureShaderProgram, "modelViewMatrix");
}

RasterizationDemo.prototype.initBuffers = function() {
    this.triangleVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.triangleVertexPositionBuffer);
    
    var vertices = [
         -1.0,  -1.0,  0.0,
         -1.0,   1.0,  0.0,
          1.0,   1.0,  0.0,

         -1.0,  -1.0,  0.0,
          1.0,  -1.0,  0.0,
          1.0,   1.0,  0.0,
     ];
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
    this.triangleVertexPositionBuffer.itemSize = 3;
    this.triangleVertexPositionBuffer.numItems = 3 * 2;

    this.textureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.textureCoordBuffer);

    var textureCoords = [
        0.0,  0.0,
        0.0,  1.0,
        1.0,  1.0,

        0.0,  0.0,
        1.0,  0.0,
        1.0,  1.0
    ];
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(textureCoords), gl.STATIC_DRAW);
    this.textureCoordBuffer.itemSize = 2;
}

function getTime() {  
	var d = new Date();
	return d.getMinutes() * 60.0 + d.getSeconds() + d.getMilliseconds() / 1000.0;
}


RasterizationDemo.prototype.initTextureFramebuffer = function() {
    // create off-screen framebuffer
    this.framebuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffer);
    this.framebuffer.width = this.prerender_width;
    this.framebuffer.height = this.prerender_height;

    // create RGB texture
    this.framebufferTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, this.framebufferTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.framebuffer.width, this.framebuffer.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);//LINEAR_MIPMAP_NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    //gl.generateMipmap(gl.TEXTURE_2D);

    // create depth buffer
    this.renderbuffer = gl.createRenderbuffer();
    gl.bindRenderbuffer(gl.RENDERBUFFER, this.renderbuffer);
    gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, this.framebuffer.width, this.framebuffer.height);

    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.framebufferTexture, 0);
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, this.renderbuffer);

    // reset state
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindRenderbuffer(gl.RENDERBUFFER, null);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
}

RasterizationDemo.prototype.drawScene = function() {
            
    gl.bindFramebuffer(gl.FRAMEBUFFER, env.framebuffer);
    gl.useProgram(this.shaderProgram);
    gl.viewport(0, 0, this.prerender_width, this.prerender_height);
    gl.clear(gl.COLOR_BUFFER_BIT);

        var perspectiveMatrix = new J3DIMatrix4();  
        perspectiveMatrix.setUniform(gl, this.shaderProgram.projectionMatrixUniform, false);

        var modelViewMatrix = new J3DIMatrix4();    
        modelViewMatrix.setUniform(gl, this.shaderProgram.modelviewMatrixUniform, false);

        gl.uniform2iv(gl.getUniformLocation(this.shaderProgram, "viewport"), [getRenderTargetWidth(), getRenderTargetHeight()]);
            
		gl.uniform1f(gl.getUniformLocation(this.shaderProgram, "time"), getTime());  

        gl.bindBuffer(gl.ARRAY_BUFFER, this.triangleVertexPositionBuffer);
        gl.vertexAttribPointer(this.shaderProgram.vertexPositionAttribute, this.triangleVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, this.textureCoordBuffer);
        gl.vertexAttribPointer(this.textureShaderProgram.textureCoordAttribute, this.textureCoordBuffer.itemSize, gl.FLOAT, false, 0, 0);
        
        gl.drawArrays(gl.TRIANGLES, 0, this.triangleVertexPositionBuffer.numItems);

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.useProgram(this.textureShaderProgram);
    gl.viewport(0, 0, this.render_width, this.render_height);
    gl.clear(gl.COLOR_BUFFER_BIT);

        var perspectiveMatrix = new J3DIMatrix4();  
        perspectiveMatrix.setUniform(gl, this.textureShaderProgram.projectionMatrixUniform, false);

        var modelViewMatrix = new J3DIMatrix4();    
        modelViewMatrix.setUniform(gl, this.textureShaderProgram.modelviewMatrixUniform, false);

        gl.bindTexture(gl.TEXTURE_2D, this.framebufferTexture);
        gl.uniform1i(gl.getUniformLocation(this.textureShaderProgram, "uSampler"), 0);
            
        gl.bindBuffer(gl.ARRAY_BUFFER, this.triangleVertexPositionBuffer);
        gl.vertexAttribPointer(this.textureShaderProgram.vertexPositionAttribute, this.triangleVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, this.textureCoordBuffer);
        gl.vertexAttribPointer(this.textureShaderProgram.textureCoordAttribute, this.textureCoordBuffer.itemSize, gl.FLOAT, false, 0, 0);
        
        gl.drawArrays(gl.TRIANGLES, 0, this.triangleVertexPositionBuffer.numItems);
}

RasterizationDemo.prototype.run = function() {

    this.render_width     = 800;
    this.render_height    = 400;

    this.prerender_width  = this.render_width;
    this.prerender_height = this.render_height;

    this.initTextureFramebuffer();
    this.initShaders();
    this.initTextureShaders();
    this.initBuffers();
};

function init() {   
    env = new RasterizationDemo();

    return env;
}

function compute(canvas)
{
    env.run();
    env.drawScene();
}
