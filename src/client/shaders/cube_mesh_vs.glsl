#version 330 core

uniform mat4 mvp;

layout(location = 0) in vec3 vertex_pos;

void main() {
    gl_Position = mvp * vec4(vertex_pos, 1.0);
}
