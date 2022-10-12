import gfx

import os
import math


// convenience type aliases
type Image         = gfx.Image
type Image4        = gfx.Image4
type Point2        = gfx.Point2
type Point2i       = gfx.Point2i
type Vector2i      = gfx.Vector2i
type Vector2       = gfx.Vector2
type Size2i        = gfx.Size2i
type LineSegment2i = gfx.LineSegment2i
type Color         = gfx.Color
type Color4        = gfx.Color4



//////////////////////////////////////////////////////////////////////////////////////////////////
/*
fn draw_imac(filename string) Point2i {
    points := []Point2i{}

    image := load_image(filename)
    for row in image {
        raster_line_segment(Point2i{image.x, image.y}, Point2i{image.row, image.y})
    }
    return
}
*/

fn generate_gif_images(start Point2, length f64, direction f64, length_factor f64, spread f64, spread_factor f64, count int) []LineSegment2i {
    mut line_segments := []LineSegment2i{}
    mut vector := Vector2{ (math.cos(direction) * length),  (math.sin(direction) * length)}
    mut end := start.add(vector)
    line_segments << LineSegment2i{start.as_point2i(), end.as_point2i()}
    if count > 0 {
        line_segments << generate_fractal_tree(end, length * length_factor, direction + spread, length_factor, spread * spread_factor, spread_factor, count-1)
        line_segments << generate_fractal_tree(end, length * length_factor, direction - spread, length_factor, spread * spread_factor, spread_factor, count-1)
    }
    return line_segments
}

// Generating functions that return shapes as list of points

// Generate corner points of a simple, fixed, closed polygon (rotated square)
fn generate_fixed_polygon(center Point2i, radius int) []Point2i {
    mut points := []Point2i{}

    cx, cy := center.x, center.y
    cr := int(0.5403023059 * f64(radius))
    sr := int(0.8414709848 * f64(radius))
    points << Point2i{ cx + cr, cy + sr }
    points << Point2i{ cx - sr, cy + cr }
    points << Point2i{ cx - cr, cy - sr }
    points << Point2i{ cx + sr, cy - cr }

    return points
}

// Generate corner points of a closed regular polygon with given number of sides
fn generate_regular_polygon(center Point2i, radius int, sides int) []Point2i {
    mut points := []Point2i{}
    
    angle := (2 * math.pi) / f64(sides)
    mut current_angle := 0.0
    cx, cy := center.x, center.y
    cr := int(0.5403023059 * f64(radius))
    sr := int(0.8414709848 * f64(radius))
    

for side in 0..sides {
    x := int((math.cos(current_angle) * radius) + cx)
    y := int((math.sin(current_angle) * radius) + cy)
    points << Point2i{x, y}
    current_angle += angle
}
    /*
        for each side
            compute corner point for side (tip: use math.cos, math.sin, math.pi)
            append point to points
    */

    return points
}


// Generate fractal tree as list of line segments
//     parameter        description
//    --------------- -------------------------------------------------------
//     start:          position of where the current branch starts
//     length:         length of current branch
//     direction:      direction of branch (specified in radians)
//     length_factor:  factor of shortening for each child branch
//                     ex: 0.5 --> child branches are half as long
//     spread:         how much each child branch should deviate from direction (specified in radians)
//     spread_factor:  factor of spreading for each child branch
//     count:          how many branch generations (recursion depth) to generate
fn generate_creative_artifact(start Point2, length f64, direction f64, length_factor f64, spread f64, spread_factor f64, count int) []LineSegment2i {
    mut line_segments := []LineSegment2i{}
    mut vector := Vector2{ (math.cos(direction) * length),  (math.sin(direction) * length)}
    mut end := start.add(vector)
    line_segments << LineSegment2i{start.as_point2i(), end.as_point2i()}
    if count > 0 {
        line_segments << generate_fractal_tree(end, length * length_factor, direction + spread, length_factor, spread * spread_factor, spread_factor, count-1)
        line_segments << generate_fractal_tree(end, length * length_factor, direction - spread, length_factor, spread * spread_factor, spread_factor, count-1)
    }
    return line_segments
}
fn generate_fractal_tree(start Point2, length f64, direction f64, length_factor f64, spread f64, spread_factor f64, count int) []LineSegment2i {
    mut line_segments := []LineSegment2i{}
    mut vector := Vector2{ (math.cos(direction) * length),  (math.sin(direction) * length)}
    mut end := start.add(vector)
    line_segments << LineSegment2i{start.as_point2i(), end.as_point2i()}
    if count > 0 {
        line_segments << generate_fractal_tree(end, length * length_factor, direction + spread, length_factor, spread * spread_factor, spread_factor, count-1)
        line_segments << generate_fractal_tree(end, length * length_factor, direction - spread, length_factor, spread * spread_factor, spread_factor, count-1)
    }


    /*
        compute endpoint by:
            vector = (cos(direction) * length, sin(direction) * length)
            end = start + vector
        append line segment with start and end to line_segments list
        if count greater than zero (meaning, create children branches)
            append what is returned from 2x recursive calls to generate_fractal_tree, where:
                - start parameter is end computed above                (use end for both children)
                - length parameter is length*length_factor             (use for both children)
                - direction parameter has spread added and subtracted  (1 each)
                - length_factor is passed unchanged to children
                - spread for child is spread*spread_factor             (use for both children)
                - spread_factor is passed unchanged to children
                - count parameter is decreased by 1                    (use for both chilrden)

        Note: You can append the contents of one list onto another list using the << operator
        Note: The type of start is Point2, but LineSegment2i uses Point2i.
              Use Point2's as_point2i "method" to convert a Point2 to Point2i.
    */

    return line_segments
}



//////////////////////////////////////////////////////////////////////////////////////////////////
// Rasterizing functions that convert shapes into list of points that can be rendered


// Rasterize a horizontal (same y) line segment into list of points
// Note: the endpoints,  p0 and p1, will be in the list (inclusive)
// Note: p0 and p1 can be on either side (left or right) or same location
fn raster_horizontal_line_segment(p0 Point2i, p1 Point2i) []Point2i {
    assert p0.y == p1.y

    mut points := []Point2i{}

    x_min, x_max := math.min(p0.x, p1.x), math.max(p0.x, p1.x)
    y := p0.y
    for x in x_min .. x_max {
        points << Point2i{ x, y }
    }
    points << Point2i{ x_max, y }

    return points
}

// Rasterize a vertical (same x) line segment into list of points
// Note: the endpoints,  p0 and p1, will be in the list (inclusive)
// Note: p0 and p1 can be on either side (top or bottom) or same location
fn raster_vertical_line_segment(p0 Point2i, p1 Point2i) []Point2i {
    assert p0.x == p1.x

    mut points := []Point2i{}

    x := p0.x
    y_min, y_max := math.min(p0.y, p1.y), math.max(p0.y, p1.y)
    for y in y_min .. y_max {
        points << Point2i{ x, y }
    }
    points << Point2i{ x, y_max }

    return points
}

// Rasterize a rectangle into list of points
fn raster_rectangle(top_left Point2i, bottom_right Point2i) []Point2i {
    mut points := []Point2i{}

    top_right    := Point2i{ bottom_right.x, top_left.y }
    bottom_left  := Point2i{ top_left.x, bottom_right.y }

    // rasterize each of the four edges of rectangle
    for p in raster_horizontal_line_segment(top_left, top_right)       { points << p }  // top
    for p in raster_horizontal_line_segment(bottom_left, bottom_right) { points << p }  // bottom
    for p in raster_vertical_line_segment(top_left, bottom_left)       { points << p }  // left
    for p in raster_vertical_line_segment(top_right, bottom_right)     { points << p }  // right

    return points
}

// Rasterize a line segment into a list of points using Bresenham's Line Algorithm
// https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm#Algorithm
// Suggestion: implement the integer arithmetic algorithm
fn raster_line_segment(p0 Point2i, p1 Point2i) []Point2i {
    mut points := []Point2i{}

    mut x0 := p0.x
    mut y0 := p0.y 
    mut x1 := p1.x
    mut y1 := p1.y 

    if math.abs(y1 - y0) < math.abs(x1 - x0) {
        if x0 > x1 {
            return plotlinelow(x1, y1, x0, y0)
        }
        else {
            return plotlinelow(x0, y0, x1, y1)
        }
    }
    else {
        if y0 > y1 {
            return plotlinehigh(x1, y1, x0, y0)
        }
        else {
            return plotlinehigh(x0, y0, x1, y1)
        }
    } 
    /*
        Implement Bresenham's Line Algorithm
        https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm#Algorithm
        Suggestion: implement the integer arithmetic algorithm

        Note: Pseudocode below is modified version of Wikipedia's listing,
        but it only handles case where x0 <= x1, y0 <= y1, and dy <= dx!
        You will need to generalize it to handle other conditions.

        dx = x1 - x0
        dy = y1 - y0
        D = 2*dy - dx
        y = y0
        foreach x in [x0, x1]
            create and add point(x, y)
            if D > 0
                y = y + 1
                D = D - 2*dx
            D = D + 2*dy
    */

    return points
}

fn plotlinehigh(x0 int, y0 int, x1 int, y1 int) []Point2i{
    mut points := []Point2i{}
    mut dx := x1 - x0
    mut dy := y1 - y0
    mut xi := 1

    if dx < 0 {
        xi = -1
        dx = -dx
    }
    mut d := (2 * dy) - dx
    mut x := x0

    for y in y0..y1 {
        points << Point2i{x, y}
        if d > 0 {
            x = x + xi
            d = d + ((dx - dy) * 2)
        }
        else {
            d = d + (dx * 2)
        }   
    }
    return points
}

fn plotlinelow(x0 int, y0 int, x1 int, y1 int) []Point2i {
    mut points := []Point2i{}
    mut dx := x1 - x0
    mut dy := y1 - y0
    mut yi := 1

    if dy < 0 {
        yi = -1
        dy = -dy
    }
    mut d := (2 * dy) - dx
    mut y := y0

    for x in x0..x1 {
        points << Point2i{x, y}
        if d > 0 {
            y = y + yi
            d = d + ((dy - dx) * 2)
        }
        else {
            d = d + (dy * 2)
        }
    }
    return points
}

// Rasterize the perimeter of a closed polygon (given as list of points) into a list of points
fn raster_polygon_perimeter(vertices []Point2i) []Point2i {
    mut points := []Point2i{}
    vert_length := vertices.len

    for x, pair in vertices {
        //println((x+1)%vert_length)
        for point in raster_line_segment(vertices[x], vertices[(x+1)%vert_length]) {
        //println(point)
        points << point
        }
    }
    /*
        foreach pair of vertices
            foreach point of line segment between point pair
                yield point
    */
    return points
}

// Rasterize the perimeter of a circle into a list of points
fn raster_circle_perimeter(center Point2i, radius int) []Point2i {
    mut points := []Point2i{}

    mut x0 := center.x
    mut y0 := center.y
    mut x := radius - 1
    mut y := 0
    mut dx := 1
    mut dy := 1
    mut err := dx - (2 * radius)

    for x >= y {
        points << Point2i{x0+x, y0+y}     // octant 1
        points << Point2i{x0+y, y0+x}     // octant 2
        points << Point2i{x0-y, y0+x}     // octant 3
        points << Point2i{x0-x, y0+y}     // octant 4
        points << Point2i{x0-x, y0-y}     // octant 5
        points << Point2i{x0-y, y0-x}     // octant 6
        points << Point2i{x0+y, y0-x}     // octant 7
        points << Point2i{x0+x, y0-y} 
        
        if err <= 0 {
            y += 1
            err += dy
            dy += 2
        }
        if err > 0 {
            x -= 1
            dx += 2
            err += (-2 * radius) + dx
        }
    }
    /*
        Implement Midpoint Circle Algorithm found on Wikipedia
        https://en.wikipedia.org/wiki/Midpoint_circle_algorithm

    */

    return points
}

fn raster_line_segments(line_segments []LineSegment2i) []Point2i {
    mut points := []Point2i{}
    for line_segment in line_segments {
        points << raster_line_segment(line_segment.p0, line_segment.p1)
    }
    return points
}



//////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering functions that render a shape as an image

fn render_box(center Point2i, radius int, color Color, size Size2i) Image {
    mut image := Image{ size:size }

    top_left     := Point2i{ center.x - radius, center.y - radius }
    top_right    := Point2i{ center.x + radius, center.y - radius }
    bottom_left  := Point2i{ center.x - radius, center.y + radius }
    bottom_right := Point2i{ center.x + radius, center.y + radius }

    // draw four edges of box
    for p in raster_horizontal_line_segment(top_left, top_right)       { image.set(p, color) }  // top
    for p in raster_horizontal_line_segment(bottom_left, bottom_right) { image.set(p, color) }  // bottom
    for p in raster_vertical_line_segment(top_left, bottom_left)       { image.set(p, color) }  // left
    for p in raster_vertical_line_segment(top_right, bottom_right)     { image.set(p, color) }  // right
    // NOTE: the above four loops call `set` on the four corner pixels twice.
    //       this is only a problem if color is not opaque.

    return image
}

fn render_star(center Point2i, radius int, num_points int, color Color, size Size2i) Image {
    mut image := Image{ size:size }
    image.clear()

    cx, cy := center.x, center.y

    for i in 0 .. num_points {
        radians := math.radians(f64(i) * 360.0 / f64(num_points))
        point := Point2i{ int(math.cos(radians) * radius + cx), int(math.sin(radians) * radius + cy) }
        for p in raster_line_segment(center, point) {
            image.set(p, color)
        }
    }

    return image
}

fn render_points(points []Point2i, color Color, size Size2i) Image {
    mut image := Image{ size:size }
    image.clear()

    for point in points {
        image.set(point, color)
    }

    return image
}



//////////////////////////////////////////////////////////////////////////////////////////////////

fn main() {
    // Make sure images folder exists, because this is where all
    // generated images will be saved
    if !os.exists('output') {
        os.mkdir('output') or { panic(err) }
    }

    size := Size2i{ 512, 512 }
    center := Point2i{ 256, 256 }
    radius := 192

    println('Rendering box...')
    gfx.save_image(
        image:    render_box(center, radius, gfx.white, size),
        filename: 'output/P01_00_box.ppm',
    )

    println('Rendering star...')
    gfx.save_image(
        image:    render_star(center, radius, 36, gfx.white, size),
        filename: 'output/P01_01_star.ppm',
    )

    println('Rendering fixed polygon...')
    shape_fixed_polygon := generate_fixed_polygon(center, radius)
    gfx.save_image(
        image: render_points(
            raster_polygon_perimeter(shape_fixed_polygon),
            gfx.white,
            size,
        ),
        filename: 'output/P01_02_fixed_polygon.ppm',
    )

    println('Rendering regular polygon...')
    shape_regular_polygon := generate_regular_polygon(center, radius, 15)
    gfx.save_image(
        image: render_points(
            raster_polygon_perimeter(shape_regular_polygon),
            gfx.white,
            size,
        ),
        filename: 'output/P01_03_regular_polygon.ppm',
    )

    println('Rendering circle...')
    gfx.save_image(
        image: render_points(
            raster_circle_perimeter(center, radius),
            gfx.white,
            size,
        ),
        filename: 'output/P01_04_circle.ppm',
    )

    println('Rendering fractal tree...')
    shape_fractal_tree := generate_fractal_tree(
        Point2{ 256, 500 },  // start
        100,                 // length
        math.radians(270),   // direction
        0.75,                // length_factor
        math.radians(30),    // spread
        0.85,                // spread_factor
        10                   // count
    )
    gfx.save_image(
        image: render_points(
            raster_line_segments(shape_fractal_tree),
            gfx.white,
            size
        ),
        filename: 'output/P01_05_fractal_tree.ppm',
    )

    println('Rendering creative things...')
    shape_creative := generate_fractal_tree(
        Point2{ 256, 600 },  // start
        50,                 // length
        math.radians(270),   // direction
        1.15,                // length_factor
        math.radians(10),    // spread
        0.85,                // spread_factor
        10                   // count
    )
    gfx.save_image(
        image: render_points(
            raster_line_segments(shape_creative),
            gfx.red,
            size
        ),
        filename: 'output/P01_06_creative_artifact.ppm',
    )

    println('Rendering creative things...')
    shape_series := generate_fractal_tree(
        Point2{ 256, 550 },  // start
        25,                 // length
        math.radians(270),   // direction
        1.15,                // length_factor
        math.radians(37),    // spread
        0.9,                // spread_factor
        10                  // count
    )
    gfx.save_image(
        image: render_points(
            raster_line_segments(shape_series),
            gfx.red,
            size
        ),
        filename: 'output/P01_06_series.ppm',
    )
    println('Done!')
    
}