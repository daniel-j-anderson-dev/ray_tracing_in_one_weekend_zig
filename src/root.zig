pub const vector = @import("vector.zig");
pub const color = @import("color.zig");
pub const ray = @import("ray.zig");
pub const examples = @import("examples.zig");

pub const R3 = vector.R3;
pub const Rgb = color.Rgb;
pub const Ray = ray.Ray;

pub fn rayColor(r: *const Ray) Rgb(u8) {
    _ = r;
    return .{ .red = 0, .green = 0, .blue = 0 };
}
