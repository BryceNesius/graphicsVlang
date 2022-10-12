import gfx

import os
import math


// convenience type aliases
type Image   = gfx.Image
type Image4  = gfx.Image4
type Point2i = gfx.Point2i
type Size2i  = gfx.Size2i
type Color   = gfx.Color
type Color4  = gfx.Color4
type Point2  = gfx.Point2


// renders a stepped, vertical color gradient
fn render_gradient(top Color, bottom Color, steps int, size Size2i) Image {
    mut image := Image{ size:size }
    image.clear()
    
    
    
    // each new step changes the color to be a 255 / step_height 
    /*
        foreach row in 0 .. size.height
            foreach col in 0 .. size.width
                set pixel color in image such that:
                - top row is `top`
                - bottom row is `bottom`
                - rows between have `steps` evenly spaced colors
    */
    // modulus step height and column. When == 0, change color
    

    step_height := (size.height / steps) 
    for row in 0 .. size.height {
        for step in 0 .. steps {
            mut factor := (f64(step) / f64(steps - 1))
            //           top + factor * (bottom - top)
            mut color := top.add(bottom.sub(top).scale(factor))
            rowtop := step * step_height
            rowbot := (step + 1) * step_height
            for col in rowtop .. rowbot {
                image.set_xy(row, col, color)
                

            }
        }
    }

    return image
}


fn color_over(c_top Color4, c_bottom Color4) Color4 {
    mut c := Color4{ 0, 0, 0, 1 }

    /*
        compute color of c_top OVER c_bottom
        c = (c_top.a * c_top) + ((1 - c_top.a) * c_bottom)
    */
     c.r = (c_top.a * c_top.r) + ((1 - c_top.a) * c_bottom.r)
     c.g = (c_top.a * c_top.g) + ((1 - c_top.a) * c_bottom.g)
     c.b = (c_top.a * c_top.b) + ((1 - c_top.a) * c_bottom.b)

    return c
}

fn color_blend(c0 Color4, c1 Color4, factor f64) Color4 {
    mut c := Color4{ 0, 0, 0, 1 }

    /*
        compute color of blending c0 and c1 by factor.
        for example:
        - when factor == 0.0, final color is c0
        - when factor == 0.5, final color is average of c0 and c1
        - when factor == 1.0, final color is c1
    */
   

    alpha_factor := (factor * c1.a) + ((1 - factor) * c0.a)
    c.r = ((factor * c1.r * c1.a) + ((1 - factor) * (c0.r * c0.a))) / alpha_factor
    c.g = ((factor * c1.g * c1.a) + ((1 - factor) * (c0.g * c0.a))) / alpha_factor
    c.b = ((factor * c1.b * c1.a) + ((1 - factor) * (c0.b * c0.a))) / alpha_factor
    c.a = alpha_factor

    return c
}

fn render_composite(
    img_top Image4,
    img_bot Image4,
    fn_composite fn(c_top Color4, c_bot Color4) Color4
) Image4 {
    assert img_top.size.width == img_bot.size.width
    assert img_top.size.height == img_bot.size.height
    size := img_top.size
    w, h := size.width, size.height
    mut image := Image4{ size:size }
    for y in 0 .. h {
        for x in 0 .. w {
            c_top, c_bot := img_top.get_xy(x, y), img_bot.get_xy(x, y)
            image.set_xy(x, y, fn_composite(c_top, c_bot))
        }
    }
    return image
}


// convenience struct that groups a Point2i with Color
struct PointColor {
    position Point2i
    color    Color
}

// renders an image following a simple algorithm
fn render_algorithm(iterations int, size Size2i) Image {
    mut image := Image{ size:size }
    image.clear()

    // pick three random locations and colors
    min := Point2i{0, 0}
    max := Point2i{size.width, size.height}
    corners := [
        PointColor{ gfx.point2i_rand(min, max), gfx.red },
        PointColor{ gfx.point2i_rand(min, max), gfx.cyan },
        PointColor{ gfx.point2i_rand(min, max), gfx.blue },
        
    ]
    mut position := gfx.point2i_rand(min, max)
    mut color    := gfx.white

    /*
        repeat iterations
            write color into image at position
            choose one of the corners at random
            update position by moving it halfway to corner position
            update color by moving it halfway to corner color
    */
    for x in 0 .. iterations {
        //println(position)
        
        r := gfx.int_in_range(0, 3)
        position = gfx.average_point2(position.as_point2(), Point2{corners[r].position.x, corners[r].position.y}).as_point2i()
        color = color.average(corners[r].color)
        image.set(position, color)
        
    
    }

    return image
}


fn render_creative_algorithm(iterations int, size Size2i) Image {
    mut image := Image{ size:size }
    image.clear()

    // pick three random locations and colors
    min := Point2i{0, 0}
    max := Point2i{size.width, size.height}
    corners := [
        PointColor{ gfx.point2i_rand(min, max), gfx.red },
        PointColor{ gfx.point2i_rand(min, max), gfx.cyan },
        PointColor{ gfx.point2i_rand(min, max), gfx.blue },
        PointColor{ gfx.point2i_rand(min, max), gfx.magenta },
        PointColor{ gfx.point2i_rand(min, max), gfx.cyan },
        PointColor{ gfx.point2i_rand(min, max), gfx.yellow }
    ]
    mut position := gfx.point2i_rand(min, max)
    mut color    := gfx.white

    /*
        repeat iterations
            write color into image at position
            choose one of the corners at random
            update position by moving it halfway to corner position
            update color by moving it halfway to corner color
    */
    for x in 0 .. iterations {
        //println(position)
        
        r := gfx.int_in_range(0, 6)
        position = gfx.average_point2(position.as_point2(), Point2{corners[r].position.x, corners[r].position.y}).as_point2i()
        color = color.average(corners[r].color)
        image.set(position, color)
        
    
    }

    return image
}



fn main() {
    // Make sure images folder exists, because this is where all
    // generated images will be saved
    if !os.exists('output') {
        os.mkdir('output') or { panic(err) }
    }

    size := Size2i{ 512, 512 }
    //size := Size2i{ 1024, 1024 }
    //size := Size2i{ 2048, 2048 }

    println('Generating images A and B...')
    img_a := gfx.generate_image0(size)
    img_b := gfx.generate_image1(size, true)  // set to true for extra credit (varies alpha across image)
    // write images out just to see them
    gfx.save_image(
        image4:        img_a,
        filename:      'output/P00_image_A.ppm',
        filename_mask: 'output/P00_image_A_mask.pgm',
    )
    gfx.save_image(
        image4:        img_b,
        filename:      'output/P00_image_B.ppm',
        filename_mask: 'output/P00_image_B_mask.pgm',  // uncomment for extra credit
    )

    if false {
        println('Testing image loading...')
        test := gfx.load_image('output/P00_image_B.ppm')
        gfx.save_image( image: test, filename: 'output/test.ppm' )

        println('Testing image4 loading...')
        test4 := gfx.load_image4(
            filename:'output/P00_image_A.ppm',
            filename_mask: 'output/P00_image_A_mask.pgm',
        )
        gfx.save_image(
            image4: test4,
            filename: 'output/test4.ppm',
            filename_mask: 'output/test4_mask.pgm'
        )
    }

    println('Rendering gradient images...')
    gfx.save_image(
        image: render_gradient(Color{0,0,0}, Color{1,1,1}, 8, size),
        filename:'output/P00_00_gradient_008.ppm',
    )
    gfx.save_image(
        image:render_gradient(Color{0,0,0}, Color{1,1,1}, 16, size),
        filename:'output/P00_00_gradient_016.ppm',
    )
    gfx.save_image(
        image:render_gradient(Color{0,0,0}, Color{1,1,1}, 256, size),
        filename:'output/P00_00_gradient_256.ppm',
    )

    println('Rendering composite color_over images...')
    gfx.save_image(
        image4:        render_composite(img_a, img_b, color_over),
        filename:      'output/P00_01_A_over_B.ppm',
        // filename_mask: 'output/P00_01_A_over_B_mask.pgm', // uncomment for extra credit
    )
    gfx.save_image(
        image4:        render_composite(img_b, img_a, color_over),
        filename:      'output/P00_01_B_over_A.ppm',
        // filename_mask: 'output/P00_01_B_over_A_mask.pgm', // uncomment for extra credit
    )

    println('Rendering composite color_blend images...')
    gfx.save_image(
        image4: render_composite( img_a, img_b, fn(c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, 0.00)
        }),
        filename:      'output/P00_02_A_blend000_B.ppm',
        filename_mask: 'output/P00_02_A_blend000_B_mask.pgm',
    )
    gfx.save_image(
        image4: render_composite( img_a, img_b, fn(c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, 0.25)
        }),
        filename:      'output/P00_02_A_blend025_B.ppm',
        filename_mask: 'output/P00_02_A_blend025_B_mask.pgm',
    )
    gfx.save_image(
        image4: render_composite( img_a, img_b, fn(c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, 0.50)
        }),
        filename:      'output/P00_02_A_blend050_B.ppm',
        filename_mask: 'output/P00_02_A_blend050_B_mask.pgm',
    )
    gfx.save_image(
        image4: render_composite( img_a, img_b, fn(c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, 0.75)
        }),
        filename:      'output/P00_02_A_blend075_B.ppm',
        filename_mask: 'output/P00_02_A_blend075_B_mask.pgm',
    )
    gfx.save_image(
        image4: render_composite( img_a, img_b, fn(c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, 1.00)
        }),
        filename:      'output/P00_02_A_blend100_B.ppm',
        filename_mask: 'output/P00_02_A_blend100_B_mask.pgm',
    )

    println('Rendering algorithm image...')
    gfx.save_image(
        image:render_algorithm(
            10000000,     // try larger values for iterations
            size,
        ),
        filename:'output/P00_03_algorithm.ppm',
    )

    println('Rendering creative image...')
    gfx.save_image(
        image:render_creative_algorithm(
            10000000,     // try larger values for iterations
            size,
        ),
        filename:'output/P00_03_creative_algorithm.ppm',
    )

    println('Done!')
}