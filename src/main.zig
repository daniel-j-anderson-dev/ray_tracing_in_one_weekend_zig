const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;
const log = std.log;

const ray_tracing_in_one_weekend = @import("ray_tracing_in_one_weekend");
const Rgb = ray_tracing_in_one_weekend.color.Rgb;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(io, "output/red_green.ppm", .{});
    var writer = file.writer(io, &buffer);

    try write_red_green_gradient_ppm(.{
        .image_height = 256,
        .image_width = 256,
        .output = &writer.interface,
    });
}

const WriteRedGreenGradientArgs = struct {
    output: *Io.Writer,
    image_width: u32,
    image_height: u32,
};
fn write_red_green_gradient_ppm(args: WriteRedGreenGradientArgs) !void {
    const output: *Io.Writer = args.output;
    const image_width: u32 = args.image_width;
    const image_height: u32 = args.image_height;
    const image_height_f: f64 = @floatFromInt(image_height);
    const image_width_f: f64 = @floatFromInt(image_width);

    try output.print("P3\n{d} {d}\n{d}\n", .{ image_width, image_height, maxInt(u8) });
    try output.flush();

    for (0..image_height) |row_index| {
        const row_index_f: f64 = @floatFromInt(row_index);

        log.info("\rScanlines remaining: {d}", .{image_height - row_index});

        for (0..image_width) |column_index| {
            const column_index_f: f64 = @floatFromInt(column_index);

            const percent_color = Rgb(f64){
                .red = column_index_f / (image_width_f - 1),
                .green = row_index_f / (image_height_f - 1),
                .blue = 0,
            };
            const color = percent_color.percentToInt(u8);

            try output.print("{f}\n", .{color});
            try output.flush();
        }
    }

    log.info("\rdone ", .{});
}
