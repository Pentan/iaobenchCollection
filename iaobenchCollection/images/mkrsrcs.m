//
// image resource generator
//
// cc -Wall -O3 -fobjc-arc -o mkrsrcs mkrsrcs.m -framework Foundation -framework AppKit
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#if  __has_feature(objc_arc) == 0 // no ARC
    #define NOARC_AUTORELEASE(o) [o autorelease]
#else
    #define NOARC_AUTORELEASE(o) o
#endif

///// aobench materials
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include <Block.h>
#include <dispatch/dispatch.h>

// xorshift random
typedef struct XorShift128_ {
    unsigned int x, y, z, w;
} XorShift128;

static unsigned int xorshift128NextU32(XorShift128 *r) {
    unsigned int t = r->x ^ (r->x << 11);
    r->x = r->y;
    r->y = r->z;
    r->z = r->w;
    r->w = (r->w ^ (r->w >> 19)) ^ (t ^ (t >> 8));
    return r->w;
}

static double xorshift128NextDouble(XorShift128 *r) {
    return  xorshift128NextU32(r) / 4294967296.0; // 0xffffffff == 4294967295
}

static void xorshift128Init(XorShift128 *r, unsigned int seed) {
    r->x = 123456789;
    r->y = 362436069;
    r->z = 521288629;
    r->w = seed;
    
    int i;
    for(i = 0; i < 1000; i++) {
        xorshift128NextU32(r);
    }
}
//

#define WIDTH        256
#define HEIGHT       256
#define NSUBSAMPLES  2
#define NAO_SAMPLES  8

#define TILE_W       64
#define TILE_H       64

typedef struct _vec
{
    double x;
    double y;
    double z;
} vec;


typedef struct _Isect
{
    double t;
    vec    p;
    vec    n;
    int    hit; 
} Isect;

typedef struct _Sphere
{
    vec    center;
    double radius;

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

static int ao_samples = NAO_SAMPLES;
static double ao_dirvec_z = -1.0;
static vec ao_origin = {0.0, 0.0, 0.0};

static double vdot(vec v0, vec v1)
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
    double length = sqrt(vdot((*c), (*c)));

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

    double B = vdot(rs, ray->dir);
    double C = vdot(rs, rs) - sphere->radius * sphere->radius;
    double D = B * B - C;

    if (D > 0.0) {
        double t = -B - sqrt(D);
        
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
    double d = -vdot(plane->p, plane->n);
    double v = vdot(ray->dir, plane->n);

    if (fabs(v) < 1.0e-17) return;

    double t = -(vdot(ray->org, plane->n) + d) / v;

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
    int    ntheta = ao_samples;
    int    nphi   = ao_samples;
    double eps = 0.0001;

    vec p;

    p.x = isect->p.x + eps * isect->n.x;
    p.y = isect->p.y + eps * isect->n.y;
    p.z = isect->p.z + eps * isect->n.z;

    vec basis[3];
    orthoBasis(basis, isect->n);

    double occlusion = 0.0;

    for (j = 0; j < ntheta; j++) {
        for (i = 0; i < nphi; i++) {
            double theta = sqrt(xorshift128NextDouble(rnd));
            double phi   = 2.0 * M_PI * xorshift128NextDouble(rnd);

            double x = cos(phi) * theta;
            double y = sin(phi) * theta;
            double z = sqrt(1.0 - theta * theta);

            // local -> global
            double rx = x * basis[0].x + y * basis[1].x + z * basis[2].x;
            double ry = x * basis[0].y + y * basis[1].y + z * basis[2].y;
            double rz = x * basis[0].z + y * basis[1].z + z * basis[2].z;

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

    occlusion = (ntheta * nphi - occlusion) / (double)(ntheta * nphi);

    col->x = occlusion;
    col->y = occlusion;
    col->z = occlusion;
}

static unsigned char
clamp(double f)
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
render_tile(unsigned char *img, double *fimg, int w, int h, int nsubsamples, int tilex, int tiley, int tilew, int tileh)
{
    int endx = tilex + min_i(tilew, w - tilex);
    int endy = tiley + min_i(tileh, h - tiley);
    
    int x, y;
    int u, v;
    
    XorShift128 rnd;
    xorshift128Init(&rnd, (tilex | (endx << 8) | (tiley << 16) | (endy << 24)) + 123456789);
    
    double xscale = (double)w / h;
    double yscale = (double)h / w;
    
    if(xscale < yscale) {
        xscale = 1.0;
    } else {
        yscale = 1.0;
    }
    
    for (y = tiley; y < endy; y++) {
        for (x = tilex; x < endx; x++) {
            
            for (v = 0; v < nsubsamples; v++) {
                for (u = 0; u < nsubsamples; u++) {
                    double px = ((x + (u / (double)nsubsamples) - (w / 2.0)) / (w / 2.0)) * xscale;
                    double py = (-(y + (v / (double)nsubsamples) - (h / 2.0)) / (h / 2.0)) * yscale;
                    
                    Ray ray;

                    ray.org.x = ao_origin.x;
                    ray.org.y = ao_origin.y;
                    ray.org.z = ao_origin.z;

                    ray.dir.x = px;
                    ray.dir.y = py;
                    ray.dir.z = ao_dirvec_z;
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

            fimg[3 * (y * w + x) + 0] /= (double)(nsubsamples * nsubsamples);
            fimg[3 * (y * w + x) + 1] /= (double)(nsubsamples * nsubsamples);
            fimg[3 * (y * w + x) + 2] /= (double)(nsubsamples * nsubsamples);

            img[3 * (y * w + x) + 0] = clamp(fimg[3 *(y * w + x) + 0]);
            img[3 * (y * w + x) + 1] = clamp(fimg[3 *(y * w + x) + 1]);
            img[3 * (y * w + x) + 2] = clamp(fimg[3 *(y * w + x) + 2]);
        }
    }
    //printf("block done:%d,%d\n", tilex, tiley);
}

static void
render(unsigned char *img, int w, int h, int nsubsamples, int tilew, int tileh)
{
    double *fimg = (double *)malloc(sizeof(double) * w * h * 3);
    memset((void *)fimg, 0, sizeof(double) * w * h * 3);
    
    dispatch_queue_t dque = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t dgroup = dispatch_group_create();
    
    int i, j;
    for (j = 0; j < h; j += tileh) {
        for (i = 0; i < w; i += tilew) {
            void (^renderblock)(void) = ^{
                render_tile(img, fimg, w, h, nsubsamples, i, j, tilew, tileh);
            };
            dispatch_group_async(dgroup, dque, renderblock);
        }
    }
    
    dispatch_group_wait(dgroup, DISPATCH_TIME_FOREVER);

#if  __has_feature(objc_arc) == 0 // no ARC
    dispatch_release(dgroup);
#endif
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

/////
static void savePNG(char *fname, int w, int h, unsigned char *img) {

#if  __has_feature(objc_arc) == 0 // no ARC
    NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
#endif
    
    unsigned char *planes[] = {img};
    NSBitmapImageRep *imagerep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
                                                                         pixelsWide:w
                                                                         pixelsHigh:h
                                                                      bitsPerSample:8
                                                                    samplesPerPixel:3
                                                                           hasAlpha:NO
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                        bytesPerRow:w * 3
                                                                       bitsPerPixel:24];
    
    if(imagerep) {
        NSData *pngdata = [imagerep representationUsingType:NSPNGFileType properties:nil];
        if(![pngdata writeToFile:[NSString stringWithCString:fname encoding:NSUTF8StringEncoding] atomically:YES]) {
            fprintf(stderr, "data write error to %s\n", fname);
        }
    } else {
        fprintf(stderr, "imagerep create error\n");
    }
    
#if  __has_feature(objc_arc) == 0 // no ARC
    [imagerep release];
    [ap release];
#endif
}

///// Quartz materials
#define DUMMY_W 256
#define DUMMY_H 256

static NSRect makeSSRect(float x, float y, float w, float h) {
    x = x * DUMMY_W * 0.5;
    y = y * DUMMY_H * 0.5;
    w = w * DUMMY_W * 0.5;
    h = h * DUMMY_H * 0.5;
    return CGRectMake(x, y, w, h);
}

static void drawSphere(float x, float y, float z, float r) {
    float pz = (z < 0.0)? -z : z;
    float px = x / pz;
    float py = y / pz;
    float pr = r / pz;
    
    // gradient
    NSColor *c1 = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.3];
    NSColor *c2 = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    NSGradient *shgrad = NOARC_AUTORELEASE( [[NSGradient alloc] initWithStartingColor:c1 endingColor:c2] );
    
    // shadow
    float shadowSize = 2.0;
    float shy = y - r;
    float topz = z + r * shadowSize;
    float btmz = z - r * shadowSize;
    
    float sh = shy / topz - shy / btmz;
    //printf("shy:%f, topz:%f, btmz:%f, sh:%f", shy, topz, btmz, sh);
    NSRect rect = makeSSRect(px - pr * shadowSize, py - pr - sh / 2, pr * shadowSize * 2, sh);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
    [path setLineWidth:1.0];
    
    [NSGraphicsContext saveGraphicsState];
    
    NSAffineTransform *trns = [NSAffineTransform transform];
    [trns translateXBy:NSMidX(rect) yBy:NSMidY(rect)];
    [trns scaleXBy:NSWidth(rect) yBy:NSHeight(rect)];
    [trns concat];
    //printf("mid(%f,%f), size(%f, %f)", NSMidX(rect), NSMidY(rect), NSWidth(rect), NSHeight(rect));
    
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-0.5, -0.5, 1.0, 1.0)] setClip];
    NSPoint p = NSMakePoint(0.0, 0.0);
    [shgrad drawFromCenter:p radius:0.0 toCenter:p radius:0.5 options:NSGradientDrawsBeforeStartingLocation | NSGradientDrawsAfterEndingLocation];
    
    [NSGraphicsContext restoreGraphicsState];
    
    [[NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.2 alpha:1.0] set];
    [path setLineWidth:1.0];
    //path.stroke()
    
    // sphere
    c1 = [NSColor colorWithDeviceRed:0.75 green:0.75 blue:0.75 alpha:1.0];
    c2 = [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    NSGradient *grad = NOARC_AUTORELEASE( [[NSGradient alloc] initWithStartingColor:c1 endingColor:c2] );
    
    rect = makeSSRect(px - pr, py - pr, pr * 2, pr * 2);
    path = [NSBezierPath bezierPathWithOvalInRect:rect];
    [path setLineWidth:1.0];
    /*
    [[NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0] set];
    path.fill()
    */
    [grad drawInBezierPath:path angle:90.0];
    [[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1.0] set];
    [path stroke];
}

void makeDummyImage(char *filename) {
#if  __has_feature(objc_arc) == 0 // no ARC
    NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
#endif
    
    NSImage *img = NOARC_AUTORELEASE( [[NSImage alloc] initWithSize:NSMakeSize(DUMMY_W, DUMMY_H)] );
    
    [img lockFocus];
    
    // plane color
    [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0] set];
    NSRectFill(NSMakeRect(0, 0, DUMMY_W, DUMMY_H / 2));
    
    // sky color
    [[NSColor colorWithDeviceRed:0.65 green:0.65 blue:0.65 alpha:1.0] set];
    NSRectFill(NSMakeRect(0, DUMMY_H / 2, DUMMY_W, DUMMY_H / 2));
    
    // line
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, DUMMY_H / 2 + 0.5)];
    [path lineToPoint:NSMakePoint(DUMMY_W, DUMMY_H / 2 + 0.5)];
    [path setLineWidth:1.0];
    [[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1.0] set];
    [path stroke];
    
    // spheres
    NSAffineTransform *trns = [NSAffineTransform transform];
    [trns translateXBy:DUMMY_W / 2 yBy:DUMMY_H / 2];
    [trns set];
    
    drawSphere(-2.0, 0.0, 3.5, 0.5);
    drawSphere(-0.5, 0.0, 3.0, 0.5);
    drawSphere(1.0, 0.0, 2.2, 0.5);
    
    [img unlockFocus];
    
    NSBitmapImageRep *bmprep = NOARC_AUTORELEASE( [[NSBitmapImageRep alloc] initWithData:[img TIFFRepresentation]] );
    NSData *pngdat = [bmprep representationUsingType:NSPNGFileType properties:nil];
    [pngdat writeToFile:[NSString stringWithCString:filename encoding:NSUTF8StringEncoding] atomically:YES];
    
#if  __has_feature(objc_arc) == 0 // no ARC
    [ap release];
#endif
}

///// main
#define MAX_SIZE 2048

int
main(int argc, char **argv)
{
    static char savename[256];
    unsigned char *img = (unsigned char *)malloc(MAX_SIZE * MAX_SIZE * 3);
    int w, h;

    init_scene();

    /*
    // icon settings test
    ao_origin.x = -0.3;
    ao_origin.z =  0.4;
    
    ao_dirvec_z = -2.0;
    
    spheres[0].center.x = -1.5;
    spheres[0].center.z = -3.5;
    
    spheres[2].center.x =  0.3;
    spheres[2].center.z = -2.2;
    //
    */
    /* // ao test
    ao_samples = 8;
    printf("rendering basic ao\n");
    render(img, WIDTH, HEIGHT, 2, TILE_W, TILE_H);
    savePNG("ao.png", WIDTH, HEIGHT, img);
    printf("ao.png saved\n");
    */
    
    // main
    int ss = 4;
    ao_samples = 10;
    
    // --- default images ---
    // iPhone
    printf("rendering default image\n");
    strcpy(savename, "Default.png");
    w = 320, h = 480;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    printf("rendering default image @2x\n");
    strcpy(savename, "Default@2x.png");
    w = 320 * 2, h = 480 * 2;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);

    printf("rendering default image 568h@2x\n");
    strcpy(savename, "Default-568h@2x.png");
    w = 320 * 2, h = 568 * 2;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    // iPad
    printf("rendering iPad portrait default image\n");
    strcpy(savename, "Default-Portrait~ipad.png");
    w = 768, h = 1024;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    printf("rendering iPad landscape default image\n");
    strcpy(savename, "Default-Landscape~ipad.png");
    w = 1024, h = 768;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    printf("rendering iPad portrait default image @2x\n");
    strcpy(savename, "Default-Portrait@2x~ipad.png");
    w = 768 * 2, h = 1024 * 2;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    printf("rendering iPad landscape default image @2x\n");
    strcpy(savename, "Default-Landscape@2x~ipad.png");
    w = 1024 * 2, h = 768 * 2;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    //--- icons ---
    ao_origin.x = -0.3;
    ao_origin.z =  0.4;
    
    ao_dirvec_z = -2.0;
    
    spheres[0].center.x = -1.5;
    spheres[0].center.z = -3.5;
    
    spheres[2].center.x =  0.3;
    spheres[2].center.z = -2.2;
    
    ao_samples = 16;
    
    //iPhone
    printf("rendering icon image\n");
    strcpy(savename, "Icon.png");
    w = 57, h = 57;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    printf("rendering icon image@2x\n");
    strcpy(savename, "Icon@2x.png");
    w = 57 * 2, h = 57 * 2;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    // iPad
    printf("rendering iPad icon image\n");
    strcpy(savename, "Icon-72.png");
    w = 72, h = 72;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    printf("rendering iPad icon image@2x\n");
    strcpy(savename, "Icon-72@2x.png");
    w = 72 * 2, h = 72 * 2;
    render(img, w, h, ss, TILE_W, TILE_H);
    savePNG(savename, w, h, img);
    printf("%s saved\n", savename);
    
    //--- dummy ---
    printf("make aodummy.png\n");
    makeDummyImage("aodummy.png");
    
    
    free(img);
    
    return 0;
}
