const m = @import("root").linmath;

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

pub const ChunkCoord = packed struct {
    x: i27,
    y: i27,
    z: i27,

    pub fn center(self: ChunkCoord) m.DVec3 {
        return .{
            @intToFloat(f64, self.x << 5 | 16),
            @intToFloat(f64, self.y << 5 | 16),
            @intToFloat(f64, self.z << 5 | 16),
        };
    }
};

pub const VoxelCoord = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn fromChunkCoord(chunk_coord: ChunkCoord, chunk_index: ChunkIndex) VoxelCoord {
        return .{
            .x = chunk_coord.x << 5 | chunk_index.x,
            .y = chunk_coord.y << 5 | chunk_index.y,
            .z = chunk_coord.z << 5 | chunk_index.z,
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

    pub fn center(self: VoxelCoord) m.DVec3 {
        return .{
            @intToFloat(f64, self.x),
            @intToFloat(f64, self.y),
            @intToFloat(f64, self.z),
        } + @splat(3, 0.5);
    }

    pub fn dist(self: VoxelCoord, other: VoxelCoord) f64 {
        return m.length(self.center() - other.center());
    }
};
