const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;
const log = std.log;

const root = @import("ray_tracing_in_one_weekend");
const R3 = root.R3;
const Rgb = root.Rgb;
const Ray = root.Ray;
const examples = root.examples;
const netpbm = root.netpbm;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();

    // print args
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }
}
