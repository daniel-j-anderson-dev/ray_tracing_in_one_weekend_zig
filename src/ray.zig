const root = @import("root.zig");
const R3 = root.vector.R(3, f64);

const R = f64;

pub const Ray = struct {
    origin: R3,
    direction: R3,

    pub fn new(origin: R3, direction: R3) Ray {
        return .{ .origin = origin, .direction = direction };
    }

    pub fn at(self: *const @This(), t: f64) R3 {
        return self.origin.add(self.direction.scalarMultiply(t));
    }
};
