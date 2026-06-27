const std = @import("std");
const Io = std.Io;
const math = std.math;

pub const netpbm = @import("netpbm.zig");
pub const vector = @import("vector.zig");
pub const ray = @import("ray.zig");
pub const examples = @import("examples.zig");
pub const Ray = ray.Ray;

pub fn Rgb(Channel: type) type {
    return vector.R(3, Channel);
}
fn channelMax(Channel: type) Channel {
    return switch (@typeInfo(Channel)) {
        .int, .comptime_int => math.maxInt(Channel),
        .float, .comptime_float => 1.0,
        else => @compileError("expected float or int type. found: " ++ @tagName(Channel)),
    };
}
pub fn colors(Channel: type) type {
    const max = channelMax(Channel);
    return struct {
        pub const Color = Rgb(Channel);
        pub const red = Color.basis(0).scale(max);
        pub const green = Color.basis(1).scale(max);
        pub const blue = Color.basis(2).scale(max);
    };
}

pub const all_examples = a: {
    const decls = @typeInfo(examples).@"struct".decls;
    var temp: [decls.len]type = undefined;
    for (0.., decls) |i, decl| {
        temp[i] = @field(examples, decl.name);
    }
    break :a temp;
};

pub fn save_example(io: Io, example: type) !void {
    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(io, example.default.path, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const output = &writer.interface;
    try example.write(output, .{});
    try output.flush();
}
