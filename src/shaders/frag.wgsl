const LETTER_THICKNESS: f32 = 0.0155;
const PI: f32 = 3.1415926;

// Current timestep of the simulation.
// Useful for creating animations in the shader.
@group(0) @binding(1) var<uniform> g_time: f32;

// @group(0) @binding(0) var<uniform> object_to_clip: mat4x4<f32>;
struct VertexOut {
    @builtin(position) position_clip: vec4<f32>,
    @location(0) coord: vec2<f32>,
}

@fragment
fn main(
    in: VertexOut,
) -> @location(0) vec4<f32> {
    // Subtle zoom-in at the start
    let sigmoid = (1.0 + exp(-g_time / 10.0));
    var p = in.coord * vec2(sigmoid, sigmoid);

    // Distance to the scene from this pixel.
    let d = sdf_scene(p);

    // Shade the scene.
    // Progressively add more contour lines with a stacked sigmoid threshold.
    // Start at basically no contours so that we don't immediately show the message.
    let contours = 55.0 * my_sigmoid(g_time, 0.5, 20.0) + 1.0 + 35.0 * my_sigmoid(g_time, 0.5, 40.0);
    // Gradually mix between two colors for more variety.
    var col = vec3(0.75) - sign(d) * mix(vec3(0.2, 0.4, 0.0), vec3(0.1, 0.4, 0.7), cos(g_time * 0.025));
	col *= 0.9 - exp(-3.0 * abs(d));
	col *= 0.7 + 0.3 * cos(contours * d);
	col = mix(col, vec3(1.0), 1.0 - smoothstep(0.005, 0.01, abs(d)));

    let color = vec4(col, 1.0);
    return color;
}

// Composite SDF for the whole scene.
fn sdf_scene(p: vec2<f32>) -> f32 {
    const gap: f32 = 0.1;
    const letter_width: f32 = 0.1;
    const letter_height: f32 = 0.4;

    var d: f32;

    // Time-varying bounce factors to make text wiggle.
    let bounce = sin(g_time * 1.1) * 0.02;
    let bounce2 = cos(g_time * 2.0) * 0.025;
    var bounce3 = cos(g_time * 2.7) * 0.015;
    bounce3 *= bounce3;
    let bounce4 = sin(-bounce2);

    // Angular offsets to add more text variety.
    let angle1 = -PI / 45.0;
    let rot1 = mat2x2(
        cos(angle1), sin(angle1),
        -sin(angle1), cos(angle1)
    );
    let angle2 = PI / 65.0;
    let rot2 = mat2x2(
        cos(angle2), sin(angle2),
        -sin(angle2), cos(angle2)
    );
    let angle3 = -PI / 120.0;
    let rot3 = mat2x2(
        cos(angle3), sin(angle3),
        -sin(angle3), cos(angle3)
    );

    // `HAPPY`
    var x = -0.5;
    var y = 0.4;
    d = sdf_char_h(p, vec2(x, y + bounce + letter_height), vec2(x + letter_width, y + bounce));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_a(p, vec2(x, y + -bounce2 * 0.65), vec2(x + letter_width, y + bounce2 * 0.65), letter_height));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_p(p, vec2(x, y + bounce), letter_height));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_p(rot3 * p, rot3 * vec2(x, y + bounce3), letter_height * (sin(g_time * 2.0) * 0.025 + 1.0)));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_y(p, vec2(x, y + bounce + letter_height), vec2(x + letter_width, y + bounce + letter_height), letter_height));

    // `FATHER'S`
    x = -0.75;
    y = -0.25;
    d = sdf_union(d, sdf_char_f(rot1 * p, rot1 * vec2(x, y + bounce), letter_height * (sin(g_time * 2.0) * 0.05 + 1.0), letter_width));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_a(p, vec2(x, y + bounce3), vec2(x + letter_width, y + bounce3), letter_height));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_t(p, vec2(x, y + bounce + letter_height), letter_height, letter_width));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_h(p, vec2(x, y + -bounce4 * 0.25 + letter_height), vec2(x + letter_width, y + bounce4 * 0.25)));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_e(p, vec2(x, y + bounce), letter_height * (cos(g_time * 2.0) * 0.05 + 1.0), letter_width));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_r(p, vec2(x, y + bounce2), letter_height, letter_width));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_apostrophe(p, vec2(x, y + bounce4 * 0.54), letter_height, letter_width));
    x += gap * 0.75;
    d = sdf_union(d, sdf_char_s(p, vec2(x, y + bounce3 * 10.0), letter_height, letter_width));

    // `DAY`
    x = -0.3;
    y = -0.85;
    d = sdf_union(d, sdf_char_d(p, vec2(x, y + bounce3), letter_height, letter_width));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_a(p, vec2(x, y + bounce), vec2(x + letter_width, y + bounce), letter_height));
    x += letter_width + gap;
    d = sdf_union(d, sdf_char_y(rot2 * p, rot2 * vec2(x, y + bounce2 * 0.3 + letter_height), rot2 * vec2(x + letter_width, y + -bounce2 * 0.3 + letter_height), letter_height));

    // Animate: expand and contract the composite SDF.
    // Use a cubic to pause at `0`, which creates a cool effect where the text pops in at the beginning.
    let c = cos(g_time / 10.0 - PI);
    d -= 10.0 / (1.0 + exp(-c*c*c)) - 5.0;

    return d;
}

fn my_sigmoid(x: f32, c0: f32, c1: f32) -> f32 {
    return 1.0 / (1.0 + exp(-c0 * (x - c1)));
}

fn sdf_union(d1: f32, d2: f32) -> f32 {
    return min(d1, d2);
}

//================================================================================
// SDFs for text characters.
//
// Typically parameterized by the bottom-left coordinate and the height/width of
// the bounding box for the character.
//================================================================================
fn sdf_char_d(p: vec2<f32>, bottom_left: vec2<f32>, height: f32, width: f32) -> f32 {
    const th = LETTER_THICKNESS * 0.45;
    const angle = PI / 2.0;
    const rot = mat2x2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle),
    );

    // line
    let top = vec2(bottom_left.x, bottom_left.y + height);
    let d_line = sdf_segment(p, bottom_left, top);

    // arc
    let ra = height / 2.0;
    let t = PI / 2.0;
    let cs = vec2(cos(t), sin(t));
    let p_ = rot * (p - bottom_left - vec2(0.0, 0.2)) * vec2(1.0, 1.75);
    let d_arc = sdf_ring(p_, cs, ra, th);

    return sdf_union(d_line, d_arc);
}

// `S` is pretty hacked. I didn't feel like dealing with bezier curves this time around.
fn sdf_char_s(p: vec2<f32>, bottom_left: vec2<f32>, height: f32, width: f32) -> f32 {
    const ra = 0.1;
    const th = LETTER_THICKNESS * 0.25;
    const angle = PI / 7.0;
    const rot = mat2x2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle),
    );
    const scale = 5.1;
    const offset1 = vec2(-0.35/scale, 0.45/scale);
    const offset2 = vec2(0.02, -0.5/scale + 0.01);

    let t = PI - 1.0;
    let cs = vec2(cos(t), sin(t));
    let p_ = rot * (p - bottom_left - vec2(0.1, 0.18));
    let d_upper = sdf_ring(-(p_ - offset1).yx, cs, ra, th);
    let d_lower = sdf_ring((p_ - offset2).yx, cs, ra, th);

    return sdf_union(d_upper, d_lower);
}

fn sdf_char_apostrophe(p: vec2<f32>, bottom_left: vec2<f32>, height: f32, width: f32) -> f32 {
    let angle = 0.01;
    let mid_x = bottom_left.x - 0.025;
    let top = vec2(mid_x + angle, bottom_left.y + height);

    return sdf_segment(p, top, top - vec2(angle, 0.1));
}

fn sdf_char_r(p: vec2<f32>, bottom_left: vec2<f32>, height: f32, width: f32) -> f32 {
    let mid_left = vec2(bottom_left.x, bottom_left.y + height * 0.5);
    let bottom_right = vec2(bottom_left.x + width, bottom_left.y);

    let d_p = sdf_char_p(p, bottom_left, height);
    let d_bar = sdf_segment(p, mid_left, bottom_right);

    return sdf_union(d_p, d_bar);
}

fn sdf_char_e(p: vec2<f32>, bottom_left: vec2<f32>, height: f32, width: f32) -> f32 {
    let top_left = vec2(bottom_left.x, bottom_left.y + height);
    let top_right = vec2(top_left.x + width, top_left.y);
    let mid_left = vec2(bottom_left.x, bottom_left.y + height * 0.5);
    let mid_right = vec2(mid_left.x + width - LETTER_THICKNESS, mid_left.y);
    let bottom_right = vec2(bottom_left.x + width, bottom_left.y);

    let d_left = sdf_segment(p, top_left, bottom_left);
    let d_top = sdf_segment(p, top_left, top_right);
    let d_mid = sdf_segment(p, mid_left, mid_right);
    let d_bot = sdf_segment(p, bottom_left, bottom_right);

    return sdf_union(d_left, sdf_union(d_top, sdf_union(d_mid, d_bot)));
}

fn sdf_char_t(p: vec2<f32>, top_left: vec2<f32>, height: f32, width: f32) -> f32 {
    let top_right = vec2(top_left.x + width, top_left.y);
    let top_mid = vec2(top_left.x + width * 0.5, top_left.y);
    let bottom_mid = vec2(top_mid.x, top_left.y - height);
    let offset = vec2(LETTER_THICKNESS, 0.0);

    let d_top = sdf_segment(p, top_left - offset, top_right + offset);
    let d_mid = sdf_segment(p, top_mid, bottom_mid);

    return sdf_union(d_top, d_mid);
}

fn sdf_char_f(p: vec2<f32>, bottom_left: vec2<f32>, height: f32, width: f32) -> f32 {
    let top = vec2(bottom_left.x, bottom_left.y + height);
    let right_top = vec2(bottom_left.x + width, top.y);

    let mid_y = (bottom_left.y + top.y) * 0.5 + 0.05;
    let mid = vec2(bottom_left.x, mid_y);
    let right_mid = vec2(bottom_left.x + width - LETTER_THICKNESS, mid_y);

    let d_left = sdf_segment(p, bottom_left, top);
    let d_top = sdf_segment(p, top, right_top);
    let d_mid = sdf_segment(p, mid, right_mid);

    return sdf_union(d_left, sdf_union(d_top, d_mid));
}

fn sdf_char_y(p: vec2<f32>, left: vec2<f32>, right: vec2<f32>, height: f32) -> f32 {
    let mid_x = (left.x + right.x) * 0.5;
    let bottom = vec2(mid_x, left.y - height);
    let mid_y = (left.y + bottom.y) * 0.5;
    let middle = vec2(mid_x, mid_y);

    let d_left = sdf_segment(p, left, middle);
    let d_right = sdf_segment(p, right, middle);
    let d_bottom = sdf_segment(p, bottom, middle);

    return sdf_union(d_left, sdf_union(d_right, d_bottom));
}

fn sdf_char_p(p: vec2<f32>, bottom_left: vec2<f32>, height: f32) -> f32 {
    // left bar
    let top = vec2(bottom_left.x, bottom_left.y + height - 0.019);    
    let d_left = sdf_segment(p, bottom_left, top);

    // arc
    let tb = PI - 1.0;
    let rb = LETTER_THICKNESS * 0.25;
    let sc = vec2(sin(tb),cos(tb));
    let p0 = (p - top - vec2(0.037, -0.081)).yx * vec2(1.0, 1.5);
    let d_arc = sdf_arc(p0, sc, 0.1, rb);

    return sdf_union(d_left, d_arc);
}

fn sdf_char_a(p: vec2<f32>, left: vec2<f32>, right: vec2<f32>, height: f32) -> f32 {
    var result: f32;

    let top = vec2((left.x + right.x) * 0.5, left.y + height);

    // Find halfway points along left and right segments of 'A'.
    let dirl = top - left;
    let mid_left = (left + dirl * 0.5);
    let dirr = top - right;
    let mid_right = (right + dirr * 0.5);

    let d_left   = sdf_segment(p, left, top);
    let d_middle = sdf_segment(p, mid_left, mid_right);
    let d_right  = sdf_segment(p, right, top);
    result = sdf_union(d_left, sdf_union(d_middle, d_right));

    return result;
}

fn sdf_char_h(p: vec2<f32>, top_left: vec2<f32>, bottom_right: vec2<f32>) -> f32 {
    var result: f32;

    let height = top_left.y - bottom_right.y;
    let d_left   = sdf_segment(p, top_left, top_left - vec2(0.0, height));
    let d_middle = sdf_segment(p, top_left - vec2(0.0, height * 0.5), bottom_right + vec2(0.0, height * 0.5));
    let d_right  = sdf_segment(p, vec2(bottom_right.x, top_left.y), bottom_right);
    result = sdf_union(d_left, sdf_union(d_middle, d_right));

    return result;
}

//================================================================================
// SDFs from the man, the myth, the legend: Inigo Quilez
// https://iquilezles.org/articles/distfunctions2d/
//================================================================================
fn sdf_ring(p: vec2<f32>, n: vec2<f32>, r: f32, th: f32) -> f32 {
    var p_ = vec2(abs(p.x), p.y);
    p_ = mat2x2(n.x, n.y, -n.y, n.x) * p_;
    return max(
        abs(length(p_) - r) - th * 0.5,
        length(vec2(p_.x, max(0.0, abs(r - p_.y) - th * 0.5))) * sign(p_.x)
    );
}

fn sdf_arc(p: vec2<f32>, sc: vec2<f32>, ra: f32, rb: f32) -> f32 {
    var d: f32;

    // sc is the sin/cos of the arc's aperture
  	let p_ = vec2(abs(p.x), p.y);
    if (sc.y * p_.x > sc.x * p_.y) {
        d = length(p_ - sc * vec2(ra));
    } else {
        d = abs(length(p_) - ra);
    }
    return d - rb;
}

fn sdf_orientedBox(p: vec2<f32>, start: vec2<f32>, end: vec2<f32>, thickness: f32) -> f32 {
    let l = length(end - start);
    let d = (end - start) / l;
    var q = p - (start + end) * 0.5;
    q = mat2x2(d.x, -d.y, d.y, d.x) * q;
    q = abs(q) - vec2(l, thickness) * 0.5;
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

fn sdf_segment(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
    let pa = p - a;
    let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}
