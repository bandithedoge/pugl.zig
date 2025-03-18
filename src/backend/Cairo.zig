//! Cairo graphics support.

const pugl = @import("../pugl.zig");
const c = @import("../c.zig");

const Cairo = @This();

backend: *const c.PuglBackend,

pub fn new() Cairo {
    return .{
        .backend = c.puglCairoBackend().?,
    };
}
