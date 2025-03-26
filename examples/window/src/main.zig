const std = @import("std");

const gl = @import("gl");
const pugl = @import("pugl");
const OpenGlBackend = @import("backend_opengl");

const Options = @import("Options.zig");
const cube = @import("cube.zig");

var procs: gl.ProcTable = undefined;

const Cube = struct {
    view: pugl.View,
    last_draw_time: f64 = 0,
    x_angle: f32 = 0,
    y_angle: f32 = 0,
    last_mouse_x: f32 = 0,
    last_mouse_y: f32 = 0,
    dist: f32 = 10,
    entered: bool = false,

    pub fn cast(ptr: *anyopaque) *Cube {
        return @ptrCast(@alignCast(ptr));
    }
};

const padding = 64;

const App = struct {
    options: Options,
    should_close: bool = false,

    pub fn new() !App {
        return .{ .options = try Options.parse() };
    }

    pub fn cast(ptr: *anyopaque) *App {
        return @ptrCast(@alignCast(ptr));
    }
};

fn getProcAddress(name: [*:0]const u8) ?*const anyopaque {
    return OpenGlBackend.getProcAddress(std.mem.span(name));
}

pub fn main() !void {
    var app = try App.new();

    var world = try pugl.World.new(.program, .{});
    defer world.free();

    try world.setHint(.class_name, "PuglWindowDemo");
    world.setHandle(&app);

    var cubes: [2]Cube = undefined;
    defer for (&cubes) |*c| c.view.free();

    for (&cubes, 0..) |*c, i| {
        c.* = Cube{ .view = try pugl.View.new(&world) };

        // make sure to keep this in sync with zigglgen options in build.zig
        try c.view.setIntHint(.context_version_major, 3);
        try c.view.setIntHint(.context_version_minor, 3);
        try c.view.setContextApi(.opengl);
        try c.view.setContextProfile(.compatibility);

        try c.view.setStringHint(.window_title, "Pugl Window Demo");

        const pos: i16 = @intCast(padding + i * (padding + 128));
        try c.view.setPositionHint(.default, .{ .x = pos, .y = pos });

        try c.view.setSizeHint(.default, .{ .width = 512, .height = 512 });
        try c.view.setSizeHint(.minimum, .{ .width = 128, .height = 128 });
        try c.view.setSizeHint(.maximum, .{ .width = 2048, .height = 2048 });

        const backend = OpenGlBackend.new(&c.view);
        try c.view.setBackend(backend.backend);

        if (!procs.init(getProcAddress))
            return error.BackendFailed;

        try c.view.setBoolHint(.context_debug, app.options.error_checking);
        try c.view.setBoolHint(.resizable, app.options.resizable);
        if (app.options.anti_aliasing)
            try c.view.setIntHint(.samples, 4);
        try c.view.setBoolHint(.double_buffer, app.options.double_buffer);
        if (app.options.vsync)
            try c.view.setIntHint(.swap_interval, 1);
        try c.view.setBoolHint(.ignore_key_repeat, app.options.ignore_key_repeat);

        c.view.setHandle(@ptrCast(c));
        try c.view.setEventFunc(onEvent);

        if (i == 1)
            try cubes[1].view.setTransientParent(cubes[0].view.getNativeView());

        try c.view.realize();

        try c.view.show(.raise);
    }

    const stdout = std.io.getStdOut().writer();

    var last_report_time = world.getTime();
    var frames_drawn: u64 = 0;

    while (!app.should_close) {
        try world.update(if (app.options.continuous) 0 else -1);

        if (app.options.continuous) {
            frames_drawn += 1;
            const this_time = world.getTime();
            if (this_time > last_report_time + 5) {
                const elapsed = this_time - last_report_time;
                const fps = @as(f32, @floatFromInt(frames_drawn)) / elapsed;
                try stdout.print("FPS: {d:.2} ({} frames / {d:.2} seconds)\n", .{ fps, frames_drawn, elapsed });
                last_report_time = this_time;
                frames_drawn = 0;
            }
        }
    }
}

fn onEvent(view: *const pugl.View, event: pugl.event.Event) pugl.Error!void {
    const c = Cube.cast(view.getHandle().?);
    const world = view.getWorld();
    const app = App.cast(world.getHandle().?);

    switch (event) {
        .configure => |e| {
            gl.makeProcTableCurrent(&procs);
            defer gl.makeProcTableCurrent(null);
            cube.reshape(.{ .width = e.width, .height = e.height });
        },
        .update => if (app.options.continuous) try view.obscure(),
        .expose => {
            const this_time = world.getTime();
            if (app.options.continuous) {
                const d_time: f32 = @floatCast(this_time - c.last_draw_time);
                c.x_angle = @mod(c.x_angle + (d_time * 100), 360);
                c.y_angle = @mod(c.y_angle + (d_time * 100), 360);
            }

            gl.makeProcTableCurrent(&procs);
            defer gl.makeProcTableCurrent(null);

            cube.display(view, c.dist, c.x_angle, c.y_angle, c.entered);

            c.last_draw_time = this_time;
        },
        .close => app.should_close = true,
        .key_press => |e| {
            if (e.key == 'q' or e.key == pugl.Keycode.escape.int())
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
        },
        .motion => |e| {
            const x: f32 = @floatCast(e.x);
            const y: f32 = @floatCast(e.y);
            c.x_angle -= x - c.last_mouse_x;
            c.y_angle += y - c.last_mouse_y;
            c.last_mouse_x = x;
            c.last_mouse_y = y;
            if (!app.options.continuous) try view.obscure();
        },
        .scroll => |e| {
            c.dist = @max(10, c.dist + @as(f32, @floatCast(e.dy)));
            if (!app.options.continuous) try view.obscure();
        },
        .pointer_in => {
            c.entered = true;
            if (!app.options.continuous) try view.obscure();
        },
        .pointer_out => {
            c.entered = false;
            if (!app.options.continuous) try view.obscure();
        },
        .focus_in, .focus_out => if (!app.options.continuous) try view.obscure(),
        else => {},
    }
}
