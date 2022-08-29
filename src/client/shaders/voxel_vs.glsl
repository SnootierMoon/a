#version 330 core

vec2 positions[6] = vec2[](
    vec2(1, 0),
    vec2(0, 0),
    vec2(0, 1),
    vec2(0, 1),
    vec2(1, 1),
    vec2(1, 0)
);

uint pos = 1 + 2 + 3;

uniform mat4 mvp;

out vec3 color;

void main() {
    color = vec3(1.0, 1.0, 1.0);
    gl_Position = mvp * vec4(5.0, positions[gl_VertexID], 1.0);
}
