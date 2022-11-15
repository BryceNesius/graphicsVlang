import gfx

import os
import math

////////////////////////////////////////////////////////////////////////////////////////
// module aliasing to make code a little easier to read
// ex: replacing `gfx.Scene` with just `Scene`

type Point     = gfx.Point
type Vector    = gfx.Vector  
type Direction = gfx.Direction
type Normal    = gfx.Normal
type Ray       = gfx.Ray
type Color     = gfx.Color
type Image     = gfx.Image

type Intersection = gfx.Intersection
type Surface      = gfx.Surface
type Scene        = gfx.Scene
type Shape        = gfx.Shape


////////////////////////////////////////////////////////////////////////////////////////
// Comment out lines in array below to prevent re-rendering every scene.
// If you create a new scene file, add it to the list below.
// NOTE: **BEFORE** you submit your solution, uncomment all lines, so
//       your code will render all the scenes!
fn get_scene_filenames() []string {
    return [
    /*
        'P02_00_sphere',
        'P02_01_sphere_ambient',
        'P02_02_sphere_room',
        'P02_03_quad',
        'P02_04_quad_room',
        'P02_05_ball_on_plane',
        'P02_06_balls_on_plane',
        'P02_07_reflections',
        'P02_08_antialiased',
        'P02_10_creativity_wow',
        */
        'P02_11_refraction'
    ]
}
fn intersect_ray_surface(surface Surface, ray Ray) Intersection {
    match surface.shape {
        .sphere { return intersect_ray_sphere(surface, ray) }
        .quad { return intersect_ray_quad(surface, ray) }
    }
}
fn intersect_ray_quad(surface Surface, ray Ray) Intersection {
    ctr := surface.frame.o 
    radius := surface.radius
    c := surface.frame.o
    e := ray.e
    d := ray.d 
    n := surface.frame.z
    t := e.vector_to(c).dot(n) / d.dot(n)
    if t > ray.t_max || t < ray.t_min {
        return gfx.no_intersection
    }
    p := ray.at(t)
    distance := ctr.vector_to(p)
    if math.abs(distance.x) > radius || math.abs(distance.y) > radius || math.abs(distance.z) > radius {
        return gfx.no_intersection
    }

    return Intersection{
        frame: gfx.frame_oz(p, n),
        surface: surface,
        distance: t
    }

}

fn intersect_ray_sphere(surface Surface, ray Ray) Intersection {
     /*
        if surface's shape is a sphere
            if ray does not intersect sphere, return no intersection
            compute ray's t value(s) at intersection(s)
            if ray's t is not a valid (between ray's min and max), return no intersection
            return intersection information
            NOTE: a ray can intersect a sphere in 0, 1, or 2 different points!

        if surface's shape is a quad
            if ray does not intersect plane, return no intersection
            compute ray's t value at intersection with plane
            if ray's t is not a valid (between min and max), return no intersection
            if intersection is outside the quad, return no intersection
            return intersection information
    */
    a := 1.0
    e := ray.e
    ctr := surface.frame.o 
    r := surface.radius
    ec := Vector{ x: e.x - ctr.x, y: e.y - ctr.y, z: e.z - ctr.z }
    b := 2.0 * ray.d.dot(ec)
    c := ec.length_squared() - (r * r)
    d := (b * b) - (4.0 * a * c)
    mut t := (-b - math.sqrt(d)) / 2.0
    p := ray.at(t)
    n := ctr.direction_to(p)

    // if surface is a quad, else it is treated as a sphere

    if t < ray.t_min {
        t = (-b + math.sqrt(d)) / 2.0
    } 
    if t > ray.t_max || t < ray.t_min {
        return gfx.no_intersection
    }

    if d < 0 {
        // ray did not intersect sphere
        return gfx.no_intersection
    }
    

    return Intersection{ 
        distance: t,
        frame: gfx.frame_oz( p, n),
        surface: surface
        }
}

// Determines if given ray intersects any surface in the scene.
// If ray does not intersect anything, null is returned.
// Otherwise, details of first intersection are returned as an `Intersection` struct.
fn intersect_ray_scene(scene Scene, ray Ray) Intersection {
     /*
        for each surface in surfaces
            continue if ray did not hit surface ( ex: inter.miss() )
            continue if new intersection is not closer than previous closest intersection
            set closest intersection to new intersection
    */
    mut closest := gfx.no_intersection  // type is Intersection

    for surface in scene.surfaces {
        intersection := intersect_ray_surface(surface, ray)
        if intersection.miss() {
            continue
            return intersection
        }
            if closest.is_closer(intersection) {
                continue
            }
            closest = intersection
    }
    //println(closest.distance)
    return closest  // return closest intersection
}

// Computes irradiance (as Color) from scene along ray
fn irradiance(scene Scene, ray Ray) Color {
    /*
        get scene intersection
        if not hit, return scene's background intensity
        accumulate color starting with ambient
        foreach light
            compute light response    (L)
            compute light direction   (l)
            compute light visibility  (V)
            compute material response (BRFD*cos) and accumulate
        if material has reflections (lightness of kr > 0)
            create reflection ray
            accumulate reflected light (recursive call) scaled by material reflection
        return accumulated color
    */
    mut accum := gfx.black

    intersection := intersect_ray_scene(scene, ray)
    if intersection.miss() {
        return scene.background_color
    }
    normal := intersection.frame.z
    kd := intersection.surface.material.kd
    kt := intersection.surface.material.kt
    ks := intersection.surface.material.ks
    n := intersection.surface.material.n
    kr := intersection.surface.material.kr
    v_direction := ray.d.negate()
    r := v_direction.reflect(normal)
    reflect_direction := intersection.frame.o.ray_along(r)

    // Refraction terms
    n1 := intersection.surface.material.n1
    n2 := intersection.surface.material.n2
    n_ratio := n1 / n2
    c1 := normal.dot(v_direction)
    c2 := (1- (n_ratio * n_ratio) * (1 - (c1*c1)))
 
    // kd -> the amount of reflected light from the object based on the material
    // kl -> the color and intensity of the light source
    for light in scene.lights {
        light_response := light.kl.scale(1.0 / intersection.frame.o.distance_squared_to(light.frame.o))
        light_direction := intersection.frame.o.direction_to(light.frame.o)
        h := light_direction.as_vector().add(v_direction.as_vector()).direction()
       
        shadow_ray := intersection.frame.o.ray_to(light.frame.o)
        if intersect_ray_scene(scene, shadow_ray).hit() {
            // in shadow
            continue
        }
       
        accum.add_in(
            light_response.mult(
                kd.add(ks.scale(math.pow(math.max(0.0, normal.dot(h)), n)))
                ).scale(math.abs(normal.dot(light_direction)))
        )
    }
    // ambient hack
    accum.add_in(
        scene.ambient_color.mult(kd)
    )
    // reflection
    if !kr.is_black() {
        accum.add_in(
            (irradiance(scene, reflect_direction).mult(kr)))
    }
    // refraction
    if !kt.is_black() {
        println("First")
        if ((n_ratio*n_ratio) * (1 - (c1*c1))) <= 1 {
            println("second")
            t := (v_direction.scale(n_ratio)) + normal.scale(((n_ratio*c1)-math.sqrt(c2)))
            t_dir := intersection.frame.o.ray_along(t.direction())
            accum.add_in(
                (irradiance(scene, t_dir).mult(kt))
            )
        }
    }   
    
        
    return accum
}

// Computes image of scene using basic Whitted raytracer.
fn raytrace(scene Scene) Image {
    /*
        if no anti-aliasing
            foreach image row (scene.camera.sensor.resolution.height)
                foreach pixel in row (scene.camera.senseor.resolution.width)
                    compute ray-camera parameters (u,v) for pixel
                    compute camera ray
                    set pixel to color raytraced with ray (`irradiance`)
        else
            foreach image row
                foreach pixel in row
                    init accumulated color
                    foreach sample in y
                        foreach sample in x
                            compute ray-camera parameters
                            computer camera ray
                            accumulate color raytraced with ray
                    set pixel to average of accum color (scale by number of samples)
        return rendered image
    */
    mut image := gfx.Image{ size:scene.camera.sensor.resolution }
    image.clear()

    h := scene.camera.sensor.resolution.height
    w := scene.camera.sensor.resolution.width
    sample_size := scene.camera.sensor.samples

    // if anti-aliasing is turned on do this
    if sample_size > 1 {
        for row in 0 .. h {
            for col in 0 .. w {
                mut color := Color{0, 0, 0}
                for ii := 0; ii < sample_size; ii++ {
                    for jj := 0; jj < sample_size; jj++ {
                        u := (f64(col) + (f64(ii) + 0.5) / sample_size) / f64(w)
                        v := (f64(row) + (f64(jj) + 0.5) / sample_size) / f64(h)
                        q := scene.camera.frame.o.add(
                    scene.camera.frame.x.scale((u - 0.5) * scene.camera.sensor.size.width)
                    ).add(
                        scene.camera.frame.y.scale(-(v - 0.5) * scene.camera.sensor.size.height)
                    ).sub(
                        scene.camera.frame.z.scale(scene.camera.sensor.distance)
                    )
                        ray := scene.camera.frame.o.ray_through(q)
                        color = color.add(irradiance(scene, ray))
                    }
                }
                
                
                // create a ray that passes from the focal point of the camera to the scene
                
                // then we determine what color to make that pixel with 'irradiance'
                image.set_xy(col, row, color.scale(1.0 / f64(sample_size * sample_size)))
            }
        }

        // if no anti-aliasing do this
    } else {
        for row in 0 .. h {
            for col in 0 .. w {
            u := f64(col + 0.5) / f64(w) 
            v := f64(row + 0.5) / f64(h)
            q := scene.camera.frame.o.add(
                scene.camera.frame.x.scale((u - 0.5) * scene.camera.sensor.size.width)
                ).add(
                    scene.camera.frame.y.scale(-(v - 0.5) * scene.camera.sensor.size.height)
                ).sub(
                    scene.camera.frame.z.scale(scene.camera.sensor.distance)
                )
            // create a ray that passes from the focal point of the camera to the scene
            ray := scene.camera.frame.o.ray_through(q)
            // then we determine what color to make that pixel with 'irradiance'
            image.set_xy(col, row, irradiance(scene, ray))
            }
        }
    }
    return image
}

fn main() {
    // Make sure images folder exists, because this is where all
    // generated images will be saved
    if !os.exists('output') {
        os.mkdir('output') or { panic(err) }
    }

    for filename in get_scene_filenames() {
        println('Rendering $filename' + '...')
        scene_path := 'scenes/' + filename + '.json'
        image_path := 'output/' + filename + '.ppm'
        scene := gfx.scene_from_file(scene_path)
        image := raytrace(scene)
        gfx.save_image(image:image, filename:image_path)
    }

    println('Done!')
}
