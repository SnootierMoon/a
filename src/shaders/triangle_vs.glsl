#version 330 core

uniform mat4 mvp;

vec2 positions[3] = vec2[](
    vec2(-0.3, -0.3),
    vec2(-0.3,  0.3),
    vec2(0.3,  -0.3)
);


void main() {
    gl_Position = mvp * vec4(5, positions[gl_VertexID], 1.0);
}
