const std = @import("std");
const Io = std.Io;

pub const netpbm = @import("netpbm.zig");
pub const vector = @import("vector.zig");
pub const ray = @import("ray.zig");
pub const examples = @import("examples.zig");
pub const Ray = ray.Ray;

pub const color = struct {
    pub fn Rgb(Channel: type) type {
        return vector.R(3, Channel);
    }
};

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
