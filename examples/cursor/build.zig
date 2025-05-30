const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "pugl_cursor_demo",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    const pugl = b.dependency("pugl", .{
        .target = target,
        .optimize = optimize,
        .opengl = true,
    });

    exe.root_module.addImport("pugl", pugl.module("pugl"));
    exe.root_module.addImport("backend_opengl", pugl.module("backend_opengl"));

    const gl = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"3.3",
        .profile = .compatibility,
    });

    exe.root_module.addImport("gl", gl);

    b.installArtifact(exe);
}
