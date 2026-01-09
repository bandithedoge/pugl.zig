const std = @import("std");

const CairoBackend = @import("backend_cairo");
const pugl = @import("pugl");

const c = @cImport(@cInclude("cairo.h"));

const Options = @import("Options.zig");

const App = struct {
    options: Options,
    should_close: bool = false,
    mouse_down: bool = false,
    entered: bool = false,
    last_drawn_mouse: Point = .{ .x = 0.0, .y = 0.0 },
    current_mouse: Point = .{ .x = 0.0, .y = 0.0 },

    pub fn init() !App {
        return .{ .options = try Options.parse() };
    }

    pub fn cast(ptr: *anyopaque) *App {
        return @ptrCast(@alignCast(ptr));
    }
};

pub fn main() !void {
    var app = try App.init();

    var world = try pugl.World.init(.program, .{});
    defer world.deinit();

    try world.setHint(.window_title, "PuglCairoDemo");

    const view = try pugl.View.init(&world);
    defer view.deinit();

    try view.setStringHint(.window_title, "Pugl Cairo Demo");
    try view.setSizeHint(.default, .{ .width = 512, .height = 512 });
    try view.setSizeHint(.minimum, .{ .width = 256, .height = 256 });
    try view.setSizeHint(.maximum, .{ .width = 2048, .height = 2048 });
    try view.setBoolHint(.resizable, app.options.resizable);
    view.setHandle(@ptrCast(&app));

    const backend = CairoBackend.init();
    try view.setBackend(backend.backend);

    try view.setBoolHint(.ignore_key_repeat, app.options.ignore_key_repeat);
    try view.setEventFunc(onEvent);

    try view.realize();
    try view.show(.raise);

    while (!app.should_close) {
        try world.update(if (app.options.continuous) 1.0 / 60.0 else -1.0);
    }
}

pub const Point = struct { x: f64, y: f64 };
pub const Size = struct { width: f64, height: f64 };

const Button = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    label: [:0]const u8,

    pub fn draw(self: *const Button, cr: *c.cairo_t, app: *const App, time: f64) void {
        c.cairo_save(cr);
        defer c.cairo_restore(cr);

        c.cairo_translate(cr, @floatFromInt(self.x), @floatFromInt(self.y));
        c.cairo_rotate(cr, @sin(time) * std.math.pi);

        // base
        if (app.mouse_down)
            c.cairo_set_source_rgba(cr, 0.4, 0.9, 0.1, 1)
        else
            c.cairo_set_source_rgba(cr, 0.3, 0.5, 0.1, 1);
        roundedBox(
            cr,
            .{ .x = 0, .y = 0 },
            .{ .width = @floatFromInt(self.width), .height = @floatFromInt(self.height) },
        );
        c.cairo_fill_preserve(cr);

        // border
        c.cairo_set_source_rgba(cr, 0.4, 0.9, 0.1, 1);
        c.cairo_set_line_width(cr, 4);
        c.cairo_stroke(cr);

        // label
        c.cairo_set_font_size(cr, 32);
        var extents: c.cairo_text_extents_t = undefined;
        c.cairo_text_extents(cr, self.label.ptr, &extents);
        c.cairo_move_to(
            cr,
            @divTrunc(@as(f64, @floatFromInt(self.width)), 2.0) - @divTrunc(extents.width, 2),
            @divTrunc(@as(f64, @floatFromInt(self.height)), 2.0) + @divTrunc(extents.height, 2),
        );
        c.cairo_set_source_rgba(cr, 0, 0, 0, 1);
        c.cairo_show_text(cr, self.label.ptr);
    }
};

const buttons = [_]Button{
    .{ .x = 128, .y = 128, .width = 64, .height = 64, .label = "1" },
    .{ .x = 384, .y = 128, .width = 64, .height = 64, .label = "2" },
    .{ .x = 128, .y = 384, .width = 64, .height = 64, .label = "3" },
    .{ .x = 384, .y = 384, .width = 64, .height = 64, .label = "4" },
};

fn onEvent(view: *const pugl.View, event: pugl.event.Event) pugl.Error!void {
    const app = App.cast(view.getHandle().?);
    switch (event) {
        .key_press => |e| {
            if (e.key == 'q' or e.key == pugl.Keycode.escape.int())
                app.should_close = true;
        },
        .button_press => {
            app.mouse_down = true;
            try postButtonRedisplay(view);
        },
        .button_release => {
            app.mouse_down = false;
            try postButtonRedisplay(view);
        },
        .motion => |e| {
            const scale = try getScale(view);

            try obscureMouseCursor(view, scale, app.last_drawn_mouse);

            app.current_mouse.x = e.x;
            app.current_mouse.y = e.y;
            try obscureMouseCursor(view, scale, app.current_mouse);

            app.last_drawn_mouse = app.current_mouse;
        },
        .pointer_in => {
            app.entered = true;
            try view.obscure();
        },
        .pointer_out => {
            app.entered = false;
            try view.obscure();
        },
        .update => if (app.options.continuous) try view.obscure(),
        .expose => |e| {
            const cr: *c.cairo_t = @ptrCast(view.getContext().?);

            c.cairo_rectangle(
                cr,
                @floatFromInt(e.x),
                @floatFromInt(e.y),
                @floatFromInt(e.width),
                @floatFromInt(e.height),
            );
            c.cairo_clip_preserve(cr);

            // background
            if (app.entered)
                c.cairo_set_source_rgb(cr, 0.1, 0.1, 0.1)
            else
                c.cairo_set_source_rgb(cr, 0, 0, 0);
            c.cairo_fill(cr);

            const scale = try getScale(view);
            c.cairo_scale(cr, scale.x, scale.y);

            for (buttons) |button|
                button.draw(cr, app, if (app.options.continuous) view.getWorld().getTime() else 0);

            // cursor
            const mouse_x = app.current_mouse.x / scale.x;
            const mouse_y = app.current_mouse.y / scale.y;
            c.cairo_set_line_width(cr, 2);
            c.cairo_set_source_rgb(cr, 1, 1, 1);
            c.cairo_move_to(cr, mouse_x - 8, mouse_y);
            c.cairo_line_to(cr, mouse_x + 8, mouse_y);
            c.cairo_move_to(cr, mouse_x, mouse_y - 8);
            c.cairo_line_to(cr, mouse_x, mouse_y + 8);
            c.cairo_stroke(cr);
        },
        .close => app.should_close = true,
        else => {},
    }
}

fn getScale(view: *const pugl.View) pugl.Error!Point {
    const size = view.getSizeHint(.current);
    return .{
        .x = (@as(f64, @floatFromInt(size.width)) - (512.0 / @as(f64, @floatFromInt(size.width)))) / 512.0,
        .y = (@as(f64, @floatFromInt(size.height)) - (512.0 / @as(f64, @floatFromInt(size.height)))) / 512.0,
    };
}

fn postButtonRedisplay(view: *const pugl.View) pugl.Error!void {
    const scale = try getScale(view);
    for (buttons) |button| {
        const span = std.math.sqrt(@as(u32, @intCast(button.width * button.width)) +
            @as(u32, @intCast(button.height * button.height)));
        try view.obscureRegion(
            .{
                .x = @intFromFloat(@as(f64, @floatFromInt(button.x - span)) * scale.x),
                .y = @intFromFloat(@as(f64, @floatFromInt(button.y - span)) * scale.y),
            },
            .{
                .width = @intFromFloat(@ceil(@as(f64, @floatFromInt(span * 2)) * scale.x)),
                .height = @intFromFloat(@ceil(@as(f64, @floatFromInt(span * 2)) * scale.y)),
            },
        );
    }
}

fn obscureMouseCursor(
    view: *const pugl.View,
    scale: Point,
    mouse: Point,
) pugl.Error!void {
    try view.obscureRegion(
        .{
            .x = @intFromFloat(@floor(mouse.x - (10 * scale.x))),
            .y = @intFromFloat(@floor(mouse.y - (10 * scale.y))),
        },
        .{
            .width = @intFromFloat(@ceil(20 * scale.x)),
            .height = @intFromFloat(@ceil(20 * scale.y)),
        },
    );
}

pub fn roundedBox(cr: *c.cairo_t, pos: Point, size: Size) void {
    const radius = 10;
    c.cairo_new_sub_path(cr);
    c.cairo_arc(
        cr,
        pos.x + size.width - radius,
        pos.y + radius,
        radius,
        std.math.degreesToRadians(-90),
        0,
    );
    c.cairo_arc(
        cr,
        pos.x + size.width - radius,
        pos.y + size.height - radius,
        radius,
        0,
        std.math.degreesToRadians(90),
    );
    c.cairo_arc(
        cr,
        pos.x + radius,
        pos.y + size.height - radius,
        radius,
        std.math.degreesToRadians(90),
        std.math.degreesToRadians(180),
    );
    c.cairo_arc(
        cr,
        pos.x + radius,
        pos.y + radius,
        radius,
        std.math.degreesToRadians(180),
        std.math.degreesToRadians(270),
    );
    c.cairo_close_path(cr);
}
