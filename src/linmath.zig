const std = @import("std");

fn VecMixin(comptime V: type) type {
    const Internal = @TypeOf(@as(V, undefined).data);
    const dims = @typeInfo(Internal).Vector.len;

    return struct {
        pub fn dot(self: V, other: V) f32 {
            return @reduce(.Add, self.data * other.data);
        }

        pub fn length(self: V) f32 {
            return @sqrt(dot(self, self));
        }

        pub fn normalized(self: V) V {
            return .{ .data = self.data / @splat(dims, length(self)) };
        }
    };
}

pub const Vec3 = struct {
    data: @Vector(3, f32),
    pub usingnamespace VecMixin(Vec3);

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .data = .{ x, y, z } };
    }

    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        const ret1 = @shuffle(f32, self, undefined, .{ 1, 2, 0 });
        ret1 *= @shuffle(f32, other, undefined, .{ 2, 0, 1 });
        const ret2 = @shuffle(f32, other, undefined, .{ 1, 2, 0 });
        ret2 *= @shuffle(f32, self, undefined, .{ 2, 0, 1 });
        return ret1 - ret2;
    }
};

pub const Vec4 = struct {
    data: @Vector(4, f32),
    pub usingnamespace VecMixin(Vec4);

    pub fn init(x: f32, y: f32, z: f32, w: f32) Vec3 {
        return .{ .data = .{ x, y, z, w } };
    }
};

pub const Mat4 = struct {
    data: [16]f32,

    pub const zero = Mat4{ .data = [_]f32{0.0} ** 16 };
    pub const identity = Mat4{ .data = [_]f32{ 1.0, 0.0, 0.0, 0.0, 0.0 } ** 3 ++ [_]f32{1.0} };

    pub fn rotationXY(angle: f32) Mat4 {
        var ret = Mat4.zero;
        ret.data[0] = @cos(angle);
        ret.data[1] = @sin(angle);
        ret.data[4] = -ret.data[1];
        ret.data[5] = ret.data[0];
        ret.data[10] = 1;
        ret.data[15] = 1;
        return ret;
    }
};
