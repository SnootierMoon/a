const m = @import("../linmath.zig");

pub const ChunkIndex = packed struct {
    x: u5,
    y: u5,
    z: u5,

    pub fn fromNum(num: u15) ChunkIndex {
        return @bitCast(ChunkIndex, num);
    }

    pub fn toNum(self: ChunkIndex) usize {
        return @bitCast(u15, self);
    }
};

pub const ChunkCoord = struct {
    x: i27,
    y: i27,
    z: i27,

    pub fn minBound(self: ChunkCoord) m.DVec3 {
        return .{
            @intToFloat(f64, self.x),
            @intToFloat(f64, self.y),
            @intToFloat(f64, self.z),
        } * m.splat3(32.0);
    }

    pub fn maxBound(self: ChunkCoord) m.DVec3 {
        return self.minBound() + m.splat3(32.0);
    }

    pub fn center(self: ChunkCoord) m.DVec3 {
        return self.minBound() + m.splat3(16.0);
    }
};

pub const VoxelCoord = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn fromChunkCoord(chunk_coord: ChunkCoord, chunk_index: ChunkIndex) VoxelCoord {
        return .{
            .x = @as(i32, chunk_coord.x) << 5 | chunk_index.x,
            .y = @as(i32, chunk_coord.y) << 5 | chunk_index.y,
            .z = @as(i32, chunk_coord.z) << 5 | chunk_index.z,
        };
    }

    pub fn chunkIndex(self: VoxelCoord) ChunkIndex {
        return .{
            .x = self.x & 31,
            .y = self.y & 31,
            .z = self.z & 31,
        };
    }

    pub fn chunkCoord(self: VoxelCoord) ChunkCoord {
        return .{
            .x = self.x >> 5,
            .y = self.y >> 5,
            .z = self.z >> 5,
        };
    }

    pub fn center(self: ChunkCoord) m.DVec3 {
        return .{
            @intToFloat(f64, self.x),
            @intToFloat(f64, self.y),
            @intToFloat(f64, self.z),
        };
    }

    pub fn distance(self: VoxelCoord, other: VoxelCoord) f64 {
        return m.length(self.center() - other.center());
    }
};
