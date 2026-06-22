const std = @import("std");
const Io = std.Io;
const math = std.math;
const maxInt = std.math.maxInt;

const root = @import("root.zig");
const netpbm = root.netpbm;

pub fn Rgb(T: type) type {
    return struct {
        red: T,
        green: T,
        blue: T,

        pub fn splat(t: T) @This() {
            return .{
                .red = t,
                .green = t,
                .blue = t
            };
        }

        pub fn add(lhs: *const @This(), rhs: *const @This()) @This() {
            return .{
                .red = lhs.red + rhs.red,
                .green = lhs.green + rhs.green,
                .blue = lhs.blue + rhs.blue,
            };
        }

        pub fn subtract(lhs: *const @This(), rhs: *const @This()) @This() {
            return .{
                .red = lhs.red - rhs.red,
                .green = lhs.green - rhs.green,
                .blue = lhs.blue - rhs.blue,
            };
        }

        pub fn scalarMultiply(self: *const @This(), t: T) @This() {
            return .{
                .red = self.red * t,
                .green = self.green * t,
                .blue = self.blue * t,
            };
        }

        pub fn scalarDivide(self: *const @This(), t: T) @This() {
            return .{
                .red = self.red / t,
                .green = self.green / t,
                .blue = self.blue / t,
            };
        }

        pub fn toArray(self: *const @This()) [3]T {
            return .{ self.red, self.green, self.blue };
        }

        pub fn clamp(self: *const @This(), lower: T, upper: T) @This() {
            return .{
                .red = math.clamp(self.red, lower, upper),
                .green = math.clamp(self.green, lower, upper),
                .blue = math.clamp(self.blue, lower, upper),
            };
        }

        pub fn percentToInt(self: *const @This(), I: type) Rgb(I) {
            const max: comptime_float = maxInt(I);
            const clamped = self.clamp(0.0, 1.0);
            return .{
                .red = @as(I, @trunc(max * clamped.red)),
                .green = @as(I, @trunc(max * clamped.green)),
                .blue = @as(I, @trunc(max * clamped.blue)),
            };
        }

        pub fn writeNetpbm(self: *const @This(), header: *const netpbm.Header, w: *Io.Writer) !void {
            const encoding = header.format_tag.encoding();
            const max: T = @intCast(header.max_value);
            switch (encoding) {
                .binary => try w.writeAll(&self.clamp(0, max).toArray()),
                .ascii => {
                    const clamped = self.clamp(0, max);
                    try w.print(
                        "{d} {d} {d}\n",
                        .{ clamped.red, clamped.green, clamped.blue },
                    );
                },
            }
        }
    };
}
