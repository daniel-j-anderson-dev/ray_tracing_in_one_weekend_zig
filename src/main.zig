const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;
const log = std.log;

const root = @import("ray_tracing_in_one_weekend");
const examples = root.examples;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [1024]u8 = undefined;
    inline for (examples.all) |example| {
        var file = try Io.Dir.cwd().createFile(io, example.default.path, .{});
        defer file.close(io);
        var writer = file.writer(io, &buffer);
        const output = &writer.interface;

        std.log.info("generating {s}...", .{example.default.path});
        try example.write(output, .{});
        std.log.info("Done", .{});
    }
}
