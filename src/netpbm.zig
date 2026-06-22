const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;

pub const Encoding = enum {
    binary,
    ascii,
};

pub const Format = enum {
    P1,
    P2,
    P3,
    P4,
    P5,
    P6,

    pub fn encoding(self: @This()) Encoding {
        return switch (self) {
            .P1, .P2, .P3 => .ascii,
            .P4, .P5, .P6 => .binary,
        };
    }
};

pub const Header = struct {
    format_tag: Format,
    image_height: u32,
    image_width: u32,
    max_value: u16,

    pub fn format(self: *const @This(), w: *Io.Writer) !void {
        try w.print(
            "{s}\n{d} {d}\n{d}\n",
            .{
                @tagName(self.format_tag),
                self.image_width,
                self.image_height,
                self.max_value,
            },
        );
    }
};

test "print header" {
    std.debug.print("\n\n", .{});

    const header = Header{
        .format_tag = .P6,
        .image_height = 10,
        .image_width = 10,
        .max_value = 1,
    };
    var buffer: [64]u8 = undefined;
    var output_file = Io.File.stderr();
    var output_file_writer = output_file.writer(std.testing.io, &buffer);
    const output = &output_file_writer.interface;

    try output.print("{f}", .{header});
    try output.flush();

    std.debug.print("\n\n", .{});
}
