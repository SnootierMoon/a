pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);

pub const DVec3 = @Vector(3, f32);

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

pub fn cross(lhs: Vec3, rhs: Vec3) Vec3 {
    const ret1 = @shuffle(f32, lhs, undefined, .{ 1, 2, 0 });
    ret1 *= @shuffle(f32, rhs, undefined, .{ 2, 0, 1 });
    const ret2 = @shuffle(f32, rhs, undefined, .{ 1, 2, 0 });
    ret2 *= @shuffle(f32, lhs, undefined, .{ 2, 0, 1 });
    return ret1 - ret2;
}

pub fn dot(lhs: anytype, rhs: @TypeOf(lhs)) f32 {
    return @reduce(.Add, lhs * rhs);
}

pub fn length(vec: anytype) f32 {
    return @sqrt(dot(vec, vec));
}

pub fn normalize(vec: anytype) @TypeOf(vec) {
    const dims = @typeInfo(@TypeOf(vec)).Vector.len;
    return vec / @splat(dims, length(vec));
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

pub fn MulType(comptime lhs: type, comptime rhs: type) type {
    if (lhs == Mat3 and rhs == Vec3) {
        return Vec3;
    } else if (lhs == Mat4 and rhs == Vec4) {
        return Vec4;
    } else if (lhs == Mat3 and rhs == Mat3) {
        return Mat3;
    } else if (lhs == Mat4 and rhs == Mat4) {
        return Mat4;
    } else {
        @compileError("Unsupported types for MulType");
    }
}

pub fn mul(lhs: anytype, rhs: anytype) MulType(@TypeOf(lhs), @TypeOf(rhs)) {
    if (@TypeOf(lhs) == Mat3 and @TypeOf(rhs) == Vec3) {
        return mat3.mulVec(lhs, rhs);
    } else if (@TypeOf(lhs) == Mat3 and @TypeOf(rhs) == Mat3) {
        return mat3.mulMat(lhs, rhs);
    } else if (@TypeOf(lhs) == Mat4 and @TypeOf(rhs) == Vec4) {
        return mat4.mulVec(lhs, rhs);
    } else if (@TypeOf(lhs) == Mat4 and @TypeOf(rhs) == Mat4) {
        return mat4.mulMat(lhs, rhs);
    } else @compileError("Unsupported types for mul");
}

pub const mat3 = struct {
    pub fn mulVec(lhs: Mat3, rhs: Vec3) Vec3 {
        return .{
            dot(@as(Vec3, lhs[0..3].*), rhs),
            dot(@as(Vec3, lhs[3..6].*), rhs),
            dot(@as(Vec3, lhs[6..9].*), rhs),
        };
    }

    pub fn mulMat(lhs: Mat3, rhs: Mat3) Mat3 {
        var ret = @as(Mat3, undefined);
        const t = transpose(rhs);
        ret[0..3].* = mulVec(t, lhs[0..3].*);
        ret[3..6].* = mulVec(t, lhs[3..6].*);
        ret[6..9].* = mulVec(t, lhs[6..9].*);
        return ret;
    }
};

pub const mat4 = struct {
    pub fn mulVec(lhs: Mat4, rhs: Vec4) Vec4 {
        return .{
            dot(rhs, @as(Vec4, lhs[0..4].*)),
            dot(rhs, @as(Vec4, lhs[4..8].*)),
            dot(rhs, @as(Vec4, lhs[8..12].*)),
            dot(rhs, @as(Vec4, lhs[12..16].*)),
        };
    }

    pub fn mulMat(lhs: Mat4, rhs: Mat4) Mat4 {
        var ret = @as(Mat4, undefined);
        const t = transpose(rhs);
        ret[0..4].* = mulVec(t, lhs[0..4].*);
        ret[4..8].* = mulVec(t, lhs[4..8].*);
        ret[8..12].* = mulVec(t, lhs[8..12].*);
        ret[12..16].* = mulVec(t, lhs[12..16].*);
        return ret;
    }
};

pub const transform = struct {
    pub fn perspective(z_near: f32, fov_y: f32, aspect_ratio: f32) Mat4 {
        const scale_y = 1.0 / @tan(fov_y * 0.5);
        const scale_x = scale_y / aspect_ratio;
        return .{
            scale_x, 0.0,     0.0,  0.0,
            0.0,     scale_y, 0.0,  0.0,
            0.0,     0.0,     -1.0, -2.0 * z_near,
            0.0,     0.0,     -1.0, 0.0,
        };
    }

    pub fn look(pos: Vec3, yaw: f32, pitch: f32) Mat4 {
        const cos_yaw = @cos(yaw);
        const sin_yaw = @sin(yaw);
        const cos_pitch = @cos(pitch);
        const sin_pitch = @sin(pitch);
        const cam_x = Vec3{ sin_yaw, -cos_yaw, 0 }; // right
        const cam_y = Vec3{ -cos_yaw * sin_pitch, -sin_yaw * sin_pitch, cos_pitch }; // up
        const cam_z = Vec3{ -cos_yaw * cos_pitch, -sin_yaw * cos_pitch, -sin_pitch }; // backwards
        return .{
            cam_x[0], cam_x[1], cam_x[2], dot(cam_x, pos),
            cam_y[0], cam_y[1], cam_y[2], dot(cam_y, pos),
            cam_z[0], cam_z[1], cam_z[2], dot(cam_z, pos),
            0.0,      0.0,      0.0,      1.0,
        };
    }
};

pub const Camera = struct {
    fov_y: f32,
    aspect_ratio: f32,
    yaw: f32,
    pitch: f32,
    pos: Vec3,

    const z_near = 0.1;

    pub fn drawMat(self: Camera) Mat4 {
        const projection = transform.perspective(z_near, self.fov_y, self.aspect_ratio);
        const view = transform.look(self.pos, self.yaw, self.pitch);
        return mat4.mulMat(projection, view);
    }

    pub fn moveMat(self: Camera) Mat3 {
        const cos_yaw = @cos(self.yaw);
        const sin_yaw = @sin(self.yaw);
        return .{
            cos_yaw, -sin_yaw, 0.0,
            sin_yaw, cos_yaw,  0.0,
            0.0,     0.0,      1.0,
        };
    }
};
