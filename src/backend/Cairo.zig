//! Cairo graphics support.

const pugl = @import("../pugl.zig");
const pugl_c = @import("c");
const c = @cImport(@cInclude("pugl/cairo.h"));

const Cairo = @This();

backend: *const pugl_c.PuglBackend,

pub fn new() Cairo {
    return .{
        .backend = @ptrCast(c.puglCairoBackend().?),
    };
}
