const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "pugl_cairo_demo",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
        }),
    });

    const pugl = b.dependency("pugl", .{
        .target = target,
        .optimize = optimize,
        .cairo = true,
    });

    exe.root_module.addImport("pugl", pugl.module("pugl"));
    exe.root_module.addImport("backend_cairo", pugl.module("backend_cairo"));

    const cairo_headers = pugl.namedLazyPath("cairo_headers");
    const translate_c = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = cairo_headers.path(b, "cairo.h"),
    });
    translate_c.addIncludePath(cairo_headers);
    exe.root_module.addImport("cairo_c", translate_c.createModule());

    b.installArtifact(exe);
}
