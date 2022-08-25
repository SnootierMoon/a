const m = @import("root").linmath;
const ChunkCoord = @import("root").voxel.ChunkCoord;

pub const Camera = struct {
    fov_y: f32,
    aspect_ratio: f32,
    yaw: f32,
    pitch: f32,
    pos: m.Vec3,

    root: ChunkCoord,
    view_proj: m.Mat4 = undefined,

    const z_near = 0.1;

    pub fn calcViewProj(self: *Camera) void {
        const projection = m.transform.perspective(z_near, self.fov_y, self.aspect_ratio);
        const view = m.transform.look(self.pos, self.yaw, self.pitch);
        self.view_proj = m.mat4.mulMat(projection, view);
    }

    pub fn mvp(self: *Camera, chunk_coord: ChunkCoord) m.Mat4 {
        const x = @intToFloat(f32, (chunk_coord.x - self.root.x) << 5);
        const y = @intToFloat(f32, (chunk_coord.y - self.root.y) << 5);
        const z = @intToFloat(f32, (chunk_coord.z - self.root.z) << 5);
        const model = m.transform.translation(x, y, z);
        return m.mat4.mulMat(self.view_proj, model);
    }

    pub fn move(self: *Camera, vel: m.Vec3) void {
        self.pos += m.mat3.mulVec(m.mat3.rotationXY(self.yaw), vel);
    }
};
