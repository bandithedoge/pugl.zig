const std = @import("std");

const gl = @import("gl");
const pugl = @import("pugl");

const Options = @import("Options.zig");

var procs: gl.ProcTable = undefined;

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
    return pugl.Backend.Gl.getProcAddress(std.mem.span(name));
}

pub fn main() !void {
    var app = try App.new();

    var world = try pugl.World.new(.program, .{});
    defer world.free();

    try world.setHint(.class_name, "PuglCursorDemo");

    const view: pugl.View = try .new(&world);
    defer view.free();

    try view.setStringHint(.window_title, "Pugl Cursor Demo");
    try view.setSizeHint(.default, .{ .width = 512, .height = 256 });
    try view.setSizeHint(.minimum, .{ .width = 128, .height = 64 });
    try view.setSizeHint(.maximum, .{ .width = 512, .height = 256 });

    const backend = pugl.Backend.Gl.new(&view);
    try view.setBackend(backend.backend);

    if (!procs.init(getProcAddress))
        return error.BackendFailed;

    try view.setBoolHint(.context_debug, app.options.error_checking);
    try view.setBoolHint(.resizable, app.options.resizable);
    if (app.options.anti_aliasing)
        try view.setIntHint(.samples, 4);
    try view.setBoolHint(.double_buffer, app.options.double_buffer);
    if (app.options.vsync)
        try view.setIntHint(.swap_interval, 1);
    try view.setBoolHint(.ignore_key_repeat, app.options.ignore_key_repeat);

    view.setHandle(&app);
    try view.setEventFunc(onEvent);

    try view.realize();
    try view.show(.raise);

    while (!app.should_close)
        try world.update(-1);
}

fn onEvent(view: *const pugl.View, event: pugl.event.Event) pugl.Error!void {
    const app: *App = .cast(view.getHandle().?);

    const n_rows = 2.0;
    const n_cols = 5.0;

    switch (event) {
        .configure => |e| {
            gl.makeProcTableCurrent(&procs);
            defer gl.makeProcTableCurrent(null);

            gl.Enable(gl.DEPTH_TEST);
            gl.DepthFunc(gl.LESS);
            gl.ClearColor(0.2, 0.2, 0.2, 1);

            gl.MatrixMode(gl.PROJECTION);
            gl.LoadIdentity();
            gl.Viewport(0, 0, e.width, e.height);
        },
        .key_press => |e| if (e.key == 'q' or e.key == pugl.Keycode.escape.int()) {
            app.should_close = true;
        },
        .motion => |e| {
            const size = view.getSizeHint(.current);

            const row = blk: {
                const r: u32 = @intFromFloat(e.y * n_rows / @as(f32, @floatFromInt(size.height)));
                break :blk if (r < 0) 0 else if (r >= n_rows) @as(u32, @intFromFloat(n_rows)) - 1 else r;
            };
            const col = blk: {
                const c: u32 = @intFromFloat(e.x * n_cols / @as(f32, @floatFromInt(size.width)));
                break :blk if (c < 0) 0 else if (c >= n_cols) @as(u32, @intFromFloat(n_cols)) - 1 else c;
            };
            const cursor: u32 = @mod(row * @as(u32, n_cols) + col, @as(u32, @intCast(std.meta.fields(pugl.View.Cursor).len)));

            try view.setCursor(@enumFromInt(cursor));
        },
        .expose => {
            gl.makeProcTableCurrent(&procs);
            defer gl.makeProcTableCurrent(null);

            gl.MatrixMode(gl.MODELVIEW);
            gl.LoadIdentity();
            gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            gl.Color3f(0.6, 0.6, 0.6);

            for (1..n_rows) |i| {
                const y = (@as(f32, @floatFromInt(i)) * (2.0 / n_rows)) - 1.0;
                gl.Begin(gl.LINES);
                defer gl.End();
                gl.Vertex2f(-1, y);
                gl.Vertex2f(1, y);
            }

            for (1..n_cols) |i| {
                const x = (@as(f32, @floatFromInt(i)) * (2.0 / n_cols)) - 1.0;
                gl.Begin(gl.LINES);
                defer gl.End();
                gl.Vertex2f(x, -1);
                gl.Vertex2f(x, 1);
            }
        },
        .pointer_out => try view.setCursor(.arrow),
        .close => app.should_close = true,
        else => {},
    }
}
