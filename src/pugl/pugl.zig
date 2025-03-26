const std = @import("std");
const builtin = @import("builtin");

const c = @import("c");
const options = @import("pugl_options");

pub const event = @import("event.zig");
pub const Keycode = @import("keycode.zig").Keycode;
pub const utils = @import("utils.zig");
pub const View = @import("View.zig");
pub const World = @import("World.zig");

pub const Backend = struct {
    view: *const View,
    backend: *const c.PuglBackend,
};

pub const Error = error{
    _,
    /// Non-fatal failure
    Failure,
    /// Unknown system error
    Unknown,
    /// Invalid or missing backend
    BadBackend,
    /// Invalid view configuration
    BadConfiguration,
    /// Invalid parameter
    BadParameter,
    /// Backend initialization failed
    BackendFailed,
    /// Class registration failed
    RegistrationFailed,
    /// System view realization failed
    RealizeFailed,
    /// Failed to set pixel format
    SetFormatFailed,
    /// Failed to create drawing context
    CreateContextFailed,
    /// Unsupported operation
    Unsupported,
    /// Failed to allocate memory
    OutOfMemory,
};

/// A string property for configuration
pub const StringHint = enum(c_uint) {
    /// The application class name.
    ///
    /// This is a stable identifier for the application, which should be a short camel-case name like "MyApp".
    /// This should be the same for every instance of the application, but different from any other application.
    /// On X11 and Windows, it is used to set the class name of windows (that underlie realized views),
    /// which is used for things like loading configuration, or custom window management rules.
    class_name = c.PUGL_CLASS_NAME,
    /// The title of the window or application.
    ///
    /// This is used by the system to display a title for the application or window,
    /// for example in title bars or window/application switchers.
    /// It is only used to display a label to the user, not as an identifier,
    /// and can change over time to reflect the current state of the application.
    /// For example, it is common for programs to add the name of the current document,
    /// like "myfile.txt - Fancy Editor".
    window_title = c.PUGL_WINDOW_TITLE,
};

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
