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
