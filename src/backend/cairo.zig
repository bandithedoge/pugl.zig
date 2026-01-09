//! Cairo graphics support.

const pugl_c = @import("c");

const c = @cImport(@cInclude("pugl/cairo.h"));

const Cairo = @This();

backend: *const pugl_c.PuglBackend,

pub fn init() Cairo {
    return .{
        .backend = @ptrCast(c.puglCairoBackend().?),
    };
}
