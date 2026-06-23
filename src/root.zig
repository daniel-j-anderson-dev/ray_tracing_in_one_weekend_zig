pub const netpbm = @import("netpbm.zig");
pub const vector = @import("vector.zig");
pub const ray = @import("ray.zig");
pub const examples = @import("examples.zig");

pub const Ray = ray.Ray;

pub fn Rgb(Channel: type) type {
    return vector.R(3, Channel);
}

pub fn staticAssert(comptime b: bool) void {
    if (b) {} else @compileError("staticAssert failed");
}
pub fn isFloat(T: type) bool {
    return switch (@typeInfo(T)) {
        .float, .comptime_float => true,
        else => false,
    };
}
pub fn isInteger(T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .comptime_int => true,
        else => false,
    };
}
pub fn isVector(T: type) bool {
    return switch (@typeInfo(T)) {
        .vector => true,
        else => false,
    };
}
