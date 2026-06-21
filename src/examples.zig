const std = @import("std");
const Io = std.Io;
const log = std.log;
const maxInt = std.math.maxInt;

const root = @import("root.zig");
const Rgb = root.Rgb;

pub fn write_red_green_gradient_ppm(
    args: struct {
        output: *Io.Writer,
        image_width: u32,
        image_height: u32,
    },
) !void {
    const output = args.output;
    const image_width = args.image_width;
    const image_height = args.image_height;
    const image_height_f: f64 = @floatFromInt(image_height);
    const image_width_f: f64 = @floatFromInt(image_width);

    try output.print("P3\n{d} {d}\n{d}\n", .{ image_width, image_height, maxInt(u8) });
    try output.flush();

    for (0..image_height) |row_index| {
        const row_index_f: f64 = @floatFromInt(row_index);

        log.info("\rScanlines remaining: {d}", .{image_height - row_index});

        for (0..image_width) |column_index| {
            const column_index_f: f64 = @floatFromInt(column_index);

            const color = Rgb(f64).percentToInt(
                .{
                    .red = column_index_f / (image_width_f - 1),
                    .green = row_index_f / (image_height_f - 1),
                    .blue = 0,
                },
                u8,
            );

            try output.print("{f}\n", .{color});
            try output.flush();
        }
    }

    log.info("\rdone ", .{});
}
