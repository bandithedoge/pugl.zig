const pugl = @import("pugl");
const gl = @import("gl");

pub fn reshape(size: pugl.View.Area) void {
    gl.enable(gl.CULL_FACE);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CW);

    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LESS);

    gl.matrixMode(gl.PROJECTION);
    gl.loadIdentity();
    gl.viewport(0, 0, @intCast(size.width), @intCast(size.height));

    const fov = 1.8;
    const aspect = size.width / size.height;
    const h = @tan(fov);
    const w = h / @as(f32, @floatFromInt(aspect));
    const z_near = 1.0;
    const z_far = 100.0;
    const depth = z_near - z_far;
    const q = (z_far + z_near) / depth;
    const qn = 2 * z_far * z_near / depth;
    const projection = [_]f32{
        w, 0, 0,  0,
        0, h, 0,  0,
        0, 0, q,  -1,
        0, 0, qn, 0,
    };
    gl.loadMatrixf(&projection);
}

pub fn display(view: *const pugl.View, distance: f32, angle_x: f32, angle_y: f32, entered: bool) void {
    gl.matrixMode(gl.MODELVIEW);
    gl.loadIdentity();
    gl.translatef(0, 0, -distance);
    gl.rotatef(angle_x, 0, 1, 0);
    gl.rotatef(angle_y, 1, 0, 0);

    if (entered)
        gl.clearColor(0.13, 0.14, 0.14, 1)
    else
        gl.clearColor(0, 0, 0, 1);

    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    if (view.hasFocus()) {
        gl.enableClientState(gl.VERTEX_ARRAY);

        gl.enableClientState(gl.COLOR_ARRAY);

        gl.vertexPointer(3, gl.FLOAT, 0, &strip_vertices);
        gl.colorPointer(3, gl.FLOAT, 0, &strip_color_vertices);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 14);

        gl.disableClientState(gl.COLOR_ARRAY);
        gl.disableClientState(gl.VERTEX_ARRAY);

        gl.color3f(0, 0, 0);
    } else {
        gl.enableClientState(gl.VERTEX_ARRAY);
        gl.enableClientState(gl.COLOR_ARRAY);

        gl.vertexPointer(3, gl.FLOAT, 0, &front_line_loop);
        gl.colorPointer(3, gl.FLOAT, 0, &front_line_loop_colors);
        gl.drawArrays(gl.LINE_LOOP, 0, 4);

        gl.vertexPointer(3, gl.FLOAT, 0, &back_line_loop);
        gl.colorPointer(3, gl.FLOAT, 0, &back_line_loop_colors);
        gl.drawArrays(gl.LINE_LOOP, 0, 4);

        gl.vertexPointer(3, gl.FLOAT, 0, &side_lines);
        gl.colorPointer(3, gl.FLOAT, 0, &side_line_colors);
        gl.drawArrays(gl.LINES, 0, 8);

        gl.disableClientState(gl.VERTEX_ARRAY);
    }
}

const strip_vertices = [_]f32{
    -1, 1, 1, // Front top left
    1, 1, 1, // Front top right
    -1, -1, 1, // Front bottom left
    1, -1, 1, // Front bottom right
    1, -1, -1, // Back bottom right
    1, 1, 1, // Front top right
    1, 1, -1, // Back top right
    -1, 1, 1, // Front top left
    -1, 1, -1, // Back top left
    -1, -1, 1, // Front bottom left
    -1, -1, -1, // Back bottom left
    1, -1, -1, // Back bottom right
    -1, 1, -1, // Back top left
    1, 1, -1, // Back top right
};

const strip_color_vertices = [_]f32{
    0.25, 0.75, 0.75, // Front top left
    0.75, 0.75, 0.75, // Front top right
    0.25, 0.25, 0.75, // Front bottom left
    0.75, 0.25, 0.75, // Front bottom right
    0.75, 0.25, 0.25, // Back bottom right
    0.75, 0.75, 0.75, // Front top right
    0.75, 0.75, 0.25, // Back top right
    0.25, 0.75, 0.75, // Front top left
    0.25, 0.75, 0.25, // Back top left
    0.25, 0.25, 0.75, // Front bottom left
    0.25, 0.25, 0.25, // Back bottom left
    0.75, 0.25, 0.25, // Back bottom right
    0.25, 0.75, 0.25, // Back top left
    0.75, 0.75, 0.25, // Back top right
};

const front_line_loop = [_]f32{
    -1, 1, 1, // Front top left
    1, 1, 1, // Front top right
    1, -1, 1, // Front bottom right
    -1, -1, 1, // Front bottom left
};

const front_line_loop_colors = [_]f32{
    0.25, 0.75, 0.75, // Front top left
    0.75, 0.75, 0.75, // Front top right
    0.75, 0.25, 0.75, // Front bottom right
    0.25, 0.25, 0.75, // Front bottom left
};

const back_line_loop = [_]f32{
    -1, 1, -1, // Back top left
    1, 1, -1, // Back top right
    1, -1, -1, // Back bottom right
    -1, -1, -1, // Back bottom left
};

const back_line_loop_colors = [_]f32{
    0.25, 0.75, 0.25, // Back top left
    0.75, 0.75, 0.25, // Back top right
    0.75, 0.25, 0.25, // Back bottom right
    0.25, 0.25, 0.25, // Back bottom left
};

const side_lines = [_]f32{
    -1, 1, 1, // Front top left
    -1, 1, -1, // Back top left
    -1, -1, 1, // Front bottom left
    -1, -1, -1, // Back bottom left
    1, 1, 1, // Front top right
    1, 1, -1, // Back top right
    1, -1, 1, // Front bottom right
    1, -1, -1, // Back bottom right
};

const side_line_colors = [_]f32{
    0.25, 0.75, 0.75, // Front top left
    0.25, 0.75, 0.25, // Back top left
    0.25, 0.25, 0.75, // Front bottom left
    0.25, 0.25, 0.25, // Back bottom left
    0.75, 0.75, 0.75, // Front top right
    0.75, 0.75, 0.25, // Back top right
    0.75, 0.25, 0.75, // Front bottom right
    0.75, 0.25, 0.25, // Back bottom right
};
