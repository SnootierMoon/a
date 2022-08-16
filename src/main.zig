const std = @import("std");

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const vertices = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};

const vert_src: []const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\
    \\vec3 offset[3] = vec3[](
    \\     vec3(0.0, 0.1, 0.0),
    \\     vec3(-0.1, -0.1, 0.0),
    \\     vec3(0.1, -0.1, 0.0)
    \\);
    \\
    \\void main() {
    \\    gl_Position = vec4(a_pos + offset[gl_VertexID], 1.0);
    \\}
;

const frag_src: []const u8 =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\void main() {
    \\    frag_color = vec4(1.0, 1.0, 1.0, 1.0);
    \\}
;

pub fn main() void {
    _ = c.glfwInit();
    defer c.glfwTerminate();
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);

    const window = c.glfwCreateWindow(800, 600, "GLFW Window", null, null) orelse {
        std.log.err("Failed to create window", .{});
        return;
    };
    defer c.glfwDestroyWindow(window);
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
        std.log.err("Failed to load OpenGL", .{});
        return;
    }

    c.glViewport(0, 0, 800, 600);

    var vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vao);

    var vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    const vert_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const frag_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    const shader_program = c.glCreateProgram();
    const vl = @intCast(c.GLint, vert_src.len);
    const fl = @intCast(c.GLint, frag_src.len);
    c.glShaderSource(vert_shader, 1, &vert_src.ptr, &vl);
    c.glCompileShader(vert_shader);
    c.glShaderSource(frag_shader, 1, &frag_src.ptr, &fl);
    c.glCompileShader(frag_shader);
    c.glAttachShader(shader_program, vert_shader);
    c.glAttachShader(shader_program, frag_shader);
    c.glLinkProgram(shader_program);
    c.glDeleteShader(vert_shader);
    c.glDeleteShader(frag_shader);

    c.glBindVertexArray(vao);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glVertexAttribDivisor(0, 1);
    c.glEnableVertexAttribArray(0);
    c.glUseProgram(shader_program);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glfwPollEvents();
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glDrawArraysInstanced(c.GL_TRIANGLES, 0, 3, 3);
        c.glfwSwapBuffers(window);
    }
}

fn framebuffer_size_callback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}
