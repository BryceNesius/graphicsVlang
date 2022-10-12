module gfx

import math

pub struct Color {
pub mut:
    r f64 = 0.0
    g f64 = 0.0
    b f64 = 0.0
}

pub struct Color4 {
pub mut:
    r f64 = 0.0
    g f64 = 0.0
    b f64 = 0.0
    a f64 = 0.0
}


///////////////////////////////////////////////////////////
// constructors and constants

pub fn color_from_u8(vals []u8) Color {
    return Color{
        f64(vals[0]) / 255.0,
        f64(vals[1]) / 255.0,
        f64(vals[2]) / 255.0,
    }
}
pub fn color_from_f64(vals []f64) Color {
    return Color{ vals[0], vals[1], vals[2] }
}
// hue in [0, 360), saturation in [0, 1], lightness in [0, 1]
pub fn color_from_hsl(hue f64, saturation f64, lightness f64) Color {
    c := (1.0 - math.abs(2.0 * lightness - 1.0)) * saturation
    x := c * (1.0 - math.abs(math.fmod(hue / 60.0, 2) - 1.0))
    m := lightness - c / 2.0
    mut r := 0.0
    mut g := 0.0
    mut b := 0.0

         if hue <  60 { r, g, b = c, x, 0 }
    else if hue < 120 { r, g, b = x, c, 0 }
    else if hue < 180 { r, g, b = 0, c, x }
    else if hue < 240 { r, g, b = 0, x, c }
    else if hue < 300 { r, g, b = x, 0, c }
    else              { r, g, b = c, 0, x }
    return Color{ r:r+m, g:g+m, b:b+m }
}

pub fn color4_from_u8(vals []u8) Color4 {
    return Color4{
        f64(vals[0]) / 255.0,
        f64(vals[1]) / 255.0,
        f64(vals[2]) / 255.0,
        if vals.len == 4 { f64(vals[3]) / 255.0 } else { 1.0 },
    }
}
pub fn color4_from_f64(vals []f64) Color4 {
    return Color4{
        vals[0],
        vals[1],
        vals[2],
        if vals.len == 4 { vals[3] } else { 1.0 },
    }
}

pub const (
    black   = Color{ r:0, g:0, b:0 }
    white   = Color{ r:1, g:1, b:1 }
    red     = Color{ r:1, g:0, b:0 }
    yellow  = Color{ r:1, g:1, b:0 }
    green   = Color{ r:0, g:1, b:0 }
    cyan    = Color{ r:0, g:1, b:1 }
    blue    = Color{ r:0, g:0, b:1 }
    magenta = Color{ r:1, g:0, b:1 }

    black4   = Color4{ r:0, g:0, b:0, a:1 }
    white4   = Color4{ r:1, g:1, b:1, a:1 }
    red4     = Color4{ r:1, g:0, b:0, a:1 }
    yellow4  = Color4{ r:1, g:1, b:0, a:1 }
    green4   = Color4{ r:0, g:1, b:0, a:1 }
    cyan4    = Color4{ r:0, g:1, b:1, a:1 }
    blue4    = Color4{ r:0, g:0, b:1, a:1 }
    magenta4 = Color4{ r:1, g:0, b:1, a:1 }
    transparent4 = Color4{ r:0, g:0, b:0, a:0 }
)


///////////////////////////////////////////////////////////
// printing methods

pub fn (c Color) str() string {
    return 'Color{ $c.r, $c.g, $c.b }'
}

pub fn (c Color4) str() string {
    return 'Color4{ $c.r, $c.g, $c.b, $c.a }'
}


///////////////////////////////////////////////////////////
// conversion methods

// convert each channel to u8 (with scaling and clamping)

pub fn (c Color) r_u8(max f64) u8 {
    return u8(255.999 * math.clamp(c.r / max, 0.0, 1.0))
}
pub fn (c Color) g_u8(max f64) u8 {
    return u8(255.999 * math.clamp(c.g / max, 0.0, 1.0))
}
pub fn (c Color) b_u8(max f64) u8 {
    return u8(255.999 * math.clamp(c.b / max, 0.0, 1.0))
}
pub fn (c Color) rgb_u8(max f64) []u8 {
    return [ c.r_u8(max), c.g_u8(max), c.b_u8(max) ]
}

pub fn (c Color4) r_u8(max f64) u8 {
    return u8(255.999 * math.clamp(c.r / max, 0.0, 1.0))
}
pub fn (c Color4) g_u8(max f64) u8 {
    return u8(255.999 * math.clamp(c.g / max, 0.0, 1.0))
}
pub fn (c Color4) b_u8(max f64) u8 {
    return u8(255.999 * math.clamp(c.b / max, 0.0, 1.0))
}
pub fn (c Color4) a_u8() u8 {
    return u8(255.999 * math.clamp(c.a, 0.0, 1.0))
}
pub fn (c Color4) rgb_u8(max f64) []u8 {
    return [ c.r_u8(max), c.g_u8(max), c.b_u8(max) ]
}
pub fn (c Color4) rgba_u8(max f64) []u8 {
    return [ c.r_u8(max), c.g_u8(max), c.b_u8(max), c.a_u8() ]
}

pub fn (c Color) as_color4() Color4 {
    return Color4{ c.r, c.g, c.b, 1.0 }
}
pub fn (c Color4) as_color() Color {
    return Color{ c.r, c.g, c.b }
}

pub fn (c Color) hue() f64 {
    max := max3(c.r, c.g, c.b)
    min := min3(c.r, c.g, c.b)
    delta := max - min
    if delta == 0 { return 0 }
    if max == c.r { return 60 * math.fmod((c.g - c.b) / delta, 6) }
    if max == c.g { return 60 * ((c.b - c.r) / delta + 2) }
                    return 60 * ((c.r - c.g) / delta + 4)
}
pub fn (c Color) saturation() f64 {
    max := max3(c.r, c.g, c.b)
    min := min3(c.r, c.g, c.b)
    delta := max - min
    if delta == 0 { return 0 }
    return delta / (1.0 - math.abs(2.0 * c.lightness() - 1.0))
}
pub fn (c Color) lightness() f64 {
    return 0.5 * (max3(c.r, c.g, c.b) + min3(c.r, c.g, c.b))
}
pub fn (c Color) hsl() (f64, f64, f64) {
    return c.hue(), c.saturation(), c.lightness()
}

// note: ignores alpha
pub fn (c Color4) hue() f64 {
    max := max3(c.r, c.g, c.b)
    min := min3(c.r, c.g, c.b)
    delta := max - min
    if delta == 0 { return 0 }
    if max == c.r { return 60 * math.fmod((c.g - c.b) / delta, 6) }
    if max == c.g { return 60 * ((c.b - c.r) / delta + 2) }
                    return 60 * ((c.r - c.g) / delta + 4)
}
// note: ignores alpha
pub fn (c Color4) saturation() f64 {
    max := max3(c.r, c.g, c.b)
    min := min3(c.r, c.g, c.b)
    delta := max - min
    if delta == 0 { return 0 }
    return delta / (1.0 - math.abs(2.0 * c.lightness() - 1.0))
}
// note: ignores alpha
pub fn (c Color4) lightness() f64 {
    return 0.5 * (max3(c.r, c.g, c.b) + min3(c.r, c.g, c.b))
}

pub fn (c Color4) hsl() (f64, f64, f64) {
    return c.hue(), c.saturation(), c.lightness()
}
pub fn (c Color4) hsla() (f64, f64, f64, f64) {
    return c.hue(), c.saturation(), c.lightness(), c.a
}


///////////////////////////////////////////////////////////
// arithmetic methods

pub fn (c Color) scale(s f64) Color {
    return Color{ c.r * s, c.g * s, c.b * s }
}
pub fn (mut c Color) scale_in(s f64) Color {
    c.r *= s
    c.g *= s
    c.b *= s
    return c
}

pub fn (a Color) add(b Color) Color {
    return Color{ a.r + b.r, a.g + b.g, a.b + b.b }
}
pub fn (mut a Color) add_in(b Color) Color {
    a.r += b.r
    a.g += b.g
    a.b += b.b
    return a
}
pub fn (a Color) + (b Color) Color {
    return Color{ a.r + b.r, a.g + b.g, a.b + b.b }
}

pub fn (a Color) mult(b Color) Color {
    return Color{ a.r * b.r, a.g * b.g, a.b * b.b }
}
pub fn (mut a Color) mult_in(b Color) Color {
    a.r *= b.r
    a.g *= b.g
    a.b *= b.b
    return a
}
pub fn (a Color) * (b Color) Color {
    return Color{ a.r * b.r, a.g * b.g, a.b * b.b }
}

pub fn (a Color) lerp(b Color, f f64) Color {
    return Color{
        a.r * (1.0 - f) + b.r * f,
        a.g * (1.0 - f) + b.g * f,
        a.b * (1.0 - f) + b.b * f,
    }
}
pub fn (a Color4) lerp(b Color4, f f64) Color4 {
    return Color4{
        a.r * (1.0 - f) + b.r * f,
        a.g * (1.0 - f) + b.g * f,
        a.b * (1.0 - f) + b.b * f,
        a.a * (1.0 - f) + b.a * f,
    }
}

pub fn (a Color) average(b Color) Color {
    return Color{
        (a.r + b.r) / 2,
        (a.g + b.g) / 2,
        (a.b + b.b) / 2,
    }
}
pub fn (a Color4) average(b Color4) Color4 {
    return Color4{
        (a.r + b.r) / 2,
        (a.g + b.g) / 2,
        (a.b + b.b) / 2,
        (a.a + b.a) / 2,
    }
}


///////////////////////////////////////////////////////////
// testing methods

pub fn (c Color) is_black() bool {
    return c.r <= 10e-5 && c.g <= 10e-5 && c.b <= 10e-5
}
pub fn (c Color4) is_black() bool {
    return c.r <= 10e-5 && c.g <= 10e-5 && c.b <= 10e-5
}

pub fn (c Color4) is_transparent() bool {
    return c.a <= 10e-5
}
pub fn (c Color4) is_opaque() bool {
    return c.a >= 1.0 - 10e-5
}





