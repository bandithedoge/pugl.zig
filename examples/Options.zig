const std = @import("std");

error_checking: bool = false,
resizable: bool = false,
anti_aliasing: bool = false,
double_buffer: bool = true,
vsync: bool = false,
continuous: bool = true,
ignore_key_repeat: bool = false,

const Options = @This();

pub fn parse(init: std.process.Init) !Options {
    var stdout = std.Io.File.stdout().writer(init.io, &.{});
    const writer = &stdout.interface;

    var options: Options = .{};

    var arg_iterator = init.minimal.args.iterate();
    _ = arg_iterator.skip();

    while (arg_iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "-e"))
            options.error_checking = true
        else if (std.mem.eql(u8, arg, "-r"))
            options.resizable = true
        else if (std.mem.eql(u8, arg, "-a"))
            options.anti_aliasing = true
        else if (std.mem.eql(u8, arg, "-d"))
            options.double_buffer = false
        else if (std.mem.eql(u8, arg, "-s"))
            options.vsync = true
        else if (std.mem.eql(u8, arg, "-b"))
            options.continuous = false
        else if (std.mem.eql(u8, arg, "-i"))
            options.ignore_key_repeat = true
        else if (std.mem.eql(u8, arg, "-h")) {
            try Options.printHelp(init, writer);
            std.process.exit(0);
        } else {
            try writer.print("Invalid argument: {s}\n\n", .{arg});
            try Options.printHelp(init, writer);
            std.process.exit(1);
        }
    }

    return options;
}

pub fn printHelp(init: std.process.Init, writer: *std.Io.Writer) !void {
    var args = init.minimal.args.iterate();
    try writer.print(
        \\Usage: {s} [OPTION]...
        \\
        \\-e  Enable platform error-checking
        \\-r  Resizable window
        \\-a  Enable anti-aliasing
        \\-d  Directly draw to window (no double-buffering)
        \\-s  Explicitly enable vertical sync
        \\-b  Block and only update on user input
        \\-i  Ignore key repeat
        \\-h  Display this help
        \\
    , .{args.next().?});
}
