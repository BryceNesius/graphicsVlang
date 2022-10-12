module gfx

import os
import json


pub struct Scene {
pub:
    camera           Camera
    background_color Color       = Color{ 0.2, 0.2, 0.2 }
    ambient_color    Color       = Color{ 0.2, 0.2, 0.2 }
    lights           [] Light    = [ Light{} ]
    surfaces         [] Surface  = [ Surface{} ]
}

pub struct Camera {
pub:
    sensor Sensor
    lookat LookAt
    frame  Frame = Frame{
        o: Point{ 0, 0, 1 },
        x: Direction{ 1, 0, 0 },
        y: Direction{ 0, 1, 0 },
        z: Direction{ 0, 0, 1 },
    }
}

pub struct Sensor {
pub:
    size       Size2  = Size2  { 1.0, 1.0 }
    resolution Size2i = Size2i { 512, 512 }
    distance   f64          = 1.0
    samples    int          = 1
}

pub struct Light {
pub:
    kl     Color = white
    frame  Frame = Frame{ o: Point{ 0, 0, 5 } }
    lookat LookAt
}

pub enum Shape {
    sphere
    quad
}

pub struct Surface {
pub:
    shape    Shape  = Shape.sphere
    radius   f64    = 1.0
    frame    Frame
    material Material
}

pub struct Material {
pub:
    kd Color = white
    ks Color = black
    n  f64   = 10.0
    kr Color = black
}





///////////////////////////////////////////////////////////
// convenience getters

pub fn (light Light) o() Point {
    return light.frame.o
}

pub fn (surface Surface) o() Point {
    return surface.frame.o
}



///////////////////////////////////////////////////////////
// scene importing and exporting functions

pub fn scene_from_file(path string) Scene {
    data := os.read_file(path)         or { panic(err) }
    return scene_from_json(data.str()) or { panic(err) }
}

pub fn scene_from_json(data string) ?Scene {
    scene := json.decode(Scene, data)?
    return scene.update_from_load()
}

pub fn (scene Scene) to_json() string {
    return json.encode(scene)
}

pub fn (scene Scene) update_from_load() Scene {
    mut lights := []Light{}
    for light in scene.lights {
        lights << light.update_from_load()
    }

    return Scene{
        camera:           scene.camera.update_from_load(),
        background_color: scene.background_color,
        ambient_color:    scene.ambient_color,
        lights:           lights,
        surfaces:         scene.surfaces,
    }
}

pub fn (camera Camera) update_from_load() Camera {
    mut frame := camera.frame
    if camera.lookat.is_set() {
        frame = camera.lookat.as_frame()
    }
    return Camera{
        sensor: camera.sensor,
        frame:  frame,
    }
}

pub fn (light Light) update_from_load() Light {
    mut frame := light.frame
    if light.lookat.is_set() {
        frame = light.lookat.as_frame()
    }

    return Light{
        frame: frame,
        kl: light.kl,
    }
}



