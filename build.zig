const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = .{
        // TODO: statically linked libGL
        .backend_opengl = b.option(bool, "opengl", "Enable support for the OpenGL graphics API") orelse false,
        // TODO: statically linked vulkan-loader
        .backend_vulkan = b.option(bool, "vulkan", "Enable support for the Vulkan graphics API") orelse false,
        .backend_cairo = b.option(bool, "cairo", "Enable support for the Cairo graphics API") orelse false,
        .backend_stub = b.option(bool, "stub", "Build stub backend") orelse false,

        // TODO: statically linked X11 libs
        .use_xcursor = b.option(bool, "xcursor", "Support changing the cursor on X11") orelse true,
        .use_xrandr = b.option(bool, "xrandr", "Support accessing the refresh rate on X11") orelse true,
        .use_xsync = b.option(bool, "xsync", "Support timers on X11") orelse true,
        .win_wchar = b.option(bool, "win_wchar", "Use UTF-16 wchar_t and UNICODE with Windows API") orelse true,
        .build_cairo = b.option(bool, "build_cairo", "Build and link pugl.zig's pinned version of Cairo") orelse true,
    };

    const options_step = b.addOptions();
    inline for (std.meta.fields(@TypeOf(options))) |option| {
        options_step.addOption(option.type, option.name, @field(options, option.name));
    }

    const platform: enum { x11, mac, win } = switch (target.result.os.tag) {
        .linux, .freebsd, .openbsd, .netbsd, .dragonfly => .x11,
        .macos => .mac,
        .windows => .win,
        else => |p| std.debug.panic("unsupported platform: {}", .{p}),
    };
    options_step.addOption(@TypeOf(platform), "platform", platform);
    const c_src_ext = if (platform == .mac) "m" else "c";

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    try c_flags.appendSlice(&.{ "-DPUGL_INTERNAL", "-DPUGL_STATIC" });

    var tests = std.ArrayList([]const u8).init(b.allocator);

    const pugl_dep = b.dependency("pugl", .{});

    const pugl_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/pugl.zig"),
        .link_libc = true,
        .imports = &.{.{ .name = "pugl_options", .module = options_step.createModule() }},
    });

    const pugl = b.addStaticLibrary(.{
        .name = "pugl",
        .root_source_file = pugl_module.root_source_file,
        .target = target,
        .optimize = optimize,
    });

    pugl.linkSystemLibrary("m");

    pugl.addIncludePath(pugl_dep.path("include"));
    pugl.installHeadersDirectory(pugl_dep.path("include"), "", .{});
    pugl.installHeadersDirectory(pugl_dep.path("subprojects/puglutil/include"), "", .{});

    switch (platform) {
        .x11 => {
            if (b.lazyDependency("x11", .{
                .target = target,
                .optimize = optimize,
            })) |x11|
                pugl.linkLibrary(x11.artifact("x11-headers"));

            pugl.linkSystemLibrary("x11");

            try c_flags.append("-D_POSIX_C_SOURCE=200809L");

            if (options.use_xcursor) {
                pugl.linkSystemLibrary("xcursor");
                try c_flags.append("-DUSE_XCURSOR=1");
            }

            if (options.use_xrandr) {
                pugl.linkSystemLibrary("xrandr");
                try c_flags.append("-DUSE_XRANDR=1");
            }

            if (options.use_xsync) {
                pugl.linkSystemLibrary("xext");
                try c_flags.append("-DUSE_XSYNC=1");
            }
        },
        .mac => {
            pugl.linkFramework("Cocoa");
        },
        .win => {
            try c_flags.appendSlice(&.{
                "-DWINVER=0x0500", // Windows 2000
                "-D_WIN32_WINNT=0x0500", // Windows 2000
                // Disable as many things from windows.h as possible
                "-DWIN32_LEAN_AND_MEAN",
                "-DNOGDICAPMASKS", // CC_*, LC_*, PC_*, CP_*, TC_*, RC_
                "-DNOSYSMETRICS", // SM_*
                "-DNOKEYSTATES", // MK_*
                "-DOEMRESOURCE", // OEM Resource values
                "-DNOATOM", // Atom Manager routines
                "-DNOCOLOR", // Screen colors
                "-DNODRAWTEXT", // DrawText() and DT_*
                "-DNOKERNEL", // All KERNEL defines and routines
                "-DNOMB", // MB_* and MessageBox()
                "-DNOMEMMGR", // GMEM_*, LMEM_*, GHND, LHND, associated routines
                "-DNOMETAFILE", // typedef METAFILEPICT
                "-DNOMINMAX", // Macros min(a,b) and max(a,b)
                "-DNOOPENFILE", // OpenFile(), OemToAnsi, AnsiToOem, and OF_*
                "-DNOSCROLL", // SB_* and scrolling routines
                "-DNOSERVICE", // All Service Controller routines, SERVICE_ equates, etc.
                "-DNOSOUND", // Sound driver routines
                "-DNOWH", // SetWindowsHook and WH_*
                "-DNOCOMM", // COMM driver routines
                "-DNOKANJI", // Kanji support stuff
                "-DNOHELP", // Help engine interface
                "-DNOPROFILER", // Profiler interface
                "-DNODEFERWINDOWPOS", // DeferWindowPos routines
                "-DNOMCX", // Modem Configuration Extensions
            });
            if (options.win_wchar)
                try c_flags.appendSlice(&.{ "-DUNICODE", "-D_UNICODE" });
            pugl.linkSystemLibrary("user32");
            pugl.linkSystemLibrary("shlwapi");
            pugl.linkSystemLibrary("dwmapi");
            pugl.linkSystemLibrary("gdi32");
        },
    }

    if (options.backend_opengl) {
        if (b.lazyDependency("opengl", .{
            .target = target,
            .optimize = optimize,
        })) |opengl|
            pugl.linkLibrary(opengl.artifact("opengl-headers"));

        pugl.linkSystemLibrary("gl");

        pugl.addCSourceFile(.{ .file = pugl_dep.path(b.fmt("src/{s}_gl.{s}", .{ @tagName(platform), c_src_ext })) });

        try tests.appendSlice(&.{
            "gl",
            "gl_free_unrealized",
            "gl_hints",
        });
    }

    if (options.backend_vulkan) {
        if (b.lazyDependency("vulkan", .{
            .target = target,
            .optimize = optimize,
        })) |vulkan| {
            pugl.linkLibrary(vulkan.artifact("vulkan-headers"));
            pugl.installHeadersDirectory(vulkan.path("include"), "", .{});
        }

        pugl.linkSystemLibrary("vulkan");

        pugl.addCSourceFile(.{
            .file = pugl_dep.path(b.fmt("src/{s}_vulkan.{s}", .{ @tagName(platform), c_src_ext })),
            .flags = c_flags.items,
        });

        if (platform == .mac) {
            pugl.linkFramework("Metal");
            pugl.linkFramework("QuartzCore");
        }

        try tests.append("vulkan");
    }

    if (options.backend_cairo) {
        if (options.build_cairo)
            if (b.lazyDependency("cairo", .{
                .target = target,
                .optimize = optimize,
                .use_zlib = false,
                .use_xcb = false,
                .symbol_lookup = false,
                .use_glib = false,
            })) |cairo| {
                const artifact = cairo.artifact("cairo");

                pugl.linkLibrary(artifact);
                pugl.installHeadersDirectory(artifact.getEmittedIncludeTree().path(cairo.builder, ""), "", .{});
                b.installArtifact(artifact);
            };

        pugl.addCSourceFile(.{
            .file = pugl_dep.path(b.fmt("src/{s}_cairo.{s}", .{ @tagName(platform), c_src_ext })),
            .flags = c_flags.items,
        });

        try tests.append("cairo");
    }

    if (options.backend_stub) {
        pugl.addCSourceFile(.{
            .file = pugl_dep.path(b.fmt("src/{s}_stub.{s}", .{ @tagName(platform), c_src_ext })),
            .flags = c_flags.items,
        });

        try tests.appendSlice(&.{
            "cursor",
            "realize",
            "redisplay",
            "show_hide",
            "size",
            "strerror",
            "stub",
            "stub_hints",
            "update",
            "view",
            "world",
            "local_copy_paste",
            "remote_copy_paste",
            "timer",
        });
    }

    pugl.addCSourceFiles(.{
        .root = pugl_dep.path("src"),
        .files = &.{
            b.fmt("{s}.{s}", .{ @tagName(platform), c_src_ext }),
            "common.c",
            "internal.c",
        },
        .flags = c_flags.items,
    });

    b.installArtifact(pugl);

    const run_tests_step = b.step("test", "Run tests");

    const unit_tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = pugl_module,
    });
    unit_tests.linkLibrary(pugl);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_tests_step.dependOn(&run_unit_tests.step);

    for (tests.items) |test_name| {
        const test_exe = b.addExecutable(.{
            .name = b.fmt("test_{s}", .{test_name}),
            .target = target,
            .optimize = optimize,
        });
        test_exe.addCSourceFile(.{ .file = pugl_dep.path(b.fmt("test/test_{s}.c", .{test_name})) });
        test_exe.linkLibrary(pugl);

        const run_test = b.addRunArtifact(test_exe);
        run_tests_step.dependOn(&run_test.step);
    }

    const docs_step = b.step("docs", "Build API docs");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = pugl.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);
}
