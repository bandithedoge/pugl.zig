//! Cairo graphics support.

const pugl_c = @import("c");

const c = @import("cairo_c");

const Cairo = @This();

backend: *const pugl_c.PuglBackend,

pub fn init() Cairo {
    return .{
        .backend = @ptrCast(c.puglCairoBackend().?),
    };
}
