// make: llvm-gcc -o ao_f_gcd_xor -O3 ao_f_gcd_xor.c -lm
// -mfpmath=sse -msse2 
// cc -Wall -o ao_f_gcd_xor ao_f_gcd_xor.c -lm
// clang -O3 -o ao_f_gcd_xor ao_f_gcd_xor.c -lm

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>

/*
#include <Block.h>
#include <dispatch/dispatch.h>

// 
#include <sys/time.h>

static double gettimeofday_sec() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + (double)tv.tv_usec * 1e-6;
}

#define SAVE_AS_BMP
#ifdef SAVE_AS_BMP
    #include "savebmp.c"
#endif
*/

#include "xorshiftrandom.h"
//

#define WIDTH        256
#define HEIGHT       256
#define NSUBSAMPLES  2
#define NAO_SAMPLES  8

#define TILE_W       64
#define TILE_H       64

typedef struct _vec
{
    float x;
    float y;
    float z;
} vec;


typedef struct _Isect
{
    float t;
    vec    p;
    vec    n;
    int    hit; 
} Isect;

typedef struct _Sphere
{
    vec    center;
    float radius;

} Sphere;

typedef struct _Plane
{
    vec    p;
    vec    n;

} Plane;

typedef struct _Ray
{
    vec    org;
    vec    dir;
} Ray;

static Sphere spheres[3];
static Plane  plane;

static float vdot(vec v0, vec v1)
{
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
}

static void vcross(vec *c, vec v0, vec v1)
{
    
    c->x = v0.y * v1.z - v0.z * v1.y;
    c->y = v0.z * v1.x - v0.x * v1.z;
    c->z = v0.x * v1.y - v0.y * v1.x;
}

static void vnormalize(vec *c)
{
    float length = sqrt(vdot((*c), (*c)));

    if (fabs(length) > 1.0e-17) {
        c->x /= length;
        c->y /= length;
        c->z /= length;
    }
}

static void
ray_sphere_intersect(Isect *isect, const Ray *ray, const Sphere *sphere)
{
    vec rs;

    rs.x = ray->org.x - sphere->center.x;
    rs.y = ray->org.y - sphere->center.y;
    rs.z = ray->org.z - sphere->center.z;

    float B = vdot(rs, ray->dir);
    float C = vdot(rs, rs) - sphere->radius * sphere->radius;
    float D = B * B - C;

    if (D > 0.0) {
        float t = -B - sqrt(D);
        
        if ((t > 0.0) && (t < isect->t)) {
            isect->t = t;
            isect->hit = 1;
            
            isect->p.x = ray->org.x + ray->dir.x * t;
            isect->p.y = ray->org.y + ray->dir.y * t;
            isect->p.z = ray->org.z + ray->dir.z * t;

            isect->n.x = isect->p.x - sphere->center.x;
            isect->n.y = isect->p.y - sphere->center.y;
            isect->n.z = isect->p.z - sphere->center.z;

            vnormalize(&(isect->n));
        }
    }
}

static void
ray_plane_intersect(Isect *isect, const Ray *ray, const Plane *plane)
{
    float d = -vdot(plane->p, plane->n);
    float v = vdot(ray->dir, plane->n);

    if (fabs(v) < 1.0e-17) return;

    float t = -(vdot(ray->org, plane->n) + d) / v;

    if ((t > 0.0) && (t < isect->t)) {
        isect->t = t;
        isect->hit = 1;
        
        isect->p.x = ray->org.x + ray->dir.x * t;
        isect->p.y = ray->org.y + ray->dir.y * t;
        isect->p.z = ray->org.z + ray->dir.z * t;

        isect->n = plane->n;
    }
}

static void
orthoBasis(vec *basis, vec n)
{
    basis[2] = n;
    basis[1].x = 0.0; basis[1].y = 0.0; basis[1].z = 0.0;

    if ((n.x < 0.6) && (n.x > -0.6)) {
        basis[1].x = 1.0;
    } else if ((n.y < 0.6) && (n.y > -0.6)) {
        basis[1].y = 1.0;
    } else if ((n.z < 0.6) && (n.z > -0.6)) {
        basis[1].z = 1.0;
    } else {
        basis[1].x = 1.0;
    }

    vcross(&basis[0], basis[1], basis[2]);
    vnormalize(&basis[0]);

    vcross(&basis[1], basis[2], basis[0]);
    vnormalize(&basis[1]);
}


static void ambient_occlusion(vec *col, const Isect *isect, XorShift128 *rnd)
{
    int    i, j;
    int    ntheta = NAO_SAMPLES;
    int    nphi   = NAO_SAMPLES;
    float eps = 0.0001;

    vec p;

    p.x = isect->p.x + eps * isect->n.x;
    p.y = isect->p.y + eps * isect->n.y;
    p.z = isect->p.z + eps * isect->n.z;

    vec basis[3];
    orthoBasis(basis, isect->n);

    float occlusion = 0.0;

    for (j = 0; j < ntheta; j++) {
        for (i = 0; i < nphi; i++) {
            float theta = sqrt(xorshift128NextFloat(rnd));
            float phi   = 2.0 * M_PI * xorshift128NextFloat(rnd);
            //float theta = sqrt(xorshift128NextDouble(rnd));
            //float phi   = 2.0 * M_PI * xorshift128NextDouble(rnd);


            float x = cos(phi) * theta;
            float y = sin(phi) * theta;
            float z = sqrt(1.0 - theta * theta);

            // local -> global
            float rx = x * basis[0].x + y * basis[1].x + z * basis[2].x;
            float ry = x * basis[0].y + y * basis[1].y + z * basis[2].y;
            float rz = x * basis[0].z + y * basis[1].z + z * basis[2].z;

            Ray ray;

            ray.org = p;
            ray.dir.x = rx;
            ray.dir.y = ry;
            ray.dir.z = rz;

            Isect occIsect;
            occIsect.t   = 1.0e+17;
            occIsect.hit = 0;

            ray_sphere_intersect(&occIsect, &ray, &spheres[0]); 
            ray_sphere_intersect(&occIsect, &ray, &spheres[1]); 
            ray_sphere_intersect(&occIsect, &ray, &spheres[2]); 
            ray_plane_intersect (&occIsect, &ray, &plane); 

            if (occIsect.hit) occlusion += 1.0;
            
        }
    }

    occlusion = (ntheta * nphi - occlusion) / (float)(ntheta * nphi);

    col->x = occlusion;
    col->y = occlusion;
    col->z = occlusion;
}

static unsigned char
clamp(float f)
{
  int i = (int)(f * 255.5);

  if (i < 0) i = 0;
  if (i > 255) i = 255;

  return (unsigned char)i;
}

static int min_i(int a, int b) {
    return (a < b)? a:b;
}

static void
render_tile(unsigned char *img, int comps, float *fimg, int w, int h, int nsubsamples, int tilex, int tiley, int tilew, int tileh)
{
    int endx = tilex + min_i(tilew, w - tilex);
    int endy = tiley + min_i(tileh, h - tiley);
    
    int x, y;
    int u, v;
    
    XorShift128 rnd;
    xorshift128Init(&rnd, (tilex | (endx << 8) | (tiley << 16) | (endy << 24)) + 123456789);
    
    for (y = tiley; y < endy; y++) {
        for (x = tilex; x < endx; x++) {
            
            for (v = 0; v < nsubsamples; v++) {
                for (u = 0; u < nsubsamples; u++) {
                    float px = (x + (u / (float)nsubsamples) - (w / 2.0)) / (w / 2.0);
                    float py = -(y + (v / (float)nsubsamples) - (h / 2.0)) / (h / 2.0);

                    Ray ray;

                    ray.org.x = 0.0;
                    ray.org.y = 0.0;
                    ray.org.z = 0.0;

                    ray.dir.x = px;
                    ray.dir.y = py;
                    ray.dir.z = -1.0;
                    vnormalize(&(ray.dir));

                    Isect isect;
                    isect.t   = 1.0e+17;
                    isect.hit = 0;

                    ray_sphere_intersect(&isect, &ray, &spheres[0]);
                    ray_sphere_intersect(&isect, &ray, &spheres[1]);
                    ray_sphere_intersect(&isect, &ray, &spheres[2]);
                    ray_plane_intersect (&isect, &ray, &plane);

                    if (isect.hit) {
                        vec col;
                        ambient_occlusion(&col, &isect, &rnd);

                        fimg[3 * (y * w + x) + 0] += col.x;
                        fimg[3 * (y * w + x) + 1] += col.y;
                        fimg[3 * (y * w + x) + 2] += col.z;
                    }

                }
            }

            fimg[3 * (y * w + x) + 0] /= (float)(nsubsamples * nsubsamples);
            fimg[3 * (y * w + x) + 1] /= (float)(nsubsamples * nsubsamples);
            fimg[3 * (y * w + x) + 2] /= (float)(nsubsamples * nsubsamples);

            img[comps * (y * w + x) + 0] = clamp(fimg[3 *(y * w + x) + 0]);
            img[comps * (y * w + x) + 1] = clamp(fimg[3 *(y * w + x) + 1]);
            img[comps * (y * w + x) + 2] = clamp(fimg[3 *(y * w + x) + 2]);
        }
    }
}

static void
render(unsigned char *img, int comps, int w, int h, int nsubsamples, int tilew, int tileh)
{

    float *fimg = (float *)malloc(sizeof(float) * w * h * 3);
    memset((void *)fimg, 0, sizeof(float) * w * h * 3);
    
    dispatch_queue_t dque = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //dispatch_queue_t dque = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_t dgroup = dispatch_group_create();
    
    int i, j;
    for (j = 0; j < h; j += tileh) {
        for (i = 0; i < w; i += tilew) {

            void (^renderblock)(void) = ^{
                render_tile(img, comps, fimg, w, h, nsubsamples, i, j, tilew, tileh);
            };
            //renderblock();
            dispatch_group_async(dgroup, dque, renderblock);
        }
    }
    
    dispatch_group_wait(dgroup, DISPATCH_TIME_FOREVER);
    // dispatch_release(dgroup);
}

static void
init_scene()
{
    spheres[0].center.x = -2.0;
    spheres[0].center.y =  0.0;
    spheres[0].center.z = -3.5;
    spheres[0].radius = 0.5;
    
    spheres[1].center.x = -0.5;
    spheres[1].center.y =  0.0;
    spheres[1].center.z = -3.0;
    spheres[1].radius = 0.5;
    
    spheres[2].center.x =  1.0;
    spheres[2].center.y =  0.0;
    spheres[2].center.z = -2.2;
    spheres[2].radius = 0.5;

    plane.p.x = 0.0;
    plane.p.y = -0.5;
    plane.p.z = 0.0;

    plane.n.x = 0.0;
    plane.n.y = 1.0;
    plane.n.z = 0.0;

}

/*
static void
saveppm(const char *fname, int w, int h, unsigned char *img)
{
    FILE *fp;

    fp = fopen(fname, "wb");
    assert(fp);

    fprintf(fp, "P6¥n");
    fprintf(fp, "%d %d¥n", w, h);
    fprintf(fp, "255¥n");
    fwrite(img, w * h * 3, 1, fp);
    fclose(fp);
}

int
main(int argc, char **argv)
{
    unsigned char *img = (unsigned char *)malloc(WIDTH * HEIGHT * 3);

    double starttime = gettimeofday_sec();

    init_scene();

    render(img, WIDTH, HEIGHT, NSUBSAMPLES, TILE_W, TILE_H);

    printf("done: %lf[sec]\n", gettimeofday_sec() - starttime);

#ifdef SAVE_AS_BMP
    saveBMP("ao_f.bmp", WIDTH, HEIGHT, img);
    printf("ao_f.bmp saved\n");
#else
    saveppm("ao_f.ppm", WIDTH, HEIGHT, img);
    printf("ao_f.ppm saved\n");
#endif

    return 0;
}
*/