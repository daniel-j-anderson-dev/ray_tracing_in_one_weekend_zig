const std = @import("std");
const Io = std.Io;

const ray_tracing_in_one_weekend = @import("ray_tracing_in_one_weekend");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    try stdout_writer.print("hello {s}\n", .{"🌎"});
    try stdout_writer.flush();
}
// pub fn 
