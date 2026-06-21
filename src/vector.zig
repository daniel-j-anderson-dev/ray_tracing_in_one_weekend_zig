const std = @import("std");
const Io = std.Io;
const math = std.math;

pub const R = f64;
const scalar = struct {
    fn subtract(lhs: R, rhs: R) R {
        return lhs - rhs;
    }

    fn add(lhs: R, rhs: R) R {
        return lhs + rhs;
    }

    fn multiply(lhs: R) fn (R) R {
        return struct {
            pub fn f(rhs: R) R {
                return lhs * rhs;
            }
        }.f;
    }

    fn divide(lhs: R) fn (R) R {
        return struct {
            pub fn f(rhs: R) R {
                return lhs / rhs;
            }
        }.f;
    }
};

pub const R3 = struct {
    x: R,
    y: R,
    z: R,

    pub const zero = R3{ .x = 0, .y = 0, .z = 0 };
    pub const ones = R3{ .x = 1, .y = 1, .z = 1 };
    pub const x_hat = R3{ .x = 1, .y = 0, .z = 0 };
    pub const y_hat = R3{ .x = 0, .y = 1, .z = 0 };
    pub const z_hat = R3{ .x = 0, .y = 0, .z = 1 };

    pub fn elementWiseBinaryOperation(
        lhs: *const R3,
        rhs: *const R3,
        binOp: fn (R, R) R,
    ) R3 {
        return .{
            .x = binOp(lhs.x, rhs.x),
            .y = binOp(lhs.y, rhs.y),
            .z = binOp(lhs.z, rhs.z),
        };
    }

    pub fn elementWiseMap(self: *const R3, f: fn (f64) f64) R3 {
        return .{
            .x = f(self.x),
            .y = f(self.y),
            .z = f(self.z),
        };
    }

    pub fn subtract(lhs: *const R3, rhs: *const R3) R3 {
        return lhs.elementWiseBinaryOperation(rhs, scalar.subtract);
    }

    pub fn add(lhs: *const R3, rhs: *const R3) R3 {
        return lhs.elementWiseBinaryOperation(rhs, scalar.add);
    }

    pub fn scalarMultiply(self: *const R3, c: R) R3 {
        return self.elementWiseMap(scalar.multiply(c));
    }

    pub fn scalarDivide(self: *const R3, c: R) R3 {
        return self.elementWiseMap(scalar.divide(c));
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
        return switch (self.norm()) {
            0 => error.NormZero,
            else => |n| self.scalarDivide(n),
        };
    }

    pub fn format(self: *const R3, w: *Io.Writer) Io.Writer.Error!void {
        try w.print("({d}, {d}, {d})", .{ self.x, self.y, self.z });
    }
};

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
test "a" {
    std.debug.print("\n\n", .{});
    const expected = R3.ones;
    const actual = R3.x_hat.add(&R3.y_hat).add(&R3.z_hat);
    try expectEqual(expected, actual);
    try expectEqual(0.0, R3.x_hat.dotProduct(&R3.y_hat));
    std.debug.print("{f}", .{R3.x_hat});
    std.debug.print("\n\n", .{});
    _ = R3;
}
