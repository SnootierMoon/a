#version 330 core

vec3 positions[6] = vec3[](
    vec3(0, 1, 0),
    vec3(0, 0, 0),
    vec3(0, 0, 1),
    vec3(0, 0, 1),
    vec3(0, 1, 1),
    vec3(0, 1, 0)
);

uint data = 0U * 1024U + 0U * 32U + 5U;

uniform mat4 mvp;

out vec3 color;

void main() {
    uvec3 pos = (uvec3(data) >> uvec3(0U, 5U, 10U)) & 31U;
    color = vec3(1.0, 1.0, 1.0);
    gl_Position = mvp * vec4(positions[gl_VertexID] + pos, 1.0);
}
