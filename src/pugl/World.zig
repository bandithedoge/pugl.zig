const std = @import("std");
const pugl = @import("pugl.zig");
const c = @import("c");

const utils = @import("utils.zig");
const errFromStatus = utils.errFromStatus;

world: *c.PuglWorld,

const World = @This();

/// The type of a World
pub const Type = enum(c_uint) {
    /// Top-level application
    program = c.PUGL_PROGRAM,
    /// Plugin or module within a larger application
    module = c.PUGL_MODULE,
};

/// World flags
pub const Flags = packed struct {
    /// Set up support for threads if necessary.
    ///
    /// X11: Calls `XInitThreads` which is required for some drivers.
    threads: bool = false,
    _: u31 = 0,

    pub fn cast(self: Flags) u32 {
        return @bitCast(self);
    }
};

test Flags {
    try std.testing.expectEqual(@sizeOf(u32), @sizeOf(Flags));
    try std.testing.expectEqual(0, (Flags{}).cast());
    try std.testing.expectEqual(@as(u32, c.PUGL_WORLD_THREADS), (Flags{ .threads = true }).cast());
}

/// Create a new world. Must later be freed with `deinit`
pub fn init(world_type: Type, flags: Flags) error{OutOfMemory}!World {
    return .{ .world = c.puglNewWorld(@intFromEnum(world_type), flags.cast()) orelse return error.OutOfMemory };
}

/// Free a world allocated with `init`
pub fn deinit(self: *const World) void {
    c.puglFreeWorld(self.world);
}

/// Set the user data for the world.
///
/// This is usually a pointer to a struct that contains all the state which must be accessed by several views.
/// The handle is opaque to Pugl and is not interpreted in any way.
pub fn setHandle(self: *const World, handle: *anyopaque) void {
    c.puglSetWorldHandle(self.world, handle);
}

/// Get the user data for the world
pub fn getHandle(self: *const World) ?*anyopaque {
    return c.puglGetWorldHandle(self.world);
}

/// Return a pointer to the native handle of the world.
///
/// X11: Returns a pointer to the `Display`.
///
/// MacOS: Returns a pointer to the `NSApplication`.
///
/// Windows: Returns the `HMODULE` of the calling process.
pub fn getNativeWorld(self: *const World) *anyopaque {
    return c.puglGetNativeWorld(self.world).?;
}

/// Set a string property to configure the world or application.
///
/// The string value only needs to be valid for the duration of this call, it will be copied if necessary.
pub fn setHint(self: *const World, hint: pugl.StringHint, value: [:0]const u8) pugl.Error!void {
    try errFromStatus(c.puglSetWorldString(self.world, @intFromEnum(hint), value));
}

/// Get a world or application string property.
///
/// The returned string should be accessed immediately, or copied.
/// It may become invalid upon any call to any function that manipulates the same view.
pub fn getHint(self: *const World, hint: pugl.StringHint) [:0]const u8 {
    return std.mem.span(c.puglGetWorldString(self.world, @intFromEnum(hint)));
}

/// Return the time in seconds.
///
/// This is a monotonically increasing clock with high resolution.
/// The returned time is only useful to compare against other times returned by this function,
/// its absolute value has no meaning.
pub fn getTime(self: *const World) f64 {
    return c.puglGetTime(self.world);
}

/// Update by processing events from the window system.
///
/// This function is a single iteration of the main loop, and should be called repeatedly to update all views.
///
/// If `timeout` is zero, then this function will not block.
/// Plugins should always use a timeout of zero to avoid blocking the host.
///
/// If a positive `timeout` is given, then events will be processed for that amount of time,
/// starting from when this function was called.
///
/// If a negative `timeout` is given, this function will block indefinitely until an event occurs.
///
/// For continuously animating programs,
/// a timeout that is a reasonable fraction of the ideal frame period should be used,
/// to minimize input latency by ensuring that as many input events are consumed as possible before drawing.
pub fn update(self: *const World, timeout: f64) pugl.Error!void {
    try errFromStatus(c.puglUpdate(self.world, timeout));
}
