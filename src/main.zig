const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;
const log = std.log;

const root = @import("ray_tracing_in_one_weekend");
const all_examples = root.all_examples;
const save_example = root.save_example;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    inline for (all_examples) |example| {
        std.log.info("generating {s} ...", .{example.default.path});
        try save_example(io, example);
        std.log.info("Done", .{});
    }
}
