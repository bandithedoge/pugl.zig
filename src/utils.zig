const pugl = @import("./pugl.zig");
const c = @import("c");

pub inline fn errFromStatus(status: c.PuglStatus) pugl.Error!void {
    if (status == c.PUGL_SUCCESS) return;

    return switch (status) {
        c.PUGL_FAILURE => pugl.Error.Failure,
        c.PUGL_UNKNOWN_ERROR => pugl.Error.Unknown,
        c.PUGL_BAD_BACKEND => pugl.Error.BadBackend,
        c.PUGL_BAD_CONFIGURATION => pugl.Error.BadConfiguration,
        c.PUGL_BAD_PARAMETER => pugl.Error.BadParameter,
        c.PUGL_BACKEND_FAILED => pugl.Error.BackendFailed,
        c.PUGL_REGISTRATION_FAILED => pugl.Error.RegistrationFailed,
        c.PUGL_REALIZE_FAILED => pugl.Error.RealizeFailed,
        c.PUGL_SET_FORMAT_FAILED => pugl.Error.SetFormatFailed,
        c.PUGL_CREATE_CONTEXT_FAILED => pugl.Error.CreateContextFailed,
        c.PUGL_UNSUPPORTED => pugl.Error.Unsupported,
        c.PUGL_NO_MEMORY => pugl.Error.OutOfMemory,
        else => unreachable,
    };
}

pub inline fn statusFromErr(err: pugl.Error) c.PuglStatus {
    return switch (err) {
        pugl.Error.Failure => c.PUGL_FAILURE,
        pugl.Error.Unknown => c.PUGL_UNKNOWN_ERROR,
        pugl.Error.BadBackend => c.PUGL_BAD_BACKEND,
        pugl.Error.BadConfiguration => c.PUGL_BAD_CONFIGURATION,
        pugl.Error.BadParameter => c.PUGL_BAD_PARAMETER,
        pugl.Error.BackendFailed => c.PUGL_BACKEND_FAILED,
        pugl.Error.RegistrationFailed => c.PUGL_REGISTRATION_FAILED,
        pugl.Error.RealizeFailed => c.PUGL_REALIZE_FAILED,
        pugl.Error.SetFormatFailed => c.PUGL_SET_FORMAT_FAILED,
        pugl.Error.CreateContextFailed => c.PUGL_CREATE_CONTEXT_FAILED,
        pugl.Error.Unsupported => c.PUGL_UNSUPPORTED,
        pugl.Error.OutOfMemory => c.PUGL_NO_MEMORY,
        else => c.PUGL_SUCCESS,
    };
}
