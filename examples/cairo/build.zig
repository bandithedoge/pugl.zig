const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "pugl_cairo_demo",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    const pugl = b.dependency("pugl", .{
        .target = target,
        .optimize = optimize,
        .cairo = true,
        // use this option if you want to use your own or installed version of cairo
        // .build_cairo = false,
    });

    exe.root_module.addImport("pugl", pugl.module("pugl"));
    exe.root_module.addImport("backend_cairo", pugl.module("backend_cairo"));

    // the pugl static library includes cairo headers
    exe.linkLibrary(pugl.artifact("pugl"));

    b.installArtifact(exe);
}
