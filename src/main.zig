const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;
const log = std.log;

const root = @import("ray_tracing_in_one_weekend");
const R3 = root.R3;
const Rgb = root.Rgb;
const Ray = root.Ray;
const rayColor = root.rayColor;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(io, "output/ray0.ppm", .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    var output = &writer.interface;

    // Image
    const ideal_aspect_ratio = 16.0 / 9.0;
    const image_width = 400;
    const image_height = a: {
        const image_height: comptime_int = @as(comptime_float, image_width) / ideal_aspect_ratio;
        break :a if (image_height < 1) 1 else image_height;
    };

    // Camera
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(comptime_float, image_width) / @as(comptime_float, image_height));
    const camera_center = R3.zero;

    // calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_x = R3.x_hat.scalarMultiply(viewport_width);
    const viewport_y = R3.y_hat.scalarMultiply(-image_height);

    // calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_x = viewport_x.scalarDivide(image_width);
    const pixel_delta_y = viewport_y.scalarDivide(image_height);

    // calculate the location of the top left pixel
    const viewport_top_left = camera_center
        .subtract(&R3.z_hat.scalarMultiply(focal_length))
        .subtract(&viewport_x.subtract(&viewport_y).scalarDivide(2));
    const top_left_pixel_center = viewport_top_left
        .add(&pixel_delta_x.add(&pixel_delta_y).scalarDivide(2));

    // Render
    try output.print("P3\n{d} {d}\n{d}\n", .{ image_width, image_height, maxInt(u8) });
    try output.flush();

    for (0..image_height) |row_index| {
        const row_index_f: f64 = @floatFromInt(row_index);

        log.info("\rScanlines remaining: {d}", .{image_height - row_index});

        for (0..image_width) |column_index| {
            const column_index_f: f64 = @floatFromInt(column_index);

            const pixel_center = top_left_pixel_center
                .add(&pixel_delta_x.scalarMultiply(column_index_f))
                .add(&pixel_delta_y.scalarMultiply(row_index_f));
            const ray_direction = pixel_center.subtract(&camera_center);
            const r = Ray{ .direction = ray_direction, .origin = camera_center };

            const pixel_color = rayColor(&r);
            try output.print("{f}", .{pixel_color});
            try output.flush();
        }
    }

    log.info("\rdone ", .{});

    try output.print("", .{});
    try output.flush();
}
