const std = @import("std");
const Io = std.Io;
const maxInt = std.math.maxInt;

const root = @import("root.zig");
const netpbm = root.netpbm;
const R3 = root.vector.R(3, f64);
const Rgb = root.color.Rgb;
const Ray = root.Ray;

pub const red_green_gradient = struct {
    pub const default = struct {
        pub const header = netpbm.Header{
            .format_tag = .P6,
            .image_height = 256,
            .image_width = 256,
            .max_value = maxInt(u8),
        };
    };
    pub fn pixelColor(
        row_index: usize,
        column_index: usize,
        image_width: u32,
        image_height: u32,
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
    pub fn write(
        output: *Io.Writer,
        args: struct { header: netpbm.Header = default.header },
    ) !void {
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
};
test "red_green_gradient.write" {
    const io = std.testing.io;
    const path = "output/red_green_gradient.ppm";
    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(io, path, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const output = &writer.interface;
    try red_green_gradient.write(output, .{});
    try output.flush();
}

pub const blue_gradient = struct {
    const default = struct {
        // Image
        pub const ideal_aspect_ratio = 16.0 / 9.0;
        pub const image_width = 400;
        pub const image_height = a: {
            const h: comptime_int = @as(comptime_float, image_width) / ideal_aspect_ratio;
            break :a if (h < 1) 1 else h;
        };
        pub const actual_aspect_ratio = @as(comptime_float, image_width) / @as(comptime_float, image_height);

        // Camera
        pub const focal_length = 1.0;
        pub const viewport_height = 2.0;
        pub const viewport_width = viewport_height * actual_aspect_ratio;
        pub const camera_center = R3.zero();

        // calculate the vectors across the horizontal and down the vertical viewport edges
        pub const viewport_x = R3.x_basis().scalarMultiply(viewport_width);
        pub const viewport_y = R3.y_basis().scalarMultiply(-viewport_height);

        // calculate the horizontal and vertical delta vectors from pixel to pixel.
        pub const pixel_delta_x = viewport_x.scalarDivide(image_width);
        pub const pixel_delta_y = viewport_y.scalarDivide(image_height);

        // calculate the location of the top left pixel
        pub const viewport_top_left = camera_center
            .subtract(R3.z_basis().scalarMultiply(focal_length))
            .subtract(viewport_x.scalarDivide(2))
            .subtract(viewport_y.scalarDivide(2));
        pub const top_left_pixel_center = viewport_top_left
            .add(pixel_delta_x.scalarDivide(2))
            .add(pixel_delta_y.scalarDivide(2));

        pub const header = netpbm.Header{
            .format_tag = .P3,
            .image_height = image_height,
            .image_width = image_width,
            .max_value = maxInt(u8),
        };
    };
    pub fn rayColor(ray: Ray) Rgb(u8) {
        const direction = ray.direction.normalize() catch R3.zero();
        const a = (direction.y() + 1.0) / 2.0;

        const start = Rgb(f64).splat(1.0);
        const end = Rgb(f64).new(.{ 0.5, 0.7, 1.0 });

        const scaled_start = start.scalarMultiply(1 - a);
        const scaled_end = end.scalarMultiply(a);

        const color = scaled_start.add(scaled_end);

        return color.percentOfInteger(u8);
    }
    pub fn write(
        output: *Io.Writer,
        args: struct {
            header: netpbm.Header = default.header,
            top_left_pixel_center: R3 = default.top_left_pixel_center,
            pixel_delta_x: R3 = default.pixel_delta_x,
            pixel_delta_y: R3 = default.pixel_delta_y,
            camera_center: R3 = default.camera_center,
        },
    ) !void {
        const header = args.header;
        const image_width = header.image_width;
        const image_height = header.image_height;
        const top_left_pixel_center = args.top_left_pixel_center;
        const pixel_delta_x = args.pixel_delta_x;
        const pixel_delta_y = args.pixel_delta_y;
        const camera_center_ = args.camera_center;

        try output.print("{f}", .{header});
        try output.flush();
        for (0..image_height) |row_index| {
            for (0..image_width) |column_index| {
                const pixel_center = top_left_pixel_center
                    .add(pixel_delta_x.scalarMultiply(@floatFromInt(column_index)))
                    .add(pixel_delta_y.scalarMultiply(@floatFromInt(row_index)));
                const pixel_to_camera = pixel_center.subtract(camera_center_);
                const ray = Ray{
                    .origin = pixel_center,
                    .direction = pixel_to_camera,
                };
                const color = rayColor(ray);
                try color.writeAsNetpbmColor(output, header);
                try output.flush();
            }
        }
    }
};
test "blue_gradient.write" {
    // file
    const io = std.testing.io;
    const path = "output/raycast_blue_gradient.ppm";
    var buffer: [1024]u8 = undefined;
    var file = try Io.Dir.cwd().createFile(std.testing.io, path, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const output = &writer.interface;
    try blue_gradient.write(output, .{});
    try output.flush();
}
