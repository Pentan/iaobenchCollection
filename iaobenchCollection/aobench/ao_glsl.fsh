
#ifdef GL_ES
precision highp float;
#endif

#define NSUBSAMPLES  2. // float
#define NAO_SAMPLES  8  // int

uniform vec2 resolution;

// FragmentProgram
//
// porting GLSL by kioku based on syoyo's AS3 Ambient Occlusion
// [http://lucille.atso-net.jp/blog/?p=638]

struct Ray
{
	vec3 org;
	vec3 dir;
};
struct Sphere
{
	vec3 center;
	float radius;
};
struct Plane
{
	vec3 p;
	vec3 n;
};

struct Intersection
{
    float t;
    vec3 p;     // hit point
    vec3 n;     // normal
    int hit;
};

void shpere_intersect(Sphere s,  Ray ray, inout Intersection isect)
{
    // rs = ray.org - sphere.center
    vec3 rs = ray.org - s.center;
    float B = dot(rs, ray.dir);
    float C = dot(rs, rs) - (s.radius * s.radius);
    float D = B * B - C;
	
    if (D > 0.0)
    {
		float t = -B - sqrt(D);
		if ( (t > 0.0) && (t < isect.t) )
		{
			isect.t = t;
			isect.hit = 1;
			
			// calculate normal.
			vec3 p = ray.org + ray.dir * t;
			vec3 n = p - s.center;
			n = normalize(n);
			isect.n = n;
			isect.p = p;
		}
	}
}

void plane_intersect(Plane pl, Ray ray, inout Intersection isect)
{
	// d = -(p . n)
	// t = -(ray.org . n + d) / (ray.dir . n)
	float d = -dot(pl.p, pl.n);
	float v = dot(ray.dir, pl.n);
	
	if (abs(v) < 1.0e-6)
		return; // the plane is parallel to the ray.
	
    float t = -(dot(ray.org, pl.n) + d) / v;
	
    if ( (t > 0.0) && (t < isect.t) )
    {
		isect.hit = 1;
		isect.t   = t;
		isect.n   = pl.n;
		/*
		 vec3 p = vec3(ray.org.x + t * ray.dir.x,
		 ray.org.y + t * ray.dir.y,
		 ray.org.z + t * ray.dir.z);
		 */
		vec3 p = ray.org + t * ray.dir;
		isect.p = p;
	}
}

Sphere sphere[3];
Plane plane;
void Intersect(Ray r, inout Intersection i)
{
	for (int c = 0; c < 3; c++)
	{
		shpere_intersect(sphere[c], r, i);
	}
	plane_intersect(plane, r, i);
}

void orthoBasis(out vec3 basis[3], vec3 n)
{
	basis[2] = vec3(n.x, n.y, n.z);
	basis[1] = vec3(0.0, 0.0, 0.0);
	
	if ((n.x < 0.6) && (n.x > -0.6))
		basis[1].x = 1.0;
	else if ((n.y < 0.6) && (n.y > -0.6))
		basis[1].y = 1.0;
	else if ((n.z < 0.6) && (n.z > -0.6))
		basis[1].z = 1.0;
	else
		basis[1].x = 1.0;
	
	
	basis[0] = cross(basis[1], basis[2]);
	basis[0] = normalize(basis[0]);
	
	basis[1] = cross(basis[2], basis[0]);
	basis[1] = normalize(basis[1]);
	
}

int seed = 0;
float random()
{
	seed = int(mod(float(seed)*1364.0+626.0, 509.0));
	return float(seed)/509.0;
}

vec3 computeAO(inout Intersection isect)
{
    const int ntheta = NAO_SAMPLES;
    const int nphi   = NAO_SAMPLES;
    const float eps  = 0.0001;
	
    // Slightly move ray org towards ray dir to avoid numerical probrem.
    vec3 p = isect.p + eps * isect.n;
	
    // Calculate orthogonal basis.
    vec3 basis[3];
    orthoBasis(basis, isect.n);
	
	mat3 basismat;
	basismat[0] = basis[0];
	basismat[1] = basis[1];
	basismat[2] = basis[2];
	
    float occlusion = 0.0;
	
    for (int j = 0; j < ntheta; j++)
    {
		for (int i = 0; i < nphi; i++)
		{
			// Pick a random ray direction with importance sampling.
			// p = cos(theta) / 3.141592
			float r = sqrt(random());
			float phi = 2.0 * 3.141592 * random();
			
			vec3 ref;
			ref.x = cos(phi) * sqrt(1.0 - r);
			ref.y = sin(phi) * sqrt(1.0 - r);
			ref.z = sqrt(r);
			
			// local -> global
			vec3 rray;
			/*
			 rray.x = ref.x * basis[0].x + ref.y * basis[1].x + ref.z * basis[2].x;
			 rray.y = ref.x * basis[0].y + ref.y * basis[1].y + ref.z * basis[2].y;
			 rray.z = ref.x * basis[0].z + ref.y * basis[1].z + ref.z * basis[2].z;
			*/
			rray = basismat * ref;
			vec3 raydir = vec3(rray.x, rray.y, rray.z);
			
			Ray ray;
			ray.org = p;
			ray.dir = raydir;
			
			Intersection occIsect;
			occIsect.hit = 0;
			occIsect.t = 1.0e+30;
			occIsect.n = occIsect.p = vec3(0, 0, 0);
			Intersect(ray, occIsect);
			if (occIsect.hit != 0)
				occlusion += 1.0;
		}
	}
	
	// [0.0, 1.0]
	occlusion = (float(ntheta * nphi) - occlusion) / float(ntheta * nphi);
	return vec3(occlusion, occlusion, occlusion);
}

void main()
{
	sphere[0].center = vec3(-2.0, 0.0, -3.5);
	sphere[0].radius = 0.5;
	sphere[1].center = vec3(-0.5, 0.0, -3.0);
	sphere[1].radius = 0.5;
	sphere[2].center = vec3(1.0, 0.0, -2.2);
	sphere[2].radius = 0.5;
	plane.p = vec3(0,-0.5, 0);
	plane.n = vec3(0, 1.0, 0);
	
	vec4 col = vec4(0,0,0,1);
	
	for(float v = 0.; v < NSUBSAMPLES; v+=1.) {
		for(float u = 0.; u < NSUBSAMPLES; u+=1.) {
			vec3 dir = vec3((gl_FragCoord.xy + vec2(u, v) / NSUBSAMPLES - resolution * 0.5) * 2.0 / resolution.yy, -1.0);
			dir.y *= -1.0;
			
			Ray r;
			r.org = vec3(0.0, 0.0, 0.0);
			r.dir = normalize(dir);
			seed = int(mod(dir.x * dir.y * 4525434.0, 65536.0));
			
			Intersection i;
			i.hit = 0;
			i.t = 1.0e+30;
			i.n = i.p = vec3(0, 0, 0);
			
			Intersect(r, i);
			if (i.hit != 0)
			{
				col.rgb += computeAO(i);
				//col.rgb += vec3(1.0, 0.5, 0.5) * max(0., dot(i.n, vec3(0.577, 0.577, 0.577))) ;
			}
		}
	}
	col.rgb /= NSUBSAMPLES * NSUBSAMPLES;
	
	gl_FragColor = clamp(col, 0.0, 1.0);
}

/*
void main() {
	vec3 org = vec3(0.0, 0.0, 0.0);
	vec3 dir = vec3((gl_FragCoord.xy - resolution * 0.5) * 2.0 / resolution.yy, -1.0);
	normalize(dir);
	
	gl_FragColor = vec4(abs(dir), 1.0);
}
*/
