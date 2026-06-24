const std = @import("std");
const Io = std.Io;
const math = std.math;

const root = @import("root.zig");
const vector = @This();
const netpbm = root.netpbm;

// REFLECTION HELPERS //

pub fn Child(V: type) type {
    return @typeInfo(V).vector.child;
}
pub fn len(V: type) comptime_int {
    return @typeInfo(V).vector.len;
}

// CONSTRUCTORS //

pub fn basis(V: type, i: usize) V {
    var output: [len(V)]Child(V) = @splat(0);
    output[i] = 1;
    return output;
}

// ARITHMETIC //

pub fn add(lhs: anytype, rhs: anytype) @TypeOf(lhs, rhs) {
    return lhs + rhs;
}
pub fn subtract(lhs: anytype, rhs: anytype) @TypeOf(lhs, rhs) {
    return lhs - rhs;
}
pub fn scalarMultiply(v: anytype, c: Child(@TypeOf(v))) @TypeOf(v) {
    return v * @as(@TypeOf(v), @splat(c));
}
pub fn scalarDivide(v: anytype, c: Child(@TypeOf(v))) @TypeOf(v) {
    return v / @as(@TypeOf(v), @splat(c));
}
pub fn dotProduct(lhs: anytype, rhs: anytype) Child(@TypeOf(lhs, rhs)) {
    return @reduce(.Add, lhs * rhs);
}
pub fn normSquared(v: anytype) Child(@TypeOf(v)) {
    return vector.dotProduct(v, v);
}
pub fn norm(v: anytype) Child(@TypeOf(v)) {
    return @sqrt(vector.normSquared(v));
}
pub fn normalize(v: anytype) error{NormZero}!@TypeOf(v) {
    const n = vector.norm(v);
    return if (n == 0)
        error.NormZero
    else
        vector.scalarDivide(v, n);
}
pub fn crossProduct(lhs: anytype, rhs: anytype) @TypeOf(lhs, rhs) {
    if (len(@TypeOf(lhs, rhs)) != 3) @compileError("");
    return .{
        lhs[1] * rhs[2] - lhs[2] * rhs[1],
        lhs[2] * rhs[0] - lhs[0] * rhs[2],
        lhs[0] * rhs[1] - lhs[1] * rhs[0],
    };
}

// COLOR HELPERS //

pub fn percentOfInteger(v: anytype, I: type) @Vector(len(@TypeOf(v)), I) {
    const V = @TypeOf(v);
    const percent_0: V = @splat(0);
    const percent_100: V = @splat(1);
    const max: V = @splat(math.maxInt(I));
    const clamped: V = math.clamp(v, percent_0, percent_100);
    return @trunc(max * clamped);
}
pub fn writeAsNetpbmColor(color: anytype, w: *Io.Writer, header: netpbm.Header) !void {
    const Color = @TypeOf(color);
    const Channel = Child(Color);
    const channel_count = len(Color);
    const ColorArray = switch (channel_count) {
        3, 4 => [channel_count]Channel,
        else => @compileError(""),
    };
    const encoding = header.format_tag.encoding();
    const upper_channel: Channel = @intCast(header.max_value);
    const lower_channel: Channel = @intCast(0);
    const upper_color: Color = @splat(upper_channel);
    const lower_color: Color = @splat(lower_channel);
    const clamped: Color = math.clamp(color, lower_color, upper_color);
    switch (encoding) {
        .binary => try w.writeAll(&@as(ColorArray, clamped)),
        .ascii => try w.print("{d} {d} {d}\n", .{ clamped[0], clamped[1], clamped[2] }),
    }
}

/// A wrapper around `@Vector(n, E)` with functions for construction and common math operations from `root.vector`
pub fn R(n: comptime_int, E: type) type {
    return struct {
        elements: Elements,

        const Self = @This();
        pub const Elements = @Vector(n, E);

        // CONSTRUCTORS //

        pub fn new(elements: Elements) Self {
            return .{ .elements = elements };
        }
        pub fn splat(e: E) Self {
            return new(@splat(e));
        }
        pub fn zero() Self {
            return splat(0);
        }
        pub fn ones() Self {
            return splat(1);
        }
        pub fn basis(i: usize) Self {
            return new(vector.basis(Elements, i));
        }
        pub fn x_basis() Self {
            return .basis(0);
        }
        pub fn y_basis() Self {
            return .basis(1);
        }
        pub fn z_basis() Self {
            return .basis(2);
        }

        // CONVERSION //
        pub fn toArray(self: Self) [n]E {
            return self.elements;
        }

        // GETTERS //

        pub fn get(self: Self, element_index: anytype) E {
            return self.toArray()[element_index];
        }
        pub fn x(self: Self) E {
            return self.get(0);
        }
        pub fn y(self: Self) E {
            return self.get(1);
        }
        pub fn z(self: Self) E {
            return self.get(2);
        }

        // ARITHMETIC //

        pub fn add(lhs: Self, rhs: Self) Self {
            return new(vector.add(lhs.elements, rhs.elements));
        }
        pub fn subtract(lhs: Self, rhs: Self) Self {
            return new(vector.subtract(lhs.elements, rhs.elements));
        }
        pub fn scalarMultiply(lhs: Self, rhs: E) Self {
            return new(vector.scalarMultiply(lhs.elements, rhs));
        }
        pub fn scalarDivide(lhs: Self, rhs: E) Self {
            return new(vector.scalarDivide(lhs.elements, rhs));
        }
        pub fn dotProduct(lhs: Self, rhs: Self) void {
            return new(vector.dotProduct(lhs.elements, rhs.elements));
        }
        pub fn normSquared(self: Self) E {
            return vector.normSquared(self.elements);
        }
        pub fn norm(self: Self) E {
            return vector.norm(self.elements);
        }
        pub fn normalize(self: Self) error{NormZero}!Self {
            return new(try vector.normalize(self.elements));
        }

        // COLOR HELPERS //

        pub const red = x;
        pub const green = y;
        pub const blue = z;
        pub fn percentOfInteger(self: Self, I: type) R(n, I) {
            return R(n, I).new(vector.percentOfInteger(self.elements, I));
        }
        pub fn writeAsNetpbmColor(self: Self, w: *Io.Writer, header: netpbm.Header) !void {
            try vector.writeAsNetpbmColor(self.elements, w, header);
        }
    };
}
