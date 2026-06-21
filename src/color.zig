const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;

pub fn Rgb(T: type) type {
    return switch (T) {
        f64 => struct {
            red: T,
            green: T,
            blue: T,

            pub fn percentToInt(self: *const @This(), I: type) Rgb(I) {
                const max = maxInt(I);
                return .{
                    .red = @trunc(max * self.red),
                    .green = @trunc(max * self.green),
                    .blue = @trunc(max * self.blue),
                };
            }
        },
        else => a: {
            const info: std.builtin.Type = @typeInfo(T);
            break :a switch (info) {
                .int, .comptime_int => struct {
                    red: T,
                    green: T,
                    blue: T,

                    pub fn format(self: *const @This(), w: *Io.Writer) !void {
                        try w.print("{d} {d} {d}", .{ self.red, self.green, self.blue });
                    }
                },
                else => struct {
                    red: T,
                    green: T,
                    blue: T,
                },
            };
        },
    };
}

const print = std.debug.print;
const expect = std.testing.expect;
test "printin" {
    print("\n\n", .{});
    const color = Rgb(f64){
        .red = 1.0,
        .green = 0,
        .blue = 0,
    };
    print("\n\n", .{});
    print("{f}\n", .{color.percentToInt(u8)});
    print("\n\n", .{});
}
