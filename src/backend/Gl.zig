//! OpenGL graphics support.

const pugl = @import("../pugl.zig");
const c = @import("../c.zig");

const errFromStatus = @import("../utils.zig").errFromStatus;

const Gl = @This();

parent_view: *const pugl.View,
backend: *const c.PuglBackend,

pub fn new(view: *const pugl.View) Gl {
    return .{
        .parent_view = view,
        .backend = c.puglGlBackend().?,
    };
}

/// Return the address of an OpenGL extension function.
pub fn getProcAddress(name: [:0]const u8) ?*const fn () callconv(.C) void {
    return c.puglGetProcAddress(name);
}

/// Enter the OpenGL context.
///
/// This can be used to enter the graphics context in unusual situations, for doing things like loading textures.
/// Note that this must not be used for drawing, which may only be done while processing an expose event.
pub fn enterContext(self: *const Gl) pugl.Error!void {
    return errFromStatus(c.puglEnterContext(self.parent_view.view));
}

/// Leave the OpenGL context.
///
/// This must only be called after `.enterContext()`.
pub fn leaveContext(self: *const Gl) pugl.Error!void {
    return errFromStatus(c.puglLeaveContext(self.parent_view.view));
}
