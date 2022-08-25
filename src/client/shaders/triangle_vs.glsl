#version 330 core

uniform mat4 mvp;

out vec3 color;

vec2 positions[3] = vec2[](
    vec2(-0.3, -0.3),
    vec2(-0.3,  0.3),
    vec2(0.3,  -0.3)
);

void main() {
    color = vec3(1.0, 1.0, 1.0);
    gl_Position = mvp * vec4(5, positions[gl_VertexID], 1.0);
}
