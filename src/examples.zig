const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;

const root = @import("root.zig");
const netpbm = root.netpbm;
const R3 = root.vector.R(3, f64);
const Rgb = root.Rgb;
const Ray = root.Ray;

pub fn writeRedGreenGradientPpm(
    args: struct {
        output: *Io.Writer,
        header: netpbm.Header,
    },
) !void {
    const pixelColor = struct {
        pub fn f(
            row_index: anytype,
            column_index: anytype,
            image_width: anytype,
            image_height: anytype,
        ) Rgb(u8) {
            const image_height_f: f64 = @floatFromInt(image_height);
            const image_width_f: f64 = @floatFromInt(image_width);
            const row_index_f: f64 = @floatFromInt(row_index);
            const column_index_f: f64 = @floatFromInt(column_index);

            const color = Rgb(f64).new(.{
                column_index_f / (image_width_f - 1),
                row_index_f / (image_height_f - 1),
                0,
            });

            return color.percentOfInteger(u8);
        }
    }.f;

    // unwrap args tuple
    const output = args.output;
    const header = args.header;
    const image_width = header.image_width;
    const image_height = header.image_height;

    try output.print("{f}", .{header});
    try output.flush();
    for (0..image_height) |row_index| {
        for (0..image_width) |column_index| {
            const color = pixelColor(row_index, column_index, image_width, image_height);
            try color.writeAsNetpbmColor(output, header);
            try output.flush();
        }
    }
}
test writeRedGreenGradientPpm {
    const io = std.testing.io;
    const path = "output/red_green_gradient.ppm";
    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(io, path, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const output = &writer.interface;

    const header = netpbm.Header{
        .format_tag = .P6,
        .image_height = 256,
        .image_width = 256,
        .max_value = maxInt(u8),
    };
    try writeRedGreenGradientPpm(.{
        .output = output,
        .header = header,
    });
    try output.flush();
}

pub fn writeBlueGradient(
    args: struct {
        output: *Io.Writer,
        header: netpbm.Header,
        top_left_pixel_center: R3,
        pixel_delta_x: R3,
        pixel_delta_y: R3,
        camera_center: R3,
    },
) !void {
    const rayColor = struct {
        /// blendedValue = ((1−a)⋅startValue) + (a ⋅ endValue)
        pub fn f(r: Ray) Rgb(u8) {
            const r_direction_hat = r.direction.normalize() catch R3.zero();
            const a = (r_direction_hat.y() + 1.0) / 2.0;

            const start = Rgb(f64).splat(1.0);
            const end = Rgb(f64).new(.{ 0.5, 0.7, 1.0 });

            const scaled_start = start.scalarMultiply(1 - a);
            const scaled_end = end.scalarMultiply(a);

            const color = scaled_start.add(scaled_end);

            return color.percentOfInteger(u8);
        }
    }.f;

    // unwrap args tuple
    const output = args.output;
    const header = args.header;
    const image_width = header.image_width;
    const image_height = header.image_height;
    const top_left_pixel_center = args.top_left_pixel_center;
    const pixel_delta_x = args.pixel_delta_x;
    const pixel_delta_y = args.pixel_delta_y;
    const camera_center = args.camera_center;

    try output.print("{f}", .{header});
    try output.flush();

    for (0..image_height) |row_index| {
        for (0..image_width) |column_index| {
            const pixel_center = top_left_pixel_center
                .add(pixel_delta_x.scalarMultiply(@floatFromInt(column_index)))
                .add(pixel_delta_y.scalarMultiply(@floatFromInt(row_index)));
            const pixel_to_camera = pixel_center.subtract(camera_center);
            const ray = Ray{ .origin = pixel_center, .direction = pixel_to_camera };
            const color = rayColor(ray);
            try color.writeAsNetpbmColor(output, header);
            try output.flush();
        }
    }
}
test writeBlueGradient {
    std.debug.print("\n\n", .{});

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
    const camera_center = R3.zero();

    // calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_x = R3.x_basis().scalarMultiply(viewport_width);
    const viewport_y = R3.y_basis().scalarMultiply(-viewport_height);

    // calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_x = viewport_x.scalarDivide(image_width);
    const pixel_delta_y = viewport_y.scalarDivide(image_height);

    // calculate the location of the top left pixel
    const viewport_top_left = camera_center
        .subtract(R3.z_basis().scalarMultiply(focal_length))
        .subtract(viewport_x.scalarDivide(2))
        .subtract(viewport_y.scalarDivide(2));
    const top_left_pixel_center = viewport_top_left
        .add(pixel_delta_x.add(pixel_delta_y).scalarDivide(2));

    // file
    const io = std.testing.io;
    const path = "output/raycast_blue_gradient.ppm";
    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(std.testing.io, path, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const output = &writer.interface;

    try writeBlueGradient(.{
        .output = output,
        .header = .{
            .format_tag = .P3,
            .image_height = image_height,
            .image_width = image_width,
            .max_value = maxInt(u8),
        },
        .camera_center = camera_center,
        .top_left_pixel_center = top_left_pixel_center,
        .pixel_delta_x = pixel_delta_x,
        .pixel_delta_y = pixel_delta_y,
    });
    try output.flush();

    std.debug.print("\n\n", .{});
}
