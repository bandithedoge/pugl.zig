const std = @import("std");

const gl = @import("gl");
const OpenGlBackend = @import("backend_opengl");
const pugl = @import("pugl");

const cube = @import("cube.zig");
const Options = @import("Options.zig");

const App = struct {
    options: Options,
    should_close: bool = false,

    parent: pugl.View = undefined,
    child: pugl.View = undefined,
    procs: gl.ProcTable = undefined,

    last_draw_time: f64 = 0,
    reversing: bool = false,
    angle_x: f64 = 0,
    angle_y: f64 = 0,
    last_mouse_x: f64 = 0,
    last_mouse_y: f64 = 0,
    distance: f64 = 10,
    mouse_entered: bool = false,

    pub fn init() !App {
        return .{ .options = try Options.parse() };
    }

    pub fn cast(ptr: *anyopaque) *App {
        return @ptrCast(@alignCast(ptr));
    }
};

const border: pugl.View.Point = .{ .x = 64, .y = 64 };

pub fn main() !void {
    var app = try App.init();

    const world = try pugl.World.init(.program, .{});
    defer world.deinit();

    try world.setHint(.class_name, "PuglEmbedDemo");

    if (!app.procs.init(getProcAddress))
        return pugl.Error.BackendFailed;

    app.parent = try pugl.View.init(&world);
    defer app.parent.deinit();

    try app.parent.setSizeHint(.default, .{ .width = 512, .height = 512 });
    try app.parent.setSizeHint(.minimum, .{ .width = 192, .height = 192 });
    try app.parent.setSizeHint(.maximum, .{ .width = 1024, .height = 1024 });
    try app.parent.setSizeHint(.minimum_aspect, .{ .width = 1, .height = 1 });
    try app.parent.setSizeHint(.maximum_aspect, .{ .width = 16, .height = 9 });

    try app.parent.setBoolHint(.context_debug, app.options.error_checking);
    try app.parent.setBoolHint(.resizable, app.options.resizable);
    if (app.options.anti_aliasing)
        try app.parent.setIntHint(.samples, 4);
    try app.parent.setBoolHint(.double_buffer, app.options.double_buffer);
    if (app.options.vsync)
        try app.parent.setIntHint(.swap_interval, 1);
    try app.parent.setBoolHint(.ignore_key_repeat, app.options.ignore_key_repeat);
    app.parent.setHandle(&app);
    try app.parent.setEventFunc(onParentEvent);
    try app.parent.setStringHint(.window_title, "Pugl Prüfung");

    const parent_backend = OpenGlBackend.init(&app.parent);
    try app.parent.setBackend(parent_backend.backend);

    try app.parent.realize();

    app.child = try pugl.View.init(&world);
    defer app.child.deinit();

    try app.child.setParent(app.parent.getNativeView());

    try app.child.setPositionHint(.default, border);
    try app.child.setSizeHint(.default, .{
        .width = 512 - (2 * border.x),
        .height = 512 - (2 * border.y),
    });

    try app.child.setBoolHint(.context_debug, app.options.error_checking);
    if (app.options.anti_aliasing)
        try app.child.setIntHint(.samples, 4);
    try app.child.setBoolHint(.double_buffer, app.options.double_buffer);
    if (app.options.vsync)
        try app.child.setIntHint(.swap_interval, 1);
    try app.child.setBoolHint(.ignore_key_repeat, app.options.ignore_key_repeat);
    app.child.setHandle(&app);
    try app.child.setEventFunc(onChildEvent);

    const child_backend = OpenGlBackend.init(&app.child);
    try app.child.setBackend(child_backend.backend);

    try app.child.realize();

    try app.parent.show(.raise);
    try app.child.show(.raise);

    try app.child.startTimer(1, 3.6);

    var requested_attention = false;
    while (!app.should_close) {
        const this_time = world.getTime();
        try world.update(if (app.options.continuous) 0 else -1);
        if (!requested_attention and this_time > 5.0) {
            var view_style = app.parent.getViewStyle();
            view_style.demanding = true;
            try app.parent.setViewStyle(view_style);
            requested_attention = true;
        }
    }
}

fn onParentEvent(view: *const pugl.View, event: pugl.event.Event) pugl.Error!void {
    const app = App.cast(view.getHandle().?);
    switch (event) {
        .configure => |e| {
            gl.makeProcTableCurrent(&app.procs);
            defer gl.makeProcTableCurrent(null);

            cube.reshape(.{ .width = e.width, .height = e.height });
            try view.setSizeHint(.current, .{
                .width = e.width - (2 * border.x),
                .height = e.height - (2 * border.y),
            });
        },
        .update => if (app.options.continuous) try view.obscure(),
        .expose => {
            gl.makeProcTableCurrent(&app.procs);
            defer gl.makeProcTableCurrent(null);

            if (view.hasFocus()) {
                gl.MatrixMode(gl.MODELVIEW);
                gl.LoadIdentity();
                gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

                gl.EnableClientState(gl.VERTEX_ARRAY);
                defer gl.DisableClientState(gl.VERTEX_ARRAY);
                gl.EnableClientState(gl.COLOR_ARRAY);
                defer gl.DisableClientState(gl.COLOR_ARRAY);

                gl.VertexPointer(3, gl.FLOAT, 0, &background_vertices);
                gl.ColorPointer(3, gl.FLOAT, 0, &background_color_vertices);
                gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4);
            } else {
                gl.ClearColor(0, 0, 0, 1);
                gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            }
        },
        .key_press => |e| try onKeyPress(view, e),
        .close => app.should_close = true,
        else => {},
    }
}

fn onChildEvent(view: *const pugl.View, event: pugl.event.Event) pugl.Error!void {
    const app = App.cast(view.getHandle().?);
    switch (event) {
        .configure => |e| {
            gl.makeProcTableCurrent(&app.procs);
            defer gl.makeProcTableCurrent(null);

            cube.reshape(.{ .width = e.width, .height = e.height });
        },
        .update => if (app.options.continuous) try view.obscure(),
        .expose => {
            const world = view.getWorld();
            const this_time = world.getTime();
            if (app.options.continuous) {
                const d_time = (this_time - app.last_draw_time) * if (app.reversing) @as(f64, -1) else @as(f64, 1);
                app.angle_x = @mod(app.angle_x + (d_time * 100.0), 360.0);
                app.angle_y = @mod(app.angle_y + (d_time * 100.0), 360.0);
            }

            gl.makeProcTableCurrent(&app.procs);
            defer gl.makeProcTableCurrent(null);

            cube.display(
                view,
                @floatCast(app.distance),
                @floatCast(app.angle_x),
                @floatCast(app.angle_y),
                app.mouse_entered,
            );

            app.last_draw_time = this_time;
        },
        .close => app.should_close = true,
        .key_press => |e| try onKeyPress(view, e),
        .motion => |e| {
            app.angle_x -= e.x - app.last_mouse_x;
            app.angle_y -= e.y - app.last_mouse_y;
            app.last_mouse_x = e.x;
            app.last_mouse_y = e.y;
            if (!app.options.continuous) {
                try view.obscure();
                try app.parent.obscure();
            }
        },
        .scroll => |e| {
            app.distance = @max(10.0, app.distance + e.dy);
            if (!app.options.continuous)
                try view.obscure();
        },
        .pointer_in => app.mouse_entered = true,
        .pointer_out => app.mouse_entered = false,
        .timer => app.reversing = !app.reversing,
        else => {},
    }
}

fn onKeyPress(view: *const pugl.View, e: pugl.event.Key) pugl.Error!void {
    const app = App.cast(view.getHandle().?);

    if (e.key == '\t') {
        if (view.hasFocus())
            try app.child.grabFocus()
        else
            try view.grabFocus();

        if (app.options.continuous) {
            try view.obscure();
            try app.child.obscure();
        }
    } else if (e.key == 'q' or e.key == pugl.Keycode.escape.int())
        app.should_close = true
    else if (e.state.shift) {
        var size = view.getSizeHint(.current);
        switch (e.key) {
            pugl.Keycode.up.int() => size.height -= 10,
            pugl.Keycode.down.int() => size.height += 10,
            pugl.Keycode.left.int() => size.width -= 10,
            pugl.Keycode.right.int() => size.width += 10,
            else => {},
        }
        try view.setSizeHint(.current, size);
    } else {
        var pos = view.getPositionHint(.current);
        switch (e.key) {
            pugl.Keycode.up.int() => pos.y -= 10,
            pugl.Keycode.down.int() => pos.y += 10,
            pugl.Keycode.left.int() => pos.x -= 10,
            pugl.Keycode.right.int() => pos.x += 10,
            else => {},
        }
        try view.setPositionHint(.current, pos);
    }
}

fn getProcAddress(name: [*:0]const u8) ?*const anyopaque {
    return OpenGlBackend.getProcAddress(std.mem.span(name));
}

const background_vertices = [_]f32{
    -1, 1, -1, // Top left
    1, 1, -1, // Top right
    -1, -1, -1, // Bottom left
    1, -1, -1, // Bottom right
};

const background_color_vertices = [_]f32{
    0.25, 0.25, 0.25, // Top left
    0.25, 0.5, 0.25, // Top right
    0.25, 0.5, 0.25, // Bottom left
    0.25, 0.75, 0.5, // Bottom right
};
