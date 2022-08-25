pub const ChunkIndex = @import("voxel/coord.zig").ChunkIndex;
pub const ChunkCoord = @import("voxel/coord.zig").ChunkCoord;
pub const VoxelCoord = @import("voxel/coord.zig").VoxelCoord;
pub const Mesh = @import("voxel/mesh.zig").Mesh;
pub const MeshFace = @import("voxel/mesh.zig").MeshFace;

pub const air = Voxel{ .id = 0 };

pub const Voxel = struct {
    id: u32,
};
