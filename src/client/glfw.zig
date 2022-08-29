const std = @import("std");
const m = @import("../linmath.zig");
const Camera = @import("../camera.zig").Camera;
pub const cube_edges = @import("../voxel/mesh.zig").cube_edges;
pub const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub const win_width = 800;
pub const win_height = 600;
pub const movement_speed = 10.0;

const log = std.log.scoped(.glfw);

pub const Platform = struct {
    allocator: std.mem.Allocator,

    window: *c.GLFWwindow,

    voxel_shader: Shader,
    voxel_vao: c.GLuint,
    voxel_uniform_mvp: Shader.Uniform(m.Mat4),

    cursor_pos: ?m.Vec2,
    current_time: f32,
    delta_time: f32,

    cube_mesh_shader: Shader,
    cube_mesh_uniform_mvp: Shader.Uniform(m.Mat4),
    cube_mesh_vao: c.GLuint,
    cube_mesh_vbo: c.GLuint,
    cube_mesh_ebo: c.GLuint,

    camera: Camera,

    pub fn init(allocator: std.mem.Allocator) !*Platform {
        var self = try allocator.create(Platform);
        errdefer allocator.destroy(self);
        self.allocator = allocator;

        if (c.glfwInit() == c.GLFW_FALSE) {
            log.err("Failed to initialize GLFW: {s}", .{getGlfwError().?});
            return error.GlfwInitFailed;
        }
        errdefer c.glfwTerminate();
        _ = c.glfwSetErrorCallback(errorCallback);

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
        self.window = c.glfwCreateWindow(win_width, win_height, "Test Window", null, null) orelse {
            log.err("Failed to create window: {s}", .{getGlfwError().?});
            return error.GlfwWindowCreateFailed;
        };
        errdefer c.glfwDestroyWindow(self.window);

        c.glfwSetWindowUserPointer(self.window, self);
        _ = c.glfwSetFramebufferSizeCallback(self.window, framebufferSizeCallback);
        _ = c.glfwSetKeyCallback(self.window, keyCallback);
        _ = c.glfwSetCursorPosCallback(self.window, cursorPosCallback);
        c.glfwSetInputMode(self.window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

        c.glfwMakeContextCurrent(self.window);
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
            log.err("Failed to load OpenGL with GLAD", .{});
            return error.GladInitFailed;
        }

        c.glEnable(c.GL_DEPTH_TEST);
        c.glEnable(c.GL_CULL_FACE);

        var vaos = @as([2]c.GLuint, undefined);
        c.glGenVertexArrays(vaos.len, &vaos);
        errdefer c.glDeleteVertexArrays(vaos.len, &vaos);

        var xbos = @as([2]c.GLuint, undefined);
        c.glGenBuffers(xbos.len, &xbos);
        errdefer c.glDeleteBuffers(xbos.len, &xbos);

        self.voxel_shader = try Shader.init(allocator, "voxel");
        errdefer self.voxel_shader.deinit();
        self.voxel_vao = vaos[0];
        self.voxel_uniform_mvp = self.voxel_shader.getUniform(m.Mat4, "mvp");

        self.cube_mesh_shader = try Shader.init(allocator, "cube_mesh");
        errdefer self.cube_mesh_shader.deinit();
        self.cube_mesh_uniform_mvp = self.cube_mesh_shader.getUniform(m.Mat4, "mvp");
        self.cube_mesh_vbo = xbos[0];
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.cube_mesh_vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(cube_edges.verts)), &cube_edges.verts, c.GL_STATIC_DRAW);
        self.cube_mesh_ebo = xbos[1];
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.cube_mesh_ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(cube_edges.indices)), &cube_edges.indices, c.GL_STATIC_DRAW);
        self.cube_mesh_vao = vaos[1];
        c.glBindVertexArray(self.cube_mesh_vao);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @intToPtr(?*anyopaque, 0));
        c.glEnableVertexAttribArray(0);

        self.cursor_pos = null;

        self.camera = Camera{
            .fov_y = 1.5,
            .aspect_ratio = 800.0 / 600.0,
            .yaw = 0.0,
            .pitch = 0.0,
            .pos = .{ 0.0, 0.0, 0.0 },
            .root = .{ .x = 0, .y = 0, .z = 0 },
        };

        return self;
    }

    pub fn deinit(self: *const Platform) void {
        const xbos = [_]c.GLuint{ self.cube_mesh_vbo, self.cube_mesh_ebo };
        const vaos = [_]c.GLuint{ self.cube_mesh_vao, self.voxel_vao };
        c.glDeleteBuffers(xbos.len, &xbos);
        c.glDeleteVertexArrays(vaos.len, &vaos);
        self.cube_mesh_shader.deinit();
        self.voxel_shader.deinit();
        c.glfwDestroyWindow(self.window);
        c.glfwTerminate();
        self.allocator.destroy(self);
    }

    pub fn run(self: *Platform) void {
        self.current_time = @floatCast(f32, c.glfwGetTime());
        while (c.glfwWindowShouldClose(self.window) == c.GLFW_FALSE) {
            const current_time = @floatCast(f32, c.glfwGetTime());
            self.delta_time = current_time - self.current_time;
            self.current_time = current_time;
            c.glfwPollEvents();
            self.processInput();
            self.render();
        }
    }

    fn render(self: *Platform) void {
        self.camera.calcViewProj();
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        self.voxel_shader.use();
        self.voxel_uniform_mvp.set(self.camera.mvp(.{ .x = 0, .y = 0, .z = 0 }));
        c.glBindVertexArray(self.voxel_vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        self.cube_mesh_shader.use();
        self.cube_mesh_uniform_mvp.set(self.camera.innerChunkMvp());
        c.glBindVertexArray(self.cube_mesh_vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.cube_mesh_vbo);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.cube_mesh_ebo);
        c.glDrawElements(c.GL_LINES, cube_edges.indices.len, c.GL_UNSIGNED_INT, @intToPtr(?*anyopaque, 0));

        c.glfwSwapBuffers(self.window);
    }

    fn processInput(self: *Platform) void {
        if (c.glfwGetKey(self.window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetWindowShouldClose(self.window, c.GLFW_TRUE);
        }
        var vel = m.zero(m.Vec3);
        if (c.glfwGetKey(self.window, c.GLFW_KEY_W) == c.GLFW_PRESS) {
            vel[0] += 1.0;
        }
        if (c.glfwGetKey(self.window, c.GLFW_KEY_A) == c.GLFW_PRESS) {
            vel[1] += 1.0;
        }
        if (c.glfwGetKey(self.window, c.GLFW_KEY_S) == c.GLFW_PRESS) {
            vel[0] -= 1.0;
        }
        if (c.glfwGetKey(self.window, c.GLFW_KEY_D) == c.GLFW_PRESS) {
            vel[1] -= 1.0;
        }
        if (c.glfwGetKey(self.window, c.GLFW_KEY_SPACE) == c.GLFW_PRESS) {
            vel[2] += 1.0;
        }
        if (c.glfwGetKey(self.window, c.GLFW_KEY_LEFT_SHIFT) == c.GLFW_PRESS) {
            vel[2] -= 1.0;
        }
        self.camera.move(m.scaleTo(vel, self.delta_time * movement_speed));
    }

    fn getFromWindow(window: ?*c.GLFWwindow) *Platform {
        return @ptrCast(*Platform, @alignCast(@alignOf(Platform), c.glfwGetWindowUserPointer(window)));
    }

    fn framebufferSizeCallback(window: ?*c.GLFWwindow, size_x: c_int, size_y: c_int) callconv(.C) void {
        const self = getFromWindow(window);
        c.glViewport(0, 0, @as(c.GLsizei, size_x), @as(c.GLsizei, size_y));
        self.camera.aspect_ratio = @intToFloat(f32, size_x) / @intToFloat(f32, size_y);
    }

    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        _ = mods;
        const self = getFromWindow(window);
        const cam_pos = self.camera.pos;
        if (key == c.GLFW_KEY_E and action == c.GLFW_PRESS) {
            std.debug.print("({}, {}, {})\n", .{ cam_pos[0], cam_pos[1], cam_pos[2] });
        }
    }

    fn cursorPosCallback(window: ?*c.GLFWwindow, pos_x: f64, pos_y: f64) callconv(.C) void {
        const self = getFromWindow(window);
        const pos = m.Vec2{ @floatCast(f32, pos_x), @floatCast(f32, pos_y) };
        if (self.cursor_pos) |old_pos| {
            const rel = (pos - old_pos) * m.splat2(-0.01);
            self.camera.yaw = @mod(self.camera.yaw + rel[0], std.math.tau);
            self.camera.pitch = std.math.clamp(self.camera.pitch + rel[1], -std.math.pi * 0.5, std.math.pi * 0.5);
        }
        self.cursor_pos = pos;
    }

    fn scrollCallback(window: ?*c.GLFWwindow, offset_x: f64, offset_y: f64) callconv(.C) void {
        _ = window;
        _ = offset_x;
        _ = offset_y;
    }

    fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
        _ = err;
        if (description) |d| {
            log.err("{s}", .{d});
        }
    }
};

const Shader = struct {
    program: c.GLuint,

    pub fn init(allocator: std.mem.Allocator, comptime name: []const u8) !Shader {
        const vert_path = "shaders/" ++ name ++ "_vs.glsl";
        const frag_path = "shaders/" ++ name ++ "_fs.glsl";
        const vert_src = @embedFile(vert_path);
        const frag_src = @embedFile(frag_path);

        return Shader{
            .program = try initGlProgram(allocator, vert_path, vert_src, frag_path, frag_src, name),
        };
    }

    pub fn deinit(self: Shader) void {
        c.glDeleteProgram(self.program);
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.program);
    }

    pub fn Uniform(comptime T: type) type {
        return struct {
            location: c.GLint,

            fn set(self: @This(), x: T) void {
                switch (T) {
                    f32 => c.glUniform1f(self.location, x),
                    m.Mat4 => c.glUniformMatrix4fv(self.location, 1, c.GL_TRUE, &x),
                    else => @compileError("Invalid uniform type"),
                }
            }
        };
    }

    pub fn getUniform(self: Shader, comptime T: type, name: [*:0]const u8) Uniform(T) {
        return .{
            .location = c.glGetUniformLocation(self.program, name),
        };
    }

    fn initGlProgram(
        allocator: std.mem.Allocator,
        vert_path: []const u8,
        vert_code: []const u8,
        frag_path: []const u8,
        frag_code: []const u8,
        name: []const u8,
    ) !c.GLuint {
        const vert = try initGlShader(allocator, c.GL_VERTEX_SHADER, vert_path, vert_code);
        defer c.glDeleteShader(vert);
        const frag = try initGlShader(allocator, c.GL_FRAGMENT_SHADER, frag_path, frag_code);
        defer c.glDeleteShader(frag);
        const gl_program = c.glCreateProgram();
        errdefer c.glDeleteProgram(gl_program);
        c.glAttachShader(gl_program, vert);
        c.glAttachShader(gl_program, frag);
        c.glLinkProgram(gl_program);

        var status = @as(c.GLint, undefined);
        c.glGetProgramiv(gl_program, c.GL_LINK_STATUS, &status);
        if (status == c.GL_TRUE) {
            return gl_program;
        } else {
            var log_len = @as(c.GLint, undefined);
            c.glGetProgramiv(gl_program, c.GL_INFO_LOG_LENGTH, &log_len);
            const info_log = try allocator.alloc(u8, @intCast(usize, log_len));
            defer allocator.free(info_log);
            c.glGetProgramInfoLog(gl_program, log_len, &log_len, info_log.ptr);
            log.err("Failed to link shader {s}:\n{s}", .{ name, info_log });
            return error.ShaderCreateError;
        }
    }

    fn initGlShader(
        allocator: std.mem.Allocator,
        kind: c.GLenum,
        path: []const u8,
        code: []const u8,
    ) !c.GLuint {
        const gl_shader = c.glCreateShader(kind);
        errdefer c.glDeleteShader(gl_shader);
        const code_ptr = code.ptr;
        const code_len = @intCast(c.GLint, code.len);
        c.glShaderSource(gl_shader, 1, &code_ptr, &code_len);
        c.glCompileShader(gl_shader);

        var status = @as(c.GLint, undefined);
        c.glGetShaderiv(gl_shader, c.GL_COMPILE_STATUS, &status);
        if (status == c.GL_TRUE) {
            return gl_shader;
        } else {
            var log_len = @as(c.GLint, undefined);
            c.glGetShaderiv(gl_shader, c.GL_INFO_LOG_LENGTH, &log_len);
            const info_log = try allocator.alloc(u8, @intCast(usize, log_len));
            defer allocator.free(info_log);
            c.glGetShaderInfoLog(gl_shader, log_len, &log_len, info_log.ptr);
            log.err("Failed to compile shader {s}:\n{s}", .{ path, info_log });
            return error.ShaderCreateError;
        }
    }
};

fn getGlfwError() ?[]const u8 {
    var description = @as([*c]const u8, undefined);
    _ = c.glfwGetError(&description);
    return std.mem.span(description);
}
