const std = @import("std");
const Io = std.Io;
const math = std.math;
const Child = std.meta.Child;

const root = @import("root.zig");
const vector = @This();
const netpbm = root.netpbm;
const staticAssert = root.staticAssert;
const isFloat = root.isFloat;
const isInteger = root.isInteger;
const isVector = root.isVector;

pub fn len(V: type) ret_ty: {
    staticAssert(isVector(V));
    break :ret_ty comptime_int;
} {
    return @typeInfo(V).vector.len;
}

pub fn basis(n: comptime_int, E: type, i: usize) @Vector(n, E) {
    var output: [n]E = @splat(0);
    output[i] = 1;
    return output;
}

pub fn add(lhs: anytype, rhs: anytype) ret_ty: {
    const V = @TypeOf(lhs, rhs);
    staticAssert(isVector(V));
    break :ret_ty V;
} {
    return lhs + rhs;
}

pub fn subtract(lhs: anytype, rhs: anytype) ret_ty: {
    const V = @TypeOf(lhs, rhs);
    staticAssert(isVector(V));
    break :ret_ty V;
} {
    return lhs - rhs;
}

pub fn scalarMultiply(v: anytype, c: anytype) ret_ty: {
    const V = @TypeOf(v);
    const C = @TypeOf(c);
    staticAssert(isVector(V));
    staticAssert(C == Child(V));
    break :ret_ty V;
} {
    return v * @as(@TypeOf(v), @splat(c));
}

pub fn scalarDivide(v: anytype, c: anytype) ret_ty: {
    const V = @TypeOf(v);
    const C = @TypeOf(c);
    staticAssert(isVector(V));
    staticAssert(C == Child(V));
    break :ret_ty V;
} {
    return v / @as(@TypeOf(v), @splat(c));
}

pub fn dotProduct(lhs: anytype, rhs: anytype) ret_ty: {
    const T = @TypeOf(lhs, rhs);
    staticAssert(isVector(T));
    break :ret_ty Child(T);
} {
    return @reduce(.Add, lhs * rhs);
}

pub fn crossProduct(lhs: anytype, rhs: anytype) ret_ty: {
    const T = @TypeOf(lhs, rhs);
    staticAssert(isVector(T));
    staticAssert(len(T) == 3);
    break :ret_ty T;
} {
    return .{
        lhs[1] * rhs[2] - lhs[2] * rhs[1],
        lhs[2] * rhs[0] - lhs[0] * rhs[2],
        lhs[0] * rhs[1] - lhs[1] * rhs[0],
    };
}

pub fn normSquared(v: anytype) ret_ty: {
    const V = @TypeOf(v);
    staticAssert(isVector(V));
    break :ret_ty Child(V);
} {
    return vector.dotProduct(v, v);
}

pub fn norm(v: anytype) ret_ty: {
    const V = @TypeOf(v);
    staticAssert(isVector(V));
    break :ret_ty Child(V);
} {
    return @sqrt(vector.normSquared(v));
}

pub fn normalize(v: anytype) error{NormZero}!ret_ty: {
    const V = @TypeOf(v);
    staticAssert(isVector(V));
    break :ret_ty V;
} {
    const n = vector.norm(v);
    return if (n == 0)
        error.NormZero
    else
        vector.scalarDivide(v, n);
}

pub fn percentOfInteger(v: anytype, I: type) ret_ty: {
    const V = @TypeOf(v);
    staticAssert(isVector(V));
    staticAssert(isFloat(Child(V)));
    staticAssert(isInteger(I));
    break :ret_ty @Vector(len(V), I);
} {
    const T = @TypeOf(v);
    const percent_0: T = @splat(0);
    const percent_100: T = @splat(1);
    const max: T = @splat(math.maxInt(I));
    const clamped: T = math.clamp(v, percent_0, percent_100);
    return @trunc(max * clamped);
}

pub fn writeAsNetpbmColor(
    color: anytype,
    w: *Io.Writer,
    header: netpbm.Header,
) !ret_ty: {
    const Color = @TypeOf(color);
    staticAssert(isVector(Color));
    staticAssert(len(Color) >= 3); // reg, green, blue
    const Channel = Child(Color);
    staticAssert(isInteger(Channel));
    break :ret_ty void;
} {
    const Color = @TypeOf(color);
    const Channel = Child(Color);
    const encoding = header.format_tag.encoding();
    const upper_channel: Channel = @intCast(header.max_value);
    const lower_channel: Channel = @intCast(0);
    const upper_color: Color = @splat(upper_channel);
    const lower_color: Color = @splat(lower_channel);
    const clamped: Color = math.clamp(color, lower_color, upper_color);
    switch (encoding) {
        .binary => try w.writeAll(&@as([len(Color)]Channel, clamped)),
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
            return new(vector.basis(n, E, i));
        }
        pub fn x_basis() Self {
            return Self.basis(0);
        }
        pub fn y_basis() Self {
            return Self.basis(1);
        }
        pub fn z_basis() Self {
            return Self.basis(2);
        }

        // GETTERS //

        pub fn get(self: Self, i: anytype) ret_ty: {
            staticAssert(isInteger(@TypeOf(i)));
            break :ret_ty E;
        } {
            return @as([n]E, self.elements)[i];
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
            return new(vector.normSquared(self.elements));
        }
        pub fn norm(self: Self) E {
            return new(vector.norm(self.elements));
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
