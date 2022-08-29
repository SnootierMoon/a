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

// 0 1
// 2 3
//
// 4 5
// 6 7

pub const cube_edges = struct {
    pub const verts = [24]f32{
        0.0, 0.0, 0.0,
        0.0, 0.0, 1.0,
        0.0, 1.0, 0.0,
        0.0, 1.0, 1.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 1.0,
        1.0, 1.0, 0.0,
        1.0, 1.0, 1.0,
    };

    pub const indices = [24]u32{
        0, 1,
        1, 3,
        3, 2,
        2, 0,
        4, 5,
        5, 7,
        7, 6,
        6, 4,
        0, 4,
        1, 5,
        3, 7,
        6, 2,
    };
};
