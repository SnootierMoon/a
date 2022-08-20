const std = @import("std");

const m = @import("linmath.zig");

pub const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub const win_width = 800;
pub const win_height = 600;

const log = std.log.scoped(.glfw);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var platform = try Platform.init(gpa.allocator());
    defer platform.deinit();

    platform.run();
}

const Platform = struct {
    window: *c.GLFWwindow,

    vao: c.GLuint,
    triangle: Shader,
    triangle_proj: Shader.Uniform(m.Mat4),

    pub fn init(allocator: std.mem.Allocator) !Platform {
        if (c.glfwInit() == c.GLFW_FALSE) {
            log.err("Failed to initialize GLFW: {s}", .{getGlfwError().?});
            return error.GlfwInitFailed;
        }
        errdefer c.glfwTerminate();

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
        const window = c.glfwCreateWindow(win_width, win_height, "Test Window", null, null) orelse {
            log.err("Failed to create window: {s}", .{getGlfwError().?});
            return error.GlfwWindowCreateFailed;
        };
        errdefer c.glfwDestroyWindow(window);

        _ = c.glfwSetErrorCallback(error_callback);
        _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

        c.glfwMakeContextCurrent(window);
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
            log.err("Failed to load OpenGL with GLAD", .{});
            return error.GladInitFailed;
        }

        // c.glEnable(c.GL_DEPTH_TEST);

        var vao: c.GLuint = undefined;
        c.glGenVertexArrays(1, &vao);
        c.glBindVertexArray(vao);

        const triangle = try Shader.init(allocator, "triangle");
        errdefer triangle.deinit();

        const triangle_proj = triangle.getUniform(m.Mat4, "projection");

        return Platform{
            .window = window,
            .triangle = triangle,
            .triangle_proj = triangle_proj,
            .vao = vao,
        };
    }

    fn deinit(self: Platform) void {
        self.triangle.deinit();
        c.glDeleteVertexArrays(1, &self.vao);
        c.glfwDestroyWindow(self.window);
        c.glfwTerminate();
    }

    fn run(self: *Platform) void {
        while (c.glfwWindowShouldClose(self.window) == c.GLFW_FALSE) {
            c.glfwPollEvents();
            self.process_input();
            self.render();
        }
    }

    fn process_input(self: *Platform) void {
        if (c.glfwGetKey(self.window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetWindowShouldClose(self.window, c.GLFW_TRUE);
        }
    }

    fn render(self: *Platform) void {
        const time = @floatCast(f32, c.glfwGetTime());
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        self.triangle.use();
        self.triangle_proj.set(m.Mat4.rotationXY(time));
        c.glBindVertexArray(self.vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glfwSwapBuffers(self.window);
    }

    fn framebuffer_size_callback(window: ?*c.GLFWwindow, size_x: c_int, size_y: c_int) callconv(.C) void {
        _ = window;
        c.glViewport(0, 0, @as(c.GLsizei, size_x), @as(c.GLsizei, size_y));
    }

    fn cursor_pos_callback(window: ?*c.GLFWwindow, pos_x: f64, pos_y: f64) callconv(.C) void {
        _ = window;
        _ = pos_x;
        _ = pos_y;
    }

    fn scroll_callback(window: ?*c.GLFWwindow, offset_x: f64, offset_y: f64) callconv(.C) void {
        _ = window;
        _ = offset_x;
        _ = offset_y;
    }

    fn error_callback(err: c_int, description: [*c]const u8) callconv(.C) void {
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
                    m.Mat4 => c.glUniformMatrix4fv(self.location, 1, c.GL_TRUE, &x.data),
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
    var description = @as([*c]u8, undefined);
    _ = c.glfwGetError(&description);
    return if (description) |d| std.mem.span(d) else null;
}
