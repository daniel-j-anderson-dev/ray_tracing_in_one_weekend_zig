const std = @import("std");
const Io = std.Io;
const math = std.math;

const root = @import("root.zig");
const netpbm = root.netpbm;
const R = f64;
const R3 = root.vector.R(3, R);
const Rgb = root.color.Rgb;
const Ray = root.Ray;
const save = root.save_example;

const examples = @This();

fn default_path(Example: type) []const u8 {
    return "output/" ++ @typeName(Example) ++ ".ppm";
}

pub const red_green_gradient = struct {
    pub const default = struct {
        pub const path = default_path(@This());
        pub const header = netpbm.Header{
            .format_tag = .P6,
            .image_height = 256,
            .image_width = 256,
            .max_value = math.maxInt(u8),
        };
    };
    pub fn pixelColor(
        row_index: usize,
        column_index: usize,
        image_width: u32,
        image_height: u32,
    ) Rgb(u8) {
        const image_height_f: R = @floatFromInt(image_height);
        const image_width_f: R = @floatFromInt(image_width);
        const row_index_f: R = @floatFromInt(row_index);
        const column_index_f: R = @floatFromInt(column_index);

        const color = Rgb(R).new(.{
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
test red_green_gradient {
    try save(std.testing.io, red_green_gradient);
}

pub const blue_gradient = struct {
    pub const default = struct {
        pub const path = default_path(@This());

        pub const ideal_aspect_ratio = 16.0 / 9.0;
        pub const image_width = 400;
        pub const image_height = a: {
            const h: comptime_int = @as(comptime_float, image_width) / ideal_aspect_ratio;
            break :a if (h < 1) 1 else h;
        };
        pub const actual_aspect_ratio = @as(comptime_float, image_width) / @as(comptime_float, image_height);

        pub const focal_length = 1.0;
        pub const viewport_height = 2.0;
        pub const viewport_width = viewport_height * actual_aspect_ratio;
        pub const camera_center = R3.zero();

        pub const viewport_x = R3.x_basis().scalarMultiply(viewport_width);
        pub const viewport_y = R3.y_basis().scalarMultiply(-viewport_height);
        pub const pixel_delta_x = viewport_x.scalarDivide(image_width);
        pub const pixel_delta_y = viewport_y.scalarDivide(image_height);
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
            .max_value = math.maxInt(u8),
        };
    };
    pub fn rayColor(ray: Ray) Rgb(u8) {
        const direction = ray.direction.normalize() catch R3.zero();
        const a = (direction.y() + 1.0) / 2.0;

        const start = Rgb(R).splat(1.0);
        const end = Rgb(R).new(.{ 0.5, 0.7, 1.0 });

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
        const camera_center = args.camera_center;

        try output.print("{f}", .{header});
        try output.flush();
        for (0..image_height) |row_index| {
            for (0..image_width) |column_index| {
                const pixel_center = top_left_pixel_center
                    .add(pixel_delta_x.scalarMultiply(@floatFromInt(column_index)))
                    .add(pixel_delta_y.scalarMultiply(@floatFromInt(row_index)));

                const pixel_to_camera = pixel_center.subtract(camera_center);

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
test blue_gradient {
    try save(std.testing.io, blue_gradient);
}

pub const red_sphere_no_shading = struct {
    pub const default = struct {
        pub const path = default_path(@This());
        pub const header = blue_gradient.default.header;
        pub const camera_center = blue_gradient.default.camera_center;
        pub const pixel_delta_x = blue_gradient.default.pixel_delta_x;
        pub const pixel_delta_y = blue_gradient.default.pixel_delta_y;
        pub const top_left_pixel_center = blue_gradient.default.top_left_pixel_center;
    };
    pub const Sphere = struct {
        radius: R,
        center: R3,

        pub const RayCollision = enum { secant, tangent };

        /// the expression `vⁿ` means dot product of `v` with itself `n` times
        /// ```text
        /// vⁿ ≔ |v·v· ⋯ ·v|
        ///      +---------+
        ///          |
        ///      n times
        /// ```
        ///
        /// Sphere equation
        /// ```text
        /// (C - P)² = r²
        /// C is the center point of the sphere
        /// P is an arbitrary point in space
        /// r is the radius of sphere
        /// ```
        /// - if `(C - P)² = r²`
        ///   - then `P` is considered on the surface of the sphere
        ///
        /// Ray equation
        /// ```text
        /// P(t) = Q + t·d̂
        /// d̂ is the direction of the ray
        /// Q is the origin of the ray
        /// P(t) is a specific point along the ray
        /// ```
        ///
        /// we want to determine a ray intersects with a sphere. <br/>
        /// we want to find all solutions for t where this equation is true
        /// ```text
        ///   (C - P(t))²                                 = r²
        /// ⇒ (C - ( Q + t·d̂))²                           = r² `substitute: P(t) = Q + d̂·t`
        /// ⇒ (C + (-Q + -t·d̂))²                          = r² `distribute -1`
        /// ⇒ (C +  -Q + -t·d̂)²                           = r² `remove parentheses ∵ addition is vector associative`
        /// ⇒ (C + -Q + -t·d̂)·(C + -Q + -t·d̂)             = r² `expand norm squared`
        /// ⇒ (-t·d̂ + (C - Q))·(-t·d̂ + (C - Q))           = r² `regroup by t ∵ addition is vector associative and commutative`
        /// ⇒ t²·d̂² - t·2·d̂·(C - Q) + (C - Q)²            = r² `foil the dot product`
        /// ⇒ t²·d̂² - t·2·d̂·(C - Q) + (C - Q)² - r²       = 0  `move r² to the left side`
        /// ⇒ t²·d̂² - t¹·2·d̂·(C - Q) + t⁰·((C - Q)² - r²) = 0  `put polynomial in normal form`
        /// ⇒ (-b ± √(4·a·c)) / 2·a                       = t  `use quadratic formula to solve for t`
        ///   a = d̂²
        ///   b = 2·d̂·(C - Q)
        ///   c = (C - Q)² - r²
        /// ⇒ (-(2·d̂·(C - Q)) ± √(4·d̂²·((C - Q)² - r²)) / 2·d̂² = t
        /// ```
        /// - if there are two real solutions to `t`
        ///   - then the ray intersects the sphere twice
        /// - if there is one real solution to `t`
        ///   - then the ray intersects the sphere once
        /// - if there are no real solution to `t`
        ///   - then the ray does not intersect the sphere
        ///
        /// The discriminant of the quadratic formula is the part under the radical (`4·a·c`).
        /// - if the discriminant is positive (`4·a·c > 0`)
        ///   - then there are two real solutions
        /// - if the discriminant is zero (`4·a·c = 0`)
        ///   - then there is one real solution
        /// - if the discriminant is negative (`4·a·c < 0`)
        ///   - then there are no real solutions
        ///
        /// ![](https://raytracing.github.io/images/fig-1.05-ray-sphere.jpg)
        pub fn rayCollision(sphere: Sphere, ray: Ray) ?Sphere.RayCollision {
            // move the center of the sphere to the origin of the ray.
            // C - Q
            const offset_center = sphere.center.subtract(ray.origin);

            // quadratic coefficients
            const a = ray.direction.normSquared();
            const b = 2.0 * ray.direction.dotProduct(offset_center);
            const c = offset_center.normSquared() - (sphere.radius * sphere.radius);

            const discriminant = (b * b) - (4 * a * c);
            return switch (math.sign(discriminant)) {
                -1 => null,
                0 => .tangent,
                1 => .secant,
                else => unreachable, // math.sign returns -1, 0, 1
            };
        }
    };
};
