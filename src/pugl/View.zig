const std = @import("std");
const pugl = @import("pugl.zig");
const c = @import("c");
const event = @import("event.zig");

const utils = @import("utils.zig");
const errFromStatus = utils.errFromStatus;
const statusFromErr = utils.statusFromErr;

view: *c.PuglView,

const View = @This();

/// Create a new view.
///
/// A newly created view does not correspond to a real system view or window.
/// It must first be configured, then the system view can be created with `realize`.
pub fn new(world: *const pugl.World) error{OutOfMemory}!View {
    return .{ .view = c.puglNewView(world.world) orelse return pugl.Error.OutOfMemory };
}

/// Free a view created with `new`
pub fn free(self: *const View) void {
    c.puglFreeView(self.view);
}

/// Return the world that this view is a part of
pub fn getWorld(self: *const View) pugl.World {
    return .{ .world = c.puglGetWorld(self.view).? };
}

/// Set the user data for a view.
///
/// This is usually a pointer to a struct that contains all the state which must be accessed by a view.
/// Everything needed to process events should be stored here, not in static variables.
///
/// The handle is opaque to Pugl and is not interpreted in any way.
pub fn setHandle(self: *const View, handle: ?*anyopaque) void {
    c.puglSetHandle(self.view, handle);
}

/// Get the user data for a view
///
/// Returns null if `setHandle` was not called or called with null.
pub fn getHandle(self: *const View) ?*anyopaque {
    return c.puglGetHandle(self.view);
}

/// Set the graphics backend to use for a view.
///
/// This must be called once to set the graphics backend before calling `realize`.
///
/// Pugl includes the following backends:
/// - `backend.gl`
/// - `backend.vulkan`
/// - `backend.cairo`
/// - `backend.stub`
///
/// After initializing a backend with `new`, pass its `backend` field to this function.
///
/// Note that backends are modular and not compiled into the main Pugl library to avoid unnecessary dependencies.
/// To use a particular backend, applications must link against the appropriate backend library,
/// or be sure to compile in the appropriate code if using a local copy of Pugl.
pub fn setBackend(self: *const View, backend: *const c.PuglBackend) pugl.Error!void {
    try errFromStatus(c.puglSetBackend(self.view, backend));
}

/// Return the graphics backend used by a view
pub fn getBackend(self: *const View) ?*const c.PuglBackend {
    return c.puglGetBackend(self.view);
}

/// Set the function to call when an event occurs
pub fn setEventFunc(
    self: *const View,
    func: fn (*const View, event.Event) pugl.Error!void,
) pugl.Error!void {
    const c_func = struct {
        fn inner(c_view: ?*c.PuglView, c_event: [*c]const c.PuglEvent) callconv(.c) c.PuglStatus {
            func(&View{ .view = c_view.? }, event.Event.from(c_event)) catch |e| {
                return statusFromErr(e);
            };
            return c.PUGL_SUCCESS;
        }
    }.inner;

    try errFromStatus(c.puglSetEventFunc(self.view, &c_func));
}

/// An integer hint for configuring a view
pub const IntHint = enum(c_uint) {
    /// OpenGL context major version
    context_version_major = c.PUGL_CONTEXT_VERSION_MAJOR,
    /// OpenGL context minor version
    context_version_minor = c.PUGL_CONTEXT_VERSION_MINOR,
    /// Number of bits for red channel
    red_bits = c.PUGL_RED_BITS,
    /// Number of bits for green channel
    green_bits = c.PUGL_GREEN_BITS,
    /// Number of bits for blue channel
    blue_bits = c.PUGL_BLUE_BITS,
    /// Number of bits for alpha channel
    alpha_bits = c.PUGL_ALPHA_BITS,
    /// Number of bits for depth buffer
    depth_bits = c.PUGL_DEPTH_BITS,
    /// Number of bits for stencil buffer
    stencil_bits = c.PUGL_STENCIL_BITS,
    /// Number of sample buffers (AA)
    sample_buffers = c.PUGL_SAMPLE_BUFFERS,
    /// Number of samples per pixel (AA)
    samples = c.PUGL_SAMPLES,
    /// Number of frames between buffer swaps
    swap_interval = c.PUGL_SWAP_INTERVAL,
    /// Refresh rate in Hz
    refresh_rate = c.PUGL_REFRESH_RATE,
};

/// Set an integer hint to configure view properties.
///
/// A `null` value means "don't care".
///
/// This only has an effect when called before `realize`.
pub fn setIntHint(self: *const View, hint: IntHint, value: ?i32) pugl.Error!void {
    try errFromStatus(c.puglSetViewHint(self.view, @intFromEnum(hint), value orelse c.PUGL_DONT_CARE));
}

/// Get the integer value for a view hint.
///
/// A `null` return value means "don't care".
///
/// If the view has been realized,
/// this can be used to get the actual value of a hint which was initially set to `null`,
/// or has been adjusted from the suggested value.
pub fn getIntHint(self: *const View, hint: IntHint) ?IntHint {
    const res = c.puglGetViewHint(self.view, @intFromEnum(hint));
    return if (res == c.PUGL_DONT_CARE) null else @enumFromInt(res);
}

pub const BoolHint = enum(c_uint) {
    /// OpenGL context debugging enabled
    context_debug = c.PUGL_CONTEXT_DEBUG,
    /// True if double buffering should be used
    double_buffer = c.PUGL_DOUBLE_BUFFER,
    /// True if view should be resizable
    resizable = c.PUGL_RESIZABLE,
    /// True if key repeat events are ignored
    ignore_key_repeat = c.PUGL_IGNORE_KEY_REPEAT,
    /// True if window frame should be dark
    dark_frame = c.PUGL_DARK_FRAME,
};

/// Set a boolean hint to configure view properties.
///
/// A `null` value means "don't care".
///
/// This only has an effect when called before `realize`.
pub fn setBoolHint(self: *const View, hint: BoolHint, value: ?bool) pugl.Error!void {
    try errFromStatus(c.puglSetViewHint(self.view, @intFromEnum(hint), if (value) |v| @intFromBool(v) else c.PUGL_DONT_CARE));
}

/// Get the boolean value for a view hint.
///
/// A `null` return value means "don't care".
///
/// If the view has been realized,
/// this can be used to get the actual value of a hint which was initially set to `null`,
/// or has been adjusted from the suggested value.
pub fn getBoolHint(self: *const View, hint: IntHint) ?IntHint {
    const res = c.puglGetViewHint(self.view, @intFromEnum(hint));
    return if (res == c.PUGL_DONT_CARE) null else @enumFromInt(res);
}

/// OpenGL render API
pub const ContextApi = enum(c_int) {
    opengl = c.PUGL_OPENGL_API,
    opengl_es = c.PUGL_OPENGL_ES_API,
};

/// Set the OpenGL render API.
///
/// A `null` value means "don't care".
///
/// This only has an effect when called before `realize`.
pub fn setContextApi(self: *const View, value: ?ContextApi) pugl.Error!void {
    try errFromStatus(c.puglSetViewHint(self.view, c.PUGL_CONTEXT_API, if (value) |v| @intFromEnum(v) else c.PUGL_DONT_CARE));
}

/// Get the OpenGL render API.
///
/// A `null` return value means "don't care".
///
/// If the view has been realized,
/// this can be used to get the actual API which was initially set to `null`,
/// or has been adjusted from the suggested value.
pub fn getContextApi(self: *const View) ?ContextApi {
    const res = c.puglGetViewHint(self.view, c.PUGL_CONTEXT_API);
    return if (res == -1) null else @enumFromInt(res);
}

/// OpenGL context profile
pub const ContextProfile = enum(c_int) {
    core = c.PUGL_OPENGL_CORE_PROFILE,
    compatibility = c.PUGL_OPENGL_COMPATIBILITY_PROFILE,
};

/// Set the OpenGL context profile.
///
/// A `null` value means "don't care".
///
/// This only has an effect when called before `View.realize()`.
pub fn setContextProfile(self: *const View, value: ?ContextProfile) pugl.Error!void {
    try errFromStatus(c.puglSetViewHint(self.view, c.PUGL_CONTEXT_PROFILE, if (value) |v| @intFromEnum(v) else c.PUGL_DONT_CARE));
}

/// Get the OpenGL context profile.
///
/// A `null` return value means "don't care".
///
/// If the view has been realized,
/// this can be used to get the actual API which was initially set to `null`,
/// or has been adjusted from the suggested value.
pub fn getContextProfile(self: *const View) ?ContextProfile {
    const res = c.puglGetViewHint(self.view, c.PUGL_CONTEXT_PROFILE);
    return if (res == c.PUGL_DONT_CARE) null else @enumFromInt(res);
}

/// View type
pub const Type = enum(c_int) {
    /// A normal top-level window
    normal = c.PUGL_VIEW_TYPE_NORMAL,
    /// A utility window like a palette or toolbox
    utility = c.PUGL_VIEW_TYPE_UTILITY,
    /// A dialog window
    dialog = c.PUGL_VIEW_TYPE_DIALOG,
};

/// Set the view type.
///
/// A `null` value means "don't care".
///
/// This only has an effect when called before `realize`.
pub fn setType(self: *const View, value: ?Type) pugl.Error!void {
    try errFromStatus(c.puglSetViewHint(self.view, c.PUGL_VIEW_TYPE, if (value) |v| @intFromEnum(v) else c.PUGL_DONT_CARE));
}

/// Get the view type.
///
/// A `null` return value means "don't care".
///
/// If the view has been realized,
/// this can be used to get the actual type which was initially set to `null`,
/// or has been adjusted from the suggested value.
pub fn getType(self: *const View) ?Type {
    const res = c.puglGetViewHint(self.view, c.PUGL_VIEW_TYPE);
    return if (res == c.PUGL_DONT_CARE) null else @enumFromInt(res);
}

/// Set a string property to configure view properties.
///
/// The string value only needs to be valid for the duration of this call, it will be copied if necessary.
pub fn setStringHint(self: *const View, hint: pugl.StringHint, value: [:0]const u8) pugl.Error!void {
    try errFromStatus(c.puglSetViewString(self.view, @intFromEnum(hint), value));
}

/// Get a view string property.
///
/// The returned string should be accessed immediately, or copied.
/// It may become invalid upon any call to any function that manipulates the same view.
pub fn getStringHint(self: *const View, hint: pugl.StringHint) [:0]const u8 {
    return std.mem.span(c.puglGetViewString(self.view, @intFromEnum(hint)));
}

/// Return the scale factor of the view.
///
/// This factor describe how large UI elements (especially text) should be compared to "normal".
/// For example, 2.0 means the UI should be drawn twice as large.
/// "Normal" is loosely defined, but means a good size on a "standard DPI" display (around 96 DPI).
/// In other words, the scale 1.0 should have text that is reasonably sized on a 96 DPI display,
/// and the scale 2.0 should have text twice that large.
pub fn getScaleFactor(self: *const View) f64 {
    return c.puglGetScaleFactor(self.view);
}

/// A 2-dimensional position within/of a view
pub const Point = struct { x: i16, y: i16 };

/// A hint for configuring/constraining the position of a view.
///
/// The system will attempt to make the view's window adhere to these,
/// but they are suggestions, not hard constraints.
/// Applications should handle any view position gracefully.
/// An unset position has `INT16_MIN` (-32768) for both `x` and `y`.
/// In practice, set positions should be between -16000 and 16000 for portability.
/// Usually, the origin is the top left of the display, although negative coordinates are possible,
/// particularly on multi-display system.
pub const PositionHint = enum(c_uint) {
    /// Default position.
    ///
    /// This is used as the position during window creation as a default, if no other position is specified.
    /// It isn't necessary to set a default position (unlike the default size, which is required).
    /// If not even a default position is set, then the window will be created at an arbitrary position.
    /// This position is a best-effort attempt to do the most reasonable thing for the initial display of the
    /// window, for example, by centering.
    /// Note that it is implementation-defined, subject to change, platform-specific, and for embedded views,
    /// may no longer make sense if the parent's size is adjusted.
    /// Code that wants to make assumptions about the initial position must set the default to a specific valid one,
    /// such as `{0, 0}`.
    default = c.PUGL_DEFAULT_POSITION,
    /// Current position.
    ///
    /// This reflects the current position of the view,
    /// which may be different from the default position if the view has been moved by the user, window manager,
    /// or for any other reason.
    /// Typically, it overrides the default position.
    current = c.PUGL_CURRENT_POSITION,
};

/// Set a position hint for the view.
///
/// This can be used to set the default or current position of a view.
/// This should be called before `realize` so the initial window for the view can be configured correctly.
/// It may also be used dynamically after the window is realized, for some hints.
///
/// Always succeeds if the view is not yet realized.
pub fn setPositionHint(self: *const View, hint: PositionHint, point: Point) pugl.Error!void {
    try errFromStatus(c.puglSetPositionHint(self.view, @intFromEnum(hint), point.x, point.y));
}

/// Get a position hint for the view.
///
/// This can be used to get the default or current position of a view,
/// in screen coordinates with an upper left origin.
pub fn getPositionHint(self: *const View, hint: PositionHint) Point {
    const res = c.puglGetPositionHint(self.view, @intFromEnum(hint));
    return .{ .x = res.x, .y = res.y };
}

/// A hint for configuring/constraining the size of a view.
/// The system will attempt to make the view's window adhere to these, but they are suggestions, not hard constraints.
/// Applications should handle any view size gracefully.
pub const SizeHint = enum(c_uint) {
    /// Default size.
    ///
    /// This is used as the size during window creation as a default, if no other size is specified.
    default = c.PUGL_DEFAULT_SIZE,
    /// Current size.
    ///
    /// This reflects the current size of the view,
    /// which may be different from the default size if the view is resizable.
    /// Typically, it overrides the default size.
    current = c.PUGL_CURRENT_SIZE,
    /// Minimum size.
    ///
    /// If set, the view's size should be constrained to be at least this large.
    minimum = c.PUGL_MIN_SIZE,
    /// Maximum size.
    ///
    /// If set, the view's size should be constrained to be at most this large.
    maximum = c.PUGL_MAX_SIZE,
    /// Fixed aspect ratio.
    ///
    /// If set, the view's size should be constrained to this aspect ratio.
    /// Mutually exclusive with `minimum_aspect` and `maximum_aspect`.
    fixed_aspect = c.PUGL_FIXED_ASPECT,
    /// Minimum aspect ratio.
    ///
    /// If set, the view's size should be constrained to an aspect ratio no lower than this.
    /// Mutually exclusive with `fixed_aspect`.
    minimum_aspect = c.PUGL_MIN_ASPECT,
    /// Maximum aspect ratio.
    ///
    /// If set, the view's size should be constrained to an aspect ratio no higher than this.
    /// Mutually exclusive with `fixed_aspect`.
    maximum_aspect = c.PUGL_MAX_ASPECT,
};

/// A 2-dimensional size within/of a view
pub const Area = struct { width: u32, height: u32 };

/// Set a size hint for the view.
///
/// This can be used to set the default, current, minimum, and maximum size of a view,
/// as well as the supported range of aspect ratios.
/// This should be called before `realize` so the initial window for the view can be configured correctly.
/// It may also be used dynamically after the window is realized, for some hints.
///
/// Always succeeds if the view is not yet realized.
pub fn setSizeHint(self: *const View, hint: SizeHint, size: Area) pugl.Error!void {
    try errFromStatus(c.puglSetSizeHint(self.view, @intFromEnum(hint), size.width, size.height));
}

/// Get a size hint for the view.
///
/// This can be used to get the default, current, minimum, and maximum size of a view,
/// as well as the supported range of aspect ratios.
pub fn getSizeHint(self: *const View, hint: SizeHint) Area {
    const res = c.puglGetSizeHint(self.view, @intFromEnum(hint));
    return .{ .width = res.width, .height = res.height };
}

/// A native view handle.
///
/// X11: This is a `Window`.
///
/// MacOS: This is a pointer to an `NSView*`.
///
/// Windows: This is a `HWND`.
pub const NativeView = usize;

/// Set the parent for embedding a view in an existing window.
///
/// This must be called before `realize`, reparenting is not supported.
pub fn setParent(self: *const View, parent: NativeView) pugl.Error!void {
    try errFromStatus(c.puglSetParent(self.view, parent));
}

/// Return the parent window this view is embedded in, or null.
pub fn getParent(self: *const View) ?NativeView {
    const res = c.puglGetParent(self.view);
    return if (res == 0) null else res;
}

/// Set the transient parent of the window.
///
/// Set this for transient children like dialogs, to have them properly associated with their parent window.
/// This should be called before `realize`.
///
/// A view can either have a parent (for embedding) or a transient parent (for top-level windows like dialogs),
/// but not both.
pub fn setTransientParent(self: *const View, parent: c.PuglNativeView) pugl.Error!void {
    try errFromStatus(c.puglSetTransientParent(self.view, parent));
}

/// Return the native handle to the window this view is a transient child of, or null.
pub fn getTransientParent(self: *const View) ?c.PuglNativeView {
    const res = c.puglGetTransientParent(self.view);
    return if (res == 0) null else res;
}

/// Realize a view by creating a corresponding system view or window.
///
/// After this call, the (initially invisible) underlying system view exists and can be accessed with `getNativeView`.
///
/// The view should be fully configured using the above functions before this is called.
/// This function may only be called once per view.
pub fn realize(self: *const View) pugl.Error!void {
    try errFromStatus(c.puglRealize(self.view));
}

/// Unrealize a view by destroying the corresponding system view or window.
///
/// This is the inverse of `realize`.
/// After this call, the view no longer corresponds to a real system view, and can be realized again later.
pub fn unrealize(self: *const View) pugl.Error!void {
    try errFromStatus(c.puglUnrealize(self.view));
}

/// A command to control the behaviour of `show`.
pub const ShowCommand = enum(c_uint) {
    /// Realize and show the window without intentionally raising it.
    ///
    /// This will weakly "show" the window but without making any effort to raise it.
    /// Depending on the platform or system configuration, the window may be raised above some others regardless.
    passive = c.PUGL_SHOW_PASSIVE,
    /// Raise the window to the top of the application's stack.
    ///
    /// This is the normal "well-behaved" way to show and raise the window, which should be used in most cases.
    raise = c.PUGL_SHOW_RAISE,
    /// Aggressively force the window to be raised to the top.
    ///
    /// This will attempt to raise the window to the top, even if this isn't the active application,
    /// or if doing so would otherwise go against the platform's guidelines.
    /// This generally shouldn't be used, and isn't guaranteed to work.
    /// On modern Windows systems,
    /// the active application must explicitly grant permission for others to steal the foreground from it.
    force_raise = c.PUGL_SHOW_FORCE_RAISE,
};

/// Show the view.
///
/// If the view has not yet been realized, the first call to this function will do so automatically.
///
/// If the view is currently hidden, it will be shown and possibly raised to the top depending on the platform.
pub fn show(self: *const View, command: ShowCommand) pugl.Error!void {
    try errFromStatus(c.puglShow(self.view, @intFromEnum(command)));
}

/// Hide the current window
pub fn hide(self: *const View) pugl.Error!void {
    try errFromStatus(c.puglHide(self.view));
}

/// View style flags.
///
/// Style flags reflect special modes and states supported by the window system.
/// Applications should ideally use a single main view, but can monitor or manipulate style flags to better integrate
/// with the window system.
pub const ViewStyle = packed struct {
    /// View is mapped to a real window and potentially visible
    mapped: bool = false,
    /// View is modal, typically a dialog box of its transient parent
    modal: bool = false,
    /// View should be above most others
    above: bool = false,
    /// View should be below most others
    below: bool = false,
    /// View is minimized, shaded, or otherwise invisible
    hidden: bool = false,
    /// View is maximized to fill the screen vertically
    tall: bool = false,
    /// View is maximized to fill the screen horizontally
    wide: bool = false,
    /// View is enlarged to fill the entire screen with no decorations
    fullscreen: bool = false,
    /// View is being resized
    resizing: bool = false,
    /// View is ready for input or otherwise demanding attention
    demanding: bool = false,
    _: u22 = 0,

    pub fn cast(self: ViewStyle) u32 {
        return @bitCast(self);
    }

    pub fn from(style: u32) ViewStyle {
        return @bitCast(style);
    }
};

test ViewStyle {
    try std.testing.expectEqual(@sizeOf(u32), @sizeOf(ViewStyle));
    try std.testing.expectEqual(0, (ViewStyle{}).cast());
    try std.testing.expectEqual(
        @as(u32, c.PUGL_VIEW_STYLE_MAPPED | c.PUGL_VIEW_STYLE_MODAL | c.PUGL_VIEW_STYLE_ABOVE | c.PUGL_VIEW_STYLE_BELOW |
            c.PUGL_VIEW_STYLE_HIDDEN | c.PUGL_VIEW_STYLE_TALL | c.PUGL_VIEW_STYLE_WIDE | c.PUGL_VIEW_STYLE_FULLSCREEN |
            c.PUGL_VIEW_STYLE_RESIZING | c.PUGL_VIEW_STYLE_DEMANDING),
        (ViewStyle{
            .mapped = true,
            .modal = true,
            .above = true,
            .below = true,
            .hidden = true,
            .tall = true,
            .wide = true,
            .fullscreen = true,
            .resizing = true,
            .demanding = true,
        }).cast(),
    );
    try std.testing.expectEqual(@as(u32, c.PUGL_MAX_VIEW_STYLE_FLAG), (ViewStyle{ .demanding = true }).cast());
}

/// Set a view state, if supported by the system.
///
/// This can be used to manipulate the window into various special states,
/// but note that not all states are supported on all systems.
/// This function may return failure or an error if the platform implementation doesn't "understand" how to set the
/// given style, but the return value here can't be used to determine if the state has actually been set.
/// Any changes to the actual state of the view will arrive in later configure events.
pub fn setViewStyle(self: *const View, flags: ViewStyle) pugl.Error!void {
    try errFromStatus(c.puglSetViewStyle(self.view, flags.cast()));
}

/// The result is determined based on the state announced in the last configure event.
pub fn getViewStyle(self: *const View) ViewStyle {
    return @bitCast(c.puglGetViewStyle(self.view));
}

/// Return true if the view is currently visible
pub fn getVisible(self: *const View) bool {
    return c.puglGetVisible(self.view);
}

/// Return the native window handle
pub fn getNativeView(self: *const View) NativeView {
    return c.puglGetNativeView(self.view);
}

// TODO: graphics context union
/// Get the graphics context.
///
/// This is a backend-specific context used for drawing if the backend graphics API requires one.
/// It is only available during an expose.
///
/// Cairo: Returns a pointer to a [cairo_t](http://www.cairographics.org/manual/cairo-cairo-t.html).
///
/// All other backends: returns null.
pub fn getContext(self: *const View) ?*anyopaque {
    return c.puglGetContext(self.view);
}

/// Request a redisplay for the entire view.
///
/// This will cause an expose event to be dispatched later.
/// If called from within the event handler, the expose should arrive at the end of the current event loop iteration,
/// though this is not strictly guaranteed on all platforms.
/// If called elsewhere, an expose will be enqueued to be processed in the next event loop iteration.
pub fn obscure(self: *const View) pugl.Error!void {
    try errFromStatus(c.puglObscureView(self.view));
}

/// "Obscure" a region so it will be exposed in the next render.
///
/// This will cause an expose event to be dispatched later.
/// If called from within the event handler, the expose should arrive at the end of the current event loop iteration,
/// though this is not strictly guaranteed on all platforms.
/// If called elsewhere, an expose will be enqueued to be processed in the next event loop iteration.
///
/// The region is clamped to the size of the view if necessary.
///
/// `position` is the top-left coordinate of the rectangle to obscure.
pub fn obscureRegion(self: *const View, position: Point, area: Area) pugl.Error!void {
    try errFromStatus(c.puglObscureRegion(self.view, position.x, position.y, area.width, area.height));
}

/// Grab the keyboard input focus.
///
/// Note that this will fail if the view is not mapped and so should not, for example,
/// be called immediately after `show`.
pub fn grabFocus(self: *const View) pugl.Error!void {
    try errFromStatus(c.puglGrabFocus(self.view));
}

/// Return whether this view has the keyboard input focus
pub fn hasFocus(self: *const View) bool {
    return c.puglHasFocus(self.view);
}

/// Request data from the general copy/paste clipboard.
///
/// An `event.DataOffer` will be sent if data is available.
pub fn paste(self: *const View) pugl.Error!void {
    try errFromStatus(c.puglPaste(self.view));
}

/// Return the number of types available for the data in a clipboard.
///
/// Returns zero if the clipboard is empty.
pub fn getNumClipboardTypes(self: *const View) u32 {
    return c.puglGetNumClipboardTypes(self.view);
}

/// Return the identifier of a type available in a clipboard.
///
/// This is usually a MIME type, but may also be another platform-specific type identifier.
/// Applications must ignore any type they do not recognize.
/// Returns null if `type_index` is out of bounds according to `getNumClipboardTypes`.
pub fn getClipboardType(self: *const View, type_index: u32) [:0]const u8 {
    return std.mem.span(c.puglGetClipboardType(self.view, type_index));
}

/// Accept data offered from a clipboard.
///
/// To accept data, this must be called while handling an `event.DataOffer`.
/// Doing so will request the data from the source as the specified type.
/// When the data is available, an `event.Data` will be sent to the view which can then retrieve the data with
/// `getClipboard`.
///
/// type_index is the index of the type that the view will accept.
/// This is the `type_index` argument to the call of `getClipboardType` that returned the accepted type.
pub fn acceptOffer(self: *const View, offer: *const event.DataOffer, type_index: u32) pugl.Error!void {
    try errFromStatus(c.puglAcceptOffer(self.view, offer.cast(), type_index));
}

/// Set the clipboard contents.
///
/// This sets the system clipboard contents, which can be retrieved with `getClipboard` or pasted into other
/// applications.
///
// `mime_type` is the MIME type of the data, "text/plain" is assumed if null.
pub fn setClipboard(self: *const View, mime_type: ?[:0]const u8, data: []anyopaque) pugl.Error!void {
    try errFromStatus(c.puglSetClipboard(self.view, mime_type orelse null, data.ptr, data.len));
}

/// Get the clipboard contents.
///
/// This gets the system clipboard contents, which may have been set with `setClipboard` or copied from another
/// application.
///
/// Returns the clipboard contents, or null.
pub fn getClipboard(self: *const View, type_index: u32, len: usize) ?*const anyopaque {
    return c.puglGetClipboard(self.view, type_index, len);
}

/// A mouse cursor type.
///
/// This is a portable subset of mouse cursors that exist on X11, MacOS, and Windows.
pub const Cursor = enum(c_uint) {
    /// Default pointing arrow
    arrow = c.PUGL_CURSOR_ARROW,
    /// Caret (I-Beam) for text entry
    caret = c.PUGL_CURSOR_CARET,
    /// Cross-hair
    crosshair = c.PUGL_CURSOR_CROSSHAIR,
    /// Hand with a pointing finger
    hand = c.PUGL_CURSOR_HAND,
    /// Operation not allowed
    no = c.PUGL_CURSOR_NO,
    /// Left/right arrow for horizontal resize
    left_right = c.PUGL_CURSOR_LEFT_RIGHT,
    /// Up/down arrow for vertical resize
    up_down = c.PUGL_CURSOR_UP_DOWN,
    /// Diagonal arrow for down/right resize
    up_left_down_right = c.PUGL_CURSOR_UP_LEFT_DOWN_RIGHT,
    /// Diagonal arrow for down/left resize
    up_right_down_left = c.PUGL_CURSOR_UP_RIGHT_DOWN_LEFT,
    /// Omnidirectional "arrow" for scrolling
    all_scroll = c.PUGL_CURSOR_ALL_SCROLL,
};

test Cursor {
    try std.testing.expectEqual(c.PUGL_NUM_CURSORS, std.meta.fields(Cursor).len);
}

/// Set the mouse cursor.
///
/// This changes the system cursor that is displayed when the pointer is inside the view.
/// May fail if setting the cursor is not supported on this system, for example if compiled on X11 without Xcursor
/// support.
///
/// Returns `BadParameter` if the given cursor is invalid, `Unsupported` if setting the cursor is not supported on this
/// system, or another error if the cursor is known but loading it fails.
pub fn setCursor(self: *const View, cursor: Cursor) pugl.Error!void {
    try errFromStatus(c.puglSetCursor(self.view, @intFromEnum(cursor)));
}

/// Activate a repeating timer event.
///
/// This starts a timer which will send an `event.Timer` to the view every `timeout` seconds.
/// This can be used to perform some action in a view at a regular interval with relatively low frequency.
/// Note that the frequency of timer events may be limited by how often `update` is called.
///
/// If the given timer already exists, it is replaced.
///
/// `id` is the identifier for this timer.
/// This is an application-specific ID that should be a low number, typically the value of a constant or `enum` that
/// starts from 0.
/// There is a platform-specific limit to the number of supported timers, and overhead associated with each,
/// so applications should create only a few timers and perform several tasks in one if necessary.
///
/// `timeout` is the period, in seconds, of this timer.
/// This is not guaranteed to have a resolution better than 10ms (the maximum timer resolution on Windows) and may be
/// rounded up if it is too short.
/// On X11 and MacOS, a resolution of about 1ms can usually be relied on.
///
/// Returns `Failure` if timers are not supported by the system, `Unknown` if setting the timer failed.
pub fn startTimer(self: *const View, id: usize, timeout: f64) pugl.Error!void {
    try errFromStatus(c.puglStartTimer(self.view, id, timeout));
}

/// Stop an active timer.
///
/// `id` is the ID previously passed to `startTimer`.
///
/// Returns `Failure` if timers are not supported by this system, `Unknown` if stopping the timer failed.
pub fn stopTimer(self: *const View, id: usize) pugl.Error!void {
    try errFromStatus(c.puglStopTimer(self.view, id));
}

/// Send an event to a view via the window system.
///
/// If supported, the event will be delivered to the view via the event loop like other events.
/// Note that this function only works for certain event types.
///
/// Currently, only `event.Client` events are supported on all platforms.
///
/// X11: An `event.Expose` event can be sent, which is similar to calling `obscureRegion`,
/// but will always send a message to the X server, even when called in an event handler.
///
/// Returns `Unsupported` if sending events of this type is not supported, `Unknown` if sending the event failed.
pub fn sendEvent(self: *const View, ev: *const event.Event) pugl.Error!void {
    try errFromStatus(c.puglSendEvent(self.view, ev.cast()));
}
