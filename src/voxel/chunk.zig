pub const Voxel = @import("root").voxel.Voxel;

pub const edge_len = 32;
pub const face_area = 32 * 32;
pub const volume = 32 * 32 * 32;

pub const Chunk = struct {
    voxels: [volume]Voxel,

    fn initEmpty() Chunk {
        return .{
            .voxels = [_]Voxel{Voxel.air} ** volume,
        };
    }
};
