#version 330 core

uvec2 positions[6] = uvec2[](
    uvec2(1, 0),
    uvec2(0, 0),
    uvec2(0, 1),
    uvec2(0, 1),
    uvec2(1, 1),
    uvec2(1, 0)
);

uniform mat4 mvp;

out vec3 color;

void main() {
    color = vec3(1.0, 1.0, 1.0);
    gl_Position = mvp * vec4(5.0, positions[gl_VertexID], 1.0);
}
