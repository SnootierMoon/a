pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);
pub const Mat3 = [9]f32;
pub const Mat4 = [16]f32;

pub fn zero(comptime T: type) T {
    return switch (T) {
        Vec2 => .{ 0, 0 },
        Vec3 => .{ 0, 0, 0 },
        Vec4 => .{ 0, 0, 0, 0 },
        Mat3 => .{0} ** 9,
        Mat4 => .{0} ** 16,
        else => @compileError("Unsupported type for zero"),
    };
}

pub fn cross(x: Vec3, y: Vec3) Vec3 {
    const ret1 = @shuffle(f32, x, undefined, .{ 1, 2, 0 });
    ret1 *= @shuffle(f32, y, undefined, .{ 2, 0, 1 });
    const ret2 = @shuffle(f32, y, undefined, .{ 1, 2, 0 });
    ret2 *= @shuffle(f32, x, undefined, .{ 2, 0, 1 });
    return ret1 - ret2;
}

pub fn dot(x: anytype, y: @TypeOf(x)) f32 {
    return @reduce(.Add, x * y);
}

pub fn length(x: anytype) f32 {
    return @sqrt(dot(x, x));
}

pub fn normalize(x: anytype) @TypeOf(x) {
    const dims = @typeInfo(@TypeOf(x)).Vector.len;
    return x / @splat(dims, length(x));
}

pub fn transpose(mat: anytype) @TypeOf(mat) {
    return switch (@TypeOf(mat)) {
        Mat3 => .{
            mat[0], mat[3], mat[6],
            mat[1], mat[4], mat[7],
            mat[2], mat[5], mat[8],
        },
        Mat4 => .{
            mat[0], mat[4], mat[8],  mat[12],
            mat[1], mat[5], mat[9],  mat[13],
            mat[2], mat[6], mat[10], mat[14],
            mat[3], mat[7], mat[11], mat[15],
        },
        else => @compileError("Unsupported type for transpose"),
    };
}

pub fn MulType(comptime x: type, comptime y: type) type {
    if (x == Mat3 and y == Vec3) {
        return Vec3;
    } else if (x == Mat4 and y == Vec4) {
        return Vec4;
    } else if (x == Mat3 and y == Mat3) {
        return Mat3;
    } else if (x == Mat4 and y == Mat4) {
        return Mat4;
    } else {
        @compileError("Unsupported types for MulType");
    }
}

pub fn mul(x: anytype, y: anytype) MulType(@TypeOf(x), @TypeOf(y)) {
    if (@TypeOf(x) == Mat3 and @TypeOf(y) == Vec3) {
        return .{
            dot(@as(Vec3, x[0..3].*), y),
            dot(@as(Vec3, x[3..6].*), y),
            dot(@as(Vec3, x[6..9].*), y),
        };
    } else if (@TypeOf(x) == Mat4 and @TypeOf(y) == Vec4) {
        return .{
            dot(y, @as(Vec4, x[0..4].*)),
            dot(y, @as(Vec4, x[4..8].*)),
            dot(y, @as(Vec4, x[8..12].*)),
            dot(y, @as(Vec4, x[12..16].*)),
        };
    } else if (@TypeOf(x) == Mat3 and @TypeOf(y) == Mat3) {
        var ret = @as(Mat3, undefined);
        const t = transpose(y);
        ret[0..3].* = mul(t, @as(Vec3, x[0..3].*));
        ret[3..6].* = mul(t, @as(Vec3, x[3..6].*));
        ret[6..9].* = mul(t, @as(Vec3, x[6..9].*));
        return ret;
    } else if (@TypeOf(x) == Mat4 and @TypeOf(y) == Mat4) {
        var ret = @as(Mat4, undefined);
        const t = transpose(y);
        ret[0..4].* = mul(t, @as(Vec4, x[0..4].*));
        ret[4..8].* = mul(t, @as(Vec4, x[4..8].*));
        ret[8..12].* = mul(t, @as(Vec4, x[8..12].*));
        ret[12..16].* = mul(t, @as(Vec4, x[12..16].*));
        return ret;
    } else @compileError("Unsupported types for mul");
}

pub fn translation(x: f32, y: f32, z: f32) Mat4 {
    return .{
        1.0, 0.0, 0.0, x,
        0.0, 1.0, 0.0, y,
        0.0, 0.0, 1.0, z,
        0.0, 0.0, 0.0, 1.0,
    };
}

pub const Camera = struct {
    fov_y: f32,
    aspect_ratio: f32,
    yaw: f32,
    pitch: f32,
    pos: Vec3,

    const z_near = 0.1;

    pub fn projection(self: Camera) Mat4 {
        const scale_y = 1.0 / @tan(self.fov_y * 0.5);
        const scale_x = scale_y / self.aspect_ratio;
        return .{
            scale_x, 0.0,     0.0,  0.0,
            0.0,     scale_y, 0.0,  0.0,
            0.0,     0.0,     -1.0, -2.0 * z_near,
            0.0,     0.0,     -1.0, 0.0,
        };
    }

    pub fn view(self: Camera) Mat4 {
        const cos_yaw = @cos(self.yaw);
        const sin_yaw = @sin(self.yaw);
        const cos_pitch = @cos(self.pitch);
        const sin_pitch = @sin(self.pitch);
        const cam_x = Vec3{ sin_yaw, -cos_yaw, 0 }; // right
        const cam_y = Vec3{ -cos_yaw * sin_pitch, -sin_yaw * sin_pitch, cos_pitch }; // up
        const cam_z = Vec3{ -cos_yaw * cos_pitch, -sin_yaw * cos_pitch, -sin_pitch }; // backwards
        return .{
            cam_x[0], cam_x[1], cam_x[2], dot(cam_x, self.pos),
            cam_y[0], cam_y[1], cam_y[2], dot(cam_y, self.pos),
            cam_z[0], cam_z[1], cam_z[2], dot(cam_z, self.pos),
            0.0,      0.0,      0.0,      1.0,
        };
    }

    pub fn draw_matrix(self: Camera) Mat4 {
        return mul(self.projection(), self.view());
    }

    pub fn move_matrix(self: Camera) Mat3 {
        const cos_yaw = @cos(self.yaw);
        const sin_yaw = @sin(self.yaw);
        return .{
            cos_yaw, -sin_yaw, 0.0,
            sin_yaw, cos_yaw,  0.0,
            0.0,     0.0,      1.0,
        };
    }
};
