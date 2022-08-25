const std = @import("std");
const glfw = @import("client/glfw.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var platform = try glfw.Platform.init(gpa.allocator());
    defer platform.deinit();

    platform.run();
}
