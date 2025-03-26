//! Cairo graphics support.

const pugl = @import("pugl");
const pugl_c = @import("c");

const c = @cImport(@cInclude("pugl/cairo.h"));

const Cairo = @This();

backend: *const pugl_c.PuglBackend,

pub fn new() Cairo {
    return .{
        .backend = @ptrCast(c.puglCairoBackend().?),
    };
}
