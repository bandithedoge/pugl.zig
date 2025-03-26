//! Stub graphics backend accessor.
//!
//! This backend just creates a simple native window without setting up any portable graphics API.

const pugl = @import("../pugl.zig");
const pugl_c = @import("c");
const c = @cImport(@cInclude("pugl/stub.h"));

const errFromStatus = @import("../utils.zig").errFromStatus;

const Stub = @This();

backend: *const pugl_c.PuglBackend,

pub fn new() Stub {
    return .{
        .backend = @ptrCast(c.puglStubBackend().?),
    };
}
