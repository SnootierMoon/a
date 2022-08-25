pub const Mesh = struct {};

pub const MeshFace = packed struct {
    mat: u32,
    x: u5,
    y: u5,
    z: u5,
    w: u5,
    h: u5,
    face: u3,
};
