const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;

const ray_tracing_in_one_weekend = @import("ray_tracing_in_one_weekend");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout();
    var stdout_file_writer = stdout_file.writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    const stdout = stdout_writer;

    const image_width = 256;
    const image_height = 256;

    try write_red_green_gradient_ppm(stdout, image_width, image_height);
}

pub fn write_red_green_gradient_ppm(w: *Io.Writer, image_width: u32, image_height: u32) !void {
    try w.print("P3\n{d} {d}\n{d}\n", .{ image_width, image_height, maxInt(u8) });
    try w.flush();

    for (0..image_height) |row_index| {
        for (0..image_width) |column_index| {
            const image_height_f: f64 = @floatFromInt(image_height);
            const image_width_f: f64 = @floatFromInt(image_width);
            const row_index_f: f64 = @floatFromInt(row_index);
            const column_index_f: f64 = @floatFromInt(column_index);

            const percent_red = column_index_f / (image_width_f - 1);
            const percent_green = row_index_f / (image_height_f - 1);
            const percent_blue = 0.0;

            const scale = 255.999;
            const red: u8 = @trunc(scale * percent_red);
            const green: u8 = @trunc(scale * percent_green);
            const blue: u8 = @trunc(scale * percent_blue);

            try w.print("{d} {d} {d}\n", .{ red, green, blue });
            try w.flush();
        }
    }
}
