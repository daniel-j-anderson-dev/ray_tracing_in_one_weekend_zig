const std = @import("std");
const Io = std.Io;
const math = std.math;

pub const R = f64;

pub const R3 = struct {
    x: R,
    y: R,
    z: R,

    pub const zero = R3{ .x = 0, .y = 0, .z = 0 };
    pub const ones = R3{ .x = 1, .y = 1, .z = 1 };
    pub const x_hat = R3{ .x = 1, .y = 0, .z = 0 };
    pub const y_hat = R3{ .x = 0, .y = 1, .z = 0 };
    pub const z_hat = R3{ .x = 0, .y = 0, .z = 1 };

    pub fn add(lhs: *const R3, rhs: *const R3) R3 {
        return .{
            .x = lhs.x + rhs.x,
            .y = lhs.y + rhs.y,
            .z = lhs.z + rhs.z,
        };
    }

    pub fn subtract(lhs: *const R3, rhs: *const R3) R3 {
        return .{
            .x = lhs.x - rhs.x,
            .y = lhs.y - rhs.y,
            .z = lhs.z - rhs.z,
        };
    }

    pub fn scalarMultiply(self: *const R3, c: R) R3 {
        return .{
            .x = self.x * c,
            .y = self.y * c,
            .z = self.z * c,
        };
    }

    pub fn scalarDivide(self: *const R3, c: R) R3 {
        return .{
            .x = self.x / c,
            .y = self.y / c,
            .z = self.z / c,
        };
    }

    pub fn dotProduct(lhs: *const R3, rhs: *const R3) R {
        return lhs.x * rhs.x +
            lhs.y * rhs.y +
            lhs.z * rhs.z;
    }

    pub fn crossProduct(lhs: *const R3, rhs: *const R3) R3 {
        return .{
            .x = lhs.y * rhs.z - lhs.z * rhs.y,
            .y = lhs.z * rhs.x - lhs.x * rhs.z,
            .z = lhs.x * rhs.y - lhs.y * rhs.x,
        };
    }

    pub fn normSquared(self: *const R3) R {
        return self.dotProduct(self);
    }

    pub fn norm(self: *const R3) R {
        return @sqrt(self.normSquared());
    }

    pub fn normalize(self: *const R3) error{NormZero}!R3 {
        const n = self.norm();
        return if (n == 0)
            error.NormZero
        else
            self.scalarDivide(n);
    }

    pub fn format(self: *const R3, w: *Io.Writer) Io.Writer.Error!void {
        try w.print("({d}, {d}, {d})", .{ self.x, self.y, self.z });
    }
};
