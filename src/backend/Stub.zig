//! Stub graphics backend accessor.
//!
//! This backend just creates a simple native window without setting up any portable graphics API.

const pugl = @import("../pugl.zig");
const c = @import("../c.zig");

const errFromStatus = @import("../utils.zig").errFromStatus;

const Stub = @This();

backend: *const c.PuglBackend,

pub fn new() Stub {
    return .{
        .backend = c.puglStubBackend().?,
    };
}
