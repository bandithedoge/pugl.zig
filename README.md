Zig bindings for [Pugl](https://gitlab.com/lv2/pugl), a minimal portable API for embeddable GUIs

# Dependencies

- Zig 0.14.0
- X11 platform:
  - libX11
  - libXrender
  - libXcursor (optional, `-Dxcursor=true`)
  - libXrandr (optional, `-Dxrandr=true`)
  - libXext (optional, `-Dxsync=true`)
- OpenGL backend:
  - libGL
- Vulkan backend:
  - vulkan-loader
- Cairo backend:
  - cairo (optional, `-Dbuild_cairo=false`)
  - glib (optional, Linux-only, `-Dbuild_cairo=true`)

# Usage

`zig fetch --save=pugl https://github.com/bandithedoge/pugl.zig/archive/<commit>.tar.gz`

In `build.zig`:

```zig
pub fn build(b: *std.Build) !void {
    // ...

    const pugl = b.dependency("pugl", .{
        .target = target,
        .optimize = optimize,
        // choose your desired backends
        // multiple can be enabled and selected at runtime
        .opengl = true,
        .vulkan = false,
        .cairo = false,
        .stub = false,
        // see `build.zig` or run `zig build --help` for more options
    });

    my_exe.root_module.addImport("pugl", pugl.module("pugl"));
    // replace `opengl` with your desired backend
    my_exe.root_module.addImport("backend_opengl", pugl.module("backend_opengl"));

    // ...
}
```

In your source file:

```zig
const pugl = @import("pugl");
// replace with your desired backend, make sure it's enabled in build.zig!
const OpenGlBackend = @import("backend_opengl");

pub fn main() !void {
    // ...

    var world = try pugl.World.new(.program, .{});
    defer world.free();

    const view = try pugl.View.new(&world);
    defer view.free();

    try view.setStringHint(.window_title, "my awesome app");
    // set other world and view hints here

    view.setHandle(&my_app_struct); // optional

    const backend = OpenGlBackend.new();
    try view.setBackend(backend.backend);

    try view.setEventFunc(onEvent);

    try view.realize();
    try view.show(.raise);

    while (!should_close) {
        // the argument determines if this function blocks and for how long
        // audio plugins and other embedded windows should use `0` to avoid blocking the host
        try world.update(-1);
    }

    // ...
}

fn onEvent(view: *const pugl.View, event: pugl.event.Event) pugl.Error!void {
    // optional, `view.getHandle()` returns null if no handle was set
    const my_app_struct: *MyApp = @ptrCast(@alignCast(view.getHandle().?))
    // see API docs for all possible event types
    switch (event) {
        .configure => |e| {
            // ...
        },
        .expose => {
            // ...
        },
        .update => {
            // ...
        },
        .close => {
            // ...
        },
        else => {},
    }
}
```

The `examples/` directory contains sample programs mostly rewritten from Pugl's upstream C examples.
