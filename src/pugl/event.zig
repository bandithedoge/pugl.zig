const std = @import("std");
const c = @import("c");
const View = @import("View.zig");

const Type = enum(c_uint) {
    nothing = c.PUGL_NOTHING,
    realize = c.PUGL_REALIZE,
    unrealize = c.PUGL_UNREALIZE,
    configure = c.PUGL_CONFIGURE,
    update = c.PUGL_UPDATE,
    blank = c.PUGL_BLANK,
    expose = c.PUGL_EXPOSE,
    flush = c.PUGL_FLUSH,
    close = c.PUGL_CLOSE,
    focus_in = c.PUGL_FOCUS_IN,
    focus_out = c.PUGL_FOCUS_OUT,
    key_press = c.PUGL_KEY_PRESS,
    key_release = c.PUGL_KEY_RELEASE,
    text = c.PUGL_TEXT,
    pointer_in = c.PUGL_POINTER_IN,
    pointer_out = c.PUGL_POINTER_OUT,
    button_press = c.PUGL_BUTTON_PRESS,
    button_release = c.PUGL_BUTTON_RELEASE,
    motion = c.PUGL_MOTION,
    scroll = c.PUGL_SCROLL,
    client = c.PUGL_CLIENT,
    timer = c.PUGL_TIMER,
    loop_enter = c.PUGL_LOOP_ENTER,
    loop_leave = c.PUGL_LOOP_LEAVE,
    data_offer = c.PUGL_DATA_OFFER,
    data = c.PUGL_DATA,
};

/// Common flags for all event types
pub const Flags = packed struct {
    /// Event is synthetic
    is_send_event: bool = false,
    /// Event is a hint (not direct user input)
    is_hint: bool = false,
    _: u30 = 0,

    pub fn cast(self: Flags) u32 {
        return @bitCast(self);
    }

    pub fn from(flags: u32) Flags {
        return @bitCast(flags);
    }
};

test Flags {
    try std.testing.expectEqual(@sizeOf(c.PuglEventFlags), @sizeOf(Flags));

    try std.testing.expectEqual(0, (Flags{}).cast());
    try std.testing.expectEqual(
        @as(u32, c.PUGL_IS_SEND_EVENT | c.PUGL_IS_HINT),
        (Flags{ .is_send_event = true, .is_hint = true }).cast(),
    );

    try std.testing.expectEqual(Flags{}, Flags.from(0));
    try std.testing.expectEqual(
        Flags{ .is_send_event = true, .is_hint = true },
        Flags.from(c.PUGL_IS_SEND_EVENT | c.PUGL_IS_HINT),
    );
}

/// Keyboard modifier flags
pub const Mods = packed struct {
    /// Shift pressed
    shift: bool = false,
    /// Control pressed
    ctrl: bool = false,
    /// Alt/Option pressed
    alt: bool = false,
    /// Super/Command/Windows pressed
    super: bool = false,
    /// Num lock enabled
    num_lock: bool = false,
    /// Scroll lock enabled
    scroll_lock: bool = false,
    /// Caps lock enabled
    caps_lock: bool = false,
    _: u25 = 0,

    pub fn cast(self: Mods) u32 {
        return @bitCast(self);
    }

    pub fn from(mods: u32) Mods {
        return @bitCast(mods);
    }
};

test Mods {
    try std.testing.expectEqual(@sizeOf(u32), @sizeOf(Mods));
    try std.testing.expectEqual(0, (Mods{}).cast());
    try std.testing.expectEqual(
        @as(u32, c.PUGL_MOD_CTRL | c.PUGL_MOD_ALT | c.PUGL_MOD_SHIFT),
        (Mods{ .ctrl = true, .alt = true, .shift = true }).cast(),
    );
    try std.testing.expectEqual(
        @as(u32, c.PUGL_MOD_SHIFT | c.PUGL_MOD_CTRL | c.PUGL_MOD_ALT | c.PUGL_MOD_SUPER | c.PUGL_MOD_NUM_LOCK |
            c.PUGL_MOD_SCROLL_LOCK | c.PUGL_MOD_CAPS_LOCK),
        (Mods{
            .shift = true,
            .ctrl = true,
            .alt = true,
            .super = true,
            .num_lock = true,
            .scroll_lock = true,
            .caps_lock = true,
        }).cast(),
    );
}

/// Common header for all event structs
pub const Any = struct {
    type: Type,
    flags: Flags,

    pub fn cast(self: *const Any) *const c.PuglAnyEvent {
        return &.{
            .type = @backingInt(self.type),
            .flags = self.flags.cast(),
        };
    }

    pub fn from(event: c.PuglAnyEvent) Any {
        return .{
            .type = @fromBackingInt(@intCast(event.type)),
            .flags = Flags.from(event.flags),
        };
    }
};

/// Button press or release event.
///
/// Button numbers start from 0, and are ordered: primary, secondary, middle.
/// So, on a typical right-handed mouse, the button numbers are:
///
/// Left: 0
///
/// Right: 1
///
/// Middle (often a wheel): 2
///
/// Higher button numbers are reported in the same order they are represented on the system.
/// There is no universal standard here, but buttons 3 and 4 are typically a pair of buttons or a rocker,
/// which are usually bound to "back" and "forward" operations.
///
/// Note that these numbers may differ from those used on the underlying platform,
/// since they are manipulated to provide a consistent portable API.
pub const Button = struct {
    type: enum(c_uint) {
        press = @backingInt(Type.button_press),
        release = @backingInt(Type.button_release),
    },
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Root-relative X coordinate
    x_root: f64,
    /// Root-relative Y coordinate
    y_root: f64,
    /// Keyboard modifier flags
    state: Mods,
    /// Button number starting from 0
    button: u32,

    pub fn cast(self: *const Button) *const c.PuglButtonEvent {
        return &.{
            .type = @backingInt(self.type),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .xRoot = self.x_root,
            .yRoot = self.y_root,
            .state = self.state.cast(),
            .button = self.button,
        };
    }

    pub fn from(event: c.PuglButtonEvent) Button {
        return .{
            .type = @fromBackingInt(@intCast(event.type)),
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .x_root = event.xRoot,
            .y_root = event.yRoot,
            .state = Mods.from(event.state),
            .button = event.button,
        };
    }
};

/// View resize or move event.
///
/// A configure event is sent whenever the view is resized or moved.
/// When a configure event is received, the graphics context is active but not set up for drawing.
/// For example, it is valid to adjust the OpenGL viewport or otherwise configure the context, but not to draw anything.
pub const Configure = struct {
    flags: Flags,
    /// Parent-relative X coordinate of view
    x: i16,
    /// Parent-relative Y coordinate of view
    y: i16,
    /// Width of view
    width: u16,
    /// Height of view
    height: u16,
    /// View style flags
    style: View.ViewStyle,

    pub fn cast(self: *const Configure) *const c.PuglConfigureEvent {
        return &.{
            .type = @backingInt(Type.configure),
            .flags = self.flags.cast(),
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
            .style = self.style.cast(),
        };
    }

    pub fn from(event: c.PuglConfigureEvent) Configure {
        return .{
            .flags = Flags.from(event.flags),
            .x = event.x,
            .y = event.y,
            .width = event.width,
            .height = event.height,
            .style = View.ViewStyle.from(event.style),
        };
    }
};

/// Expose event for when a region must be redrawn.
///
/// When an expose event is received, the graphics context is active,
/// and the view must draw the entire specified region.
/// The contents of the region are undefined, there is no preservation of anything drawn previously.
pub const Expose = struct {
    flags: Flags,
    /// View-relative top-left X coordinate of region
    x: i16,
    /// View-relative top-left Y coordinate of region
    y: i16,
    /// Width of exposed region
    width: u16,
    /// Height of exposed region
    height: u16,

    pub fn cast(self: *const Expose) *const c.PuglExposeEvent {
        return &.{
            .type = @backingInt(Type.expose),
            .flags = self.flags.cast(),
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn from(event: c.PuglExposeEvent) Expose {
        return .{
            .flags = Flags.from(event.flags),
            .x = event.x,
            .y = event.y,
            .width = event.width,
            .height = event.height,
        };
    }
};

/// Key press or release event.
///
/// This event represents low-level key presses and releases.
/// This can be used for "direct" keyboard handling like key bindings, but must not be interpreted as text input.
///
/// Keys are represented portably as Unicode code points, using the "natural" code point for the key where possible
/// (see `Keycode` enum for details).
/// The `key` field is the code for the pressed key, without any modifiers applied.
/// For example, a press or release of the 'A' key will have `key` 97 ('a') regardless of whether shift or control are
/// being held.
///
/// Alternatively, the raw `keycode` can be used to work directly with physical keys,
/// but note that this value is not portable and differs between platforms and hardware.
pub const Key = struct {
    type: enum(c_uint) {
        press = @backingInt(Type.key_press),
        release = @backingInt(Type.key_release),
    },
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Root-relative X coordinate
    x_root: f64,
    /// Root-relative Y coordinate
    y_root: f64,
    /// Keyboard modifier flags
    state: Mods,
    /// Raw key code
    keycode: u32,
    /// Unshifted Unicode character code, or 0. See `Keycode` enum
    key: u32,

    pub fn cast(self: *const Key) *const c.PuglKeyEvent {
        return &.{
            .type = @backingInt(self.type),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .xRoot = self.x_root,
            .yRoot = self.y_root,
            .state = self.state.cast(),
            .keycode = self.keycode,
            .key = self.key,
        };
    }

    pub fn from(event: c.PuglKeyEvent) Key {
        return .{
            .type = @fromBackingInt(@intCast(event.type)),
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .x_root = event.xRoot,
            .y_root = event.yRoot,
            .state = Mods.from(event.state),
            .keycode = event.keycode,
            .key = event.key,
        };
    }
};

/// Character input event.
///
/// This event represents text input, usually as the result of a key press.
/// The text is given both as a Unicode character code and a UTF-8 string.
///
/// Note that this event is generated by the platform's input system,
/// so there is not necessarily a direct correspondence between text events and physical key presses.
/// For example, with some input methods a sequence of several key presses will generate a single character.
pub const Text = struct {
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Root-relative X coordinate
    x_root: f64,
    /// Root-relative Y coordinate
    y_root: f64,
    /// Keyboard modifier flags
    state: Mods,
    /// Raw key code
    keycode: u32,
    /// Unicode character code. See `Keycode` enum
    character: u32,
    /// UTF-8 string
    string: [8]u8,

    pub fn cast(self: *const Text) *const c.PuglTextEvent {
        return &.{
            .type = @backingInt(Type.text),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .xRoot = self.x_root,
            .yRoot = self.y_root,
            .state = self.state.cast(),
            .keycode = self.keycode,
            .character = self.character,
            .string = self.string,
        };
    }

    pub fn from(event: c.PuglTextEvent) Text {
        return .{
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .x_root = event.xRoot,
            .y_root = event.yRoot,
            .state = Mods.from(event.state),
            .keycode = event.keycode,
            .character = event.character,
            .string = event.string,
        };
    }
};

/// Reason for a Crossing event
pub const CrossingMode = enum(c_uint) {
    /// Crossing due to pointer motion
    normal = c.PUGL_CROSSING_NORMAL,
    /// Crossing due to a grab
    grab = c.PUGL_CROSSING_GRAB,
    /// Crossing due to a grab release
    ungrab = c.PUGL_CROSSING_UNGRAB,
};

/// Pointer enter or leave event.
///
/// This event is sent when the pointer enters or leaves the view.
/// This can happen for several reasons (not just the user dragging the pointer over the window edge),
/// as described by the `CrossingMode` enum.
pub const Crossing = struct {
    type: enum(c_uint) {
        in = @backingInt(Type.pointer_in),
        out = @backingInt(Type.pointer_out),
    },
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Root-relative X coordinate
    x_root: f64,
    /// Root-relative Y coordinate
    y_root: f64,
    /// Keyboard modifier flags
    state: Mods,
    /// Reason for crossing
    mode: CrossingMode,

    pub fn cast(self: *const Crossing) *const c.PuglCrossingEvent {
        return &.{
            .type = @backingInt(self.type),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .xRoot = self.x_root,
            .yRoot = self.y_root,
            .state = self.state.cast(),
            .mode = @backingInt(self.mode),
        };
    }

    pub fn from(event: c.PuglCrossingEvent) Crossing {
        return .{
            .type = @fromBackingInt(@intCast(event.type)),
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .x_root = event.xRoot,
            .y_root = event.yRoot,
            .state = Mods.from(event.state),
            .mode = @fromBackingInt(@intCast(event.mode)),
        };
    }
};

/// Pointer motion event.
pub const Motion = struct {
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Root-relative X coordinate
    x_root: f64,
    /// Root-relative Y coordinate
    y_root: f64,
    /// Keyboard modifier flags
    state: Mods,

    pub fn cast(self: *const Motion) *const c.PuglMotionEvent {
        return &.{
            .type = @backingInt(Type.motion),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .xRoot = self.x_root,
            .yRoot = self.y_root,
            .state = self.state.cast(),
        };
    }

    pub fn from(event: c.PuglMotionEvent) Motion {
        return .{
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .x_root = event.xRoot,
            .y_root = event.yRoot,
            .state = Mods.from(event.state),
        };
    }
};

/// Scroll event.
///
/// The scroll distance is expressed in "lines", an arbitrary unit that corresponds to a single tick of a detented mouse
/// wheel.
/// For example, `dy` = 1.0 scrolls 1 line up.
/// Some systems and devices support finer resolution and/or higher values for fast scrolls,
/// so programs should handle any value gracefully.
pub const Scroll = struct {
    /// Scroll direction.
    ///
    /// Describes the direction of a `Scroll` event along with whether the scroll is a "smooth" scroll.
    /// The discrete directions are for devices like mouse wheels with constrained axes,
    /// while a smooth scroll is for those with arbitrary scroll direction freedom, like some touchpads.
    pub const Direction = enum(c_uint) {
        up = c.PUGL_SCROLL_UP,
        down = c.PUGL_SCROLL_DOWN,
        left = c.PUGL_SCROLL_LEFT,
        right = c.PUGL_SCROLL_RIGHT,
        smooth = c.PUGL_SCROLL_SMOOTH,
    };

    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Root-relative X coordinate
    x_root: f64,
    /// Root-relative Y coordinate
    y_root: f64,
    /// Keyboard modifier flags
    state: Mods,
    /// Scroll direction
    direction: Direction,
    /// Scroll X distance in lines
    dx: f64,
    /// Scroll Y distance in lines
    dy: f64,

    pub fn cast(self: *const Scroll) *const c.PuglScrollEvent {
        return &.{
            .type = @backingInt(Type.scroll),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .xRoot = self.x_root,
            .yRoot = self.y_root,
            .state = self.state.cast(),
            .direction = @backingInt(self.direction),
            .dx = self.dx,
            .dy = self.dy,
        };
    }

    pub fn from(event: c.PuglScrollEvent) Scroll {
        return .{
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .x_root = event.xRoot,
            .y_root = event.yRoot,
            .state = Mods.from(event.state),
            .direction = @fromBackingInt(@intCast(event.direction)),
            .dx = event.dx,
            .dy = event.dy,
        };
    }
};

/// Keyboard focus event.
///
/// This event is sent whenever the view gains or loses the keyboard focus.
/// The view with the keyboard focus will receive any key press or release events.
pub const Focus = struct {
    type: enum(c_uint) {
        in = @backingInt(Type.focus_in),
        out = @backingInt(Type.focus_out),
    },
    flags: Flags,
    /// Reason for focus change
    mode: CrossingMode,

    pub fn cast(self: *const Focus) *const c.PuglFocusEvent {
        return &.{
            .type = @backingInt(self.type),
            .flags = self.flags.cast(),
            .mode = @backingInt(self.mode),
        };
    }

    pub fn from(event: c.PuglFocusEvent) Focus {
        return .{
            .type = @fromBackingInt(@intCast(event.type)),
            .flags = Flags.from(event.flags),
            .mode = @fromBackingInt(@intCast(event.mode)),
        };
    }
};

/// Custom client message event.
///
/// This can be used to send a custom message to a view, which is delivered via the window system and processed in the
/// event loop as usual.
/// Among other things, this makes it possible to wake up the event loop for any reason.
pub const Client = struct {
    flags: Flags,
    /// Client-specific data
    data1: *anyopaque,
    /// Client-specific data
    data2: *anyopaque,

    pub fn cast(self: *const Client) *const c.PuglClientEvent {
        return &.{
            .type = @backingInt(Type.client),
            .flags = self.flags.cast(),
            .data1 = @intFromPtr(self.data1),
            .data2 = @intFromPtr(self.data2),
        };
    }

    pub fn from(event: c.PuglClientEvent) Client {
        return .{
            .flags = Flags.from(event.flags),
            .data1 = @ptrFromInt(event.data1),
            .data2 = @ptrFromInt(event.data2),
        };
    }
};

/// Timer event.
///
/// This event is sent at the regular interval specified in the call to `View.startTimer` that activated it.
///
/// The `id` is the application-specific ID given to `View.startTimer` which distinguishes this timer from others.
/// It should always be checked in the event handler, even in applications that register only one timer.
pub const Timer = struct {
    flags: Flags,
    /// Timer ID
    id: usize,

    pub fn cast(self: *const Timer) *const c.PuglTimerEvent {
        return &.{
            .type = @backingInt(Type.timer),
            .flags = self.flags.cast(),
            .id = self.id,
        };
    }

    pub fn from(event: c.PuglTimerEvent) Timer {
        return .{
            .flags = Flags.from(event.flags),
            .id = event.id,
        };
    }
};

/// Clipboard data offer event.
///
/// This event is sent when a clipboard has data present, possibly with several datatypes.
/// While handling this event, the types can be investigated with `View.getClipboardType` to decide whether to accept
/// the offer with `View.acceptOffer`.
pub const DataOffer = struct {
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Clipboard with available data
    clipboard: View.Clipboard,

    pub fn cast(self: *const DataOffer) *const c.PuglDataOfferEvent {
        return &.{
            .type = @backingInt(Type.data_offer),
            .flags = self.flags.cast(),
            .time = self.time,
            .x = self.x,
            .y = self.y,
            .clipboard = @backingInt(self.clipboard),
        };
    }

    pub fn from(event: c.PuglDataOfferEvent) DataOffer {
        return .{
            .flags = Flags.from(event.flags),
            .time = event.time,
            .x = event.x,
            .y = event.y,
            .clipboard = @fromBackingInt(@intCast(event.clipboard)),
        };
    }
};

/// Clipboard data event.
///
/// This event is sent after accepting a data offer when the data has been retrieved and converted.
/// While handling this event, the data can be accessed with `View.getClipboard`.
pub const Data = struct {
    flags: Flags,
    /// Time in seconds
    time: f64,
    /// Index of datatype
    type_index: u32,
    /// View-relative X coordinate
    x: f64,
    /// View-relative Y coordinate
    y: f64,
    /// Clipboard with available data
    clipboard: View.Clipboard,

    pub fn cast(self: *const Data) *const c.PuglDataEvent {
        return &.{
            .type = @backingInt(Type.data),
            .flags = self.flags.cast(),
            .time = self.time,
            .typeIndex = self.type_index,
            .x = self.x,
            .y = self.y,
            .clipboard = @backingInt(self.clipboard),
        };
    }

    pub fn from(event: c.PuglDataEvent) Data {
        return .{
            .flags = Flags.from(event.flags),
            .time = event.time,
            .type_index = event.typeIndex,
            .x = event.x,
            .y = event.y,
            .clipboard = @fromBackingInt(@intCast(event.clipboard)),
        };
    }
};

/// View event. See the individual event type structs for more detailed documentation.
///
/// The graphics system may only be accessed when handling certain events.
/// The graphics context is active for `realize`, `unrealize`, `configure`, and `expose`,
/// but only enabled for drawing for `expose`.
pub const Event = union(Type) {
    /// No event
    nothing: Any,
    /// View realized
    realize: Any,
    /// View unrealizeed
    unrealize: Any,
    /// View configured
    configure: Configure,
    /// View ready to draw.
    ///
    /// This is sent near the end of a main loop iteration when the view is potentially about to be redrawn.
    /// It can be used to mark regions for exposure with `View.obscure` or `View.obscureRegion`.
    /// For example, to continuously animate, obscure the view whenever an update event is received,
    /// then receive and handle the expose event(s) shortly afterwards.
    update: Any,
    /// View blank event.
    ///
    /// This event is sent to a view when it is about to be exposed, after the graphics context is entered.
    blank: Any,
    /// View must be drawn.
    ///
    /// This is sent when a region needs to be redrawn, with the graphics context entered and activated for drawing.
    /// The application must completely draw the given region.
    expose: Expose,
    /// View flush event.
    ///
    /// This event is sent to a view after it has been exposed and the graphics context is exited.
    flush: Any,
    /// View will be closed.
    ///
    /// This is sent when the view is to be closed, for example when the user clicks the close button.
    close: Any,
    /// Keyboard focus entered view
    focus_in: Focus,
    /// Keyboard focus left view
    focus_out: Focus,
    /// Key pressed
    key_press: Key,
    /// Key released
    key_release: Key,
    /// Character entered
    text: Text,
    /// Pointer entered view
    pointer_in: Crossing,
    /// Pointer left view
    pointer_out: Crossing,
    /// Mouse button pressed
    button_press: Button,
    /// Mouse button released
    button_release: Button,
    /// Pointer moved
    motion: Motion,
    /// Scrolled
    scroll: Scroll,
    /// Custom client message
    client: Client,
    /// Timer triggered
    timer: Timer,
    /// Recursive loop entered
    ///
    /// This is sent when the window system enters a recursive loop.
    /// While in the recursive loop, the main loop will be stalled and no expose events will be received.
    /// A typical use is to install a timer to perform continuous actions, such as drawing.
    ///
    /// - MacOS: A recursive loop is entered while the window is being live resized.
    /// - Windows: A recursive loop is entered while the window is being live resized or the menu is shown.
    /// - X11: A recursive loop is never entered and the event loop runs as usual while the view is being resized.
    loop_enter: Any,
    /// Recursive loop left
    ///
    /// This is sent after a loop enter event when the recursive loop is finished and normal iteration will continue.
    loop_leave: Any,
    /// Data offered from clipboard
    data_offer: DataOffer,
    /// Data available from clipboard
    data: Data,

    pub fn cast(self: *const Event) *const c.PuglEvent {
        return switch (self.*) {
            inline else => |ev| @ptrCast(&ev.cast()),
        };
    }

    pub fn from(event: *const c.PuglEvent) Event {
        return switch (@as(Type, @fromBackingInt(@intCast(event.type)))) {
            .nothing => .{ .nothing = Any.from(event.any) },
            .realize => .{ .realize = Any.from(event.any) },
            .unrealize => .{ .unrealize = Any.from(event.any) },
            .configure => .{ .configure = Configure.from(event.configure) },
            .update => .{ .update = Any.from(event.any) },
            .blank => .{ .blank = Any.from(event.any) },
            .expose => .{ .expose = Expose.from(event.expose) },
            .flush => .{ .flush = Any.from(event.any) },
            .close => .{ .close = Any.from(event.any) },
            .focus_in => .{ .focus_in = Focus.from(event.focus) },
            .focus_out => .{ .focus_out = Focus.from(event.focus) },
            .key_press => .{ .key_press = Key.from(event.key) },
            .key_release => .{ .key_release = Key.from(event.key) },
            .text => .{ .text = Text.from(event.text) },
            .pointer_in => .{ .pointer_in = Crossing.from(event.crossing) },
            .pointer_out => .{ .pointer_out = Crossing.from(event.crossing) },
            .button_press => .{ .button_press = Button.from(event.button) },
            .button_release => .{ .button_release = Button.from(event.button) },
            .motion => .{ .motion = Motion.from(event.motion) },
            .scroll => .{ .scroll = Scroll.from(event.scroll) },
            .client => .{ .client = Client.from(event.client) },
            .timer => .{ .timer = Timer.from(event.timer) },
            .loop_enter => .{ .loop_enter = Any.from(event.any) },
            .loop_leave => .{ .loop_leave = Any.from(event.any) },
            .data_offer => .{ .data_offer = DataOffer.from(event.offer) },
            .data => .{ .data = Data.from(event.data) },
        };
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
