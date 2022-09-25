const std = @import("std");
const ChunkCoord = @import("coord.zig").ChunkCoord;
const Chunk = @import("chunk.zig").Chunk;

pub const Object = struct {
    chunks: std.AutoHashMap(ChunkCoord, Chunk),
};
