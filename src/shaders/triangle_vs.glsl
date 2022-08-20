#version 330 core

uniform mat4 projection;

vec3 positions[3] = vec3[](
    vec3(-0.5, -0.5, 0.0),
    vec3(0.5,  -0.5, 0.0),
    vec3(0.0,  0.5,  0.0)
);

void main() {
    gl_Position = projection * vec4(positions[gl_VertexID], 1.0);
}
