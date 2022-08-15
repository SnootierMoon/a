const std = @import("std");
const system_sdk = @import("system_sdk.zig");

glad: *std.build.LibExeObjStep,
glfw: *std.build.LibExeObjStep,

pub fn init(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) @This() {
    const glad = b.addStaticLibrary("glad", null);
    glad.setTarget(target);
    glad.setBuildMode(mode);
    glad.addCSourceFile(glad_sources, &cflags);
    glad.addIncludePath(glad_include);
    glad.linkLibC();
    glad.install();

    const glfw = b.addStaticLibrary("glfw", null);
    glfw.setTarget(target);
    glfw.setBuildMode(mode);
    switch (target.getOsTag()) {
        .windows => {
            system_sdk.include(b, glfw, .{});
            glfw.defineCMacro("_GLFW_WIN32", null);
            glfw.addCSourceFiles(&glfw_sources_windows_win32, &cflags);
            glfw.linkLibC();
        },
        .linux => {
            system_sdk.include(b, glfw, .{});
            glfw.defineCMacro("_GLFW_X11", null);
            glfw.addCSourceFiles(&glfw_sources_linux_x11, &cflags);
            glfw.linkLibC();
        },
        .macos => {
            system_sdk.include(b, glfw, .{});
            glfw.defineCMacro("_GLFW_COCOA", null);
            glfw.addCSourceFiles(&glfw_sources_macos_cocoa, &cflags);
            glfw.linkLibC();
        },
        else => @panic("Unsupported target platform"),
    }
    glfw.install();

    return @This(){
        .glad = glad,
        .glfw = glfw,
    };
}

pub fn link(self: @This(), x: *std.build.LibExeObjStep) void {
    system_sdk.include(x.builder, x, .{});
    x.linkLibrary(self.glad);
    x.addIncludePath(glad_include);

    x.linkLibrary(self.glfw);
    x.addIncludePath(glfw_include);
    switch (x.target.getOsTag()) {
        .windows => {
            x.linkSystemLibraryName("gdi32");
            x.linkSystemLibraryName("user32");
            x.linkSystemLibraryName("shell32");
            x.linkLibC();
        },
        .linux => {
            x.linkSystemLibraryName("X11");
            x.linkSystemLibraryName("xcb");
            x.linkSystemLibraryName("Xau");
            x.linkSystemLibraryName("Xdmcp");
            x.linkLibC();
        },
        .macos => {
            x.linkFramework("IOKit");
            x.linkFramework("CoreFoundation");
            x.linkSystemLibraryName("objc");
            x.linkFramework("AppKit");
            x.linkFramework("CoreServices");
            x.linkFramework("CoreGraphics");
            x.linkFramework("Foundation");
            x.linkLibC();
        },
        else => @panic("Unsupported target platform"),
    }
}

const cflags = .{"-std=c99"};

const glad_include = "libs/glad/include";
const glad_sources = "libs/glad/src/glad.c";

const glfw_include = "libs/glfw-3.3.8/include";
const glfw_sources_common = .{
    "libs/glfw-3.3.8/src/egl_context.c",
    "libs/glfw-3.3.8/src/osmesa_context.c",
    "libs/glfw-3.3.8/src/context.c",
    "libs/glfw-3.3.8/src/init.c",
    "libs/glfw-3.3.8/src/input.c",
    "libs/glfw-3.3.8/src/monitor.c",
    "libs/glfw-3.3.8/src/window.c",
    "libs/glfw-3.3.8/src/vulkan.c",
};

const glfw_sources_linux_x11 = glfw_sources_common ++ .{
    "libs/glfw-3.3.8/src/glx_context.c",
    "libs/glfw-3.3.8/src/x11_init.c",
    "libs/glfw-3.3.8/src/linux_joystick.c",
    "libs/glfw-3.3.8/src/x11_monitor.c",
    "libs/glfw-3.3.8/src/x11_window.c",
    "libs/glfw-3.3.8/src/posix_time.c",
    "libs/glfw-3.3.8/src/posix_thread.c",
    "libs/glfw-3.3.8/src/xkb_unicode.c",
};

const glfw_sources_linux_wayland = glfw_sources_common ++ .{
    "libs/glfw-3.3.8/src/wl_init.c",
    "libs/glfw-3.3.8/src/linux_joystick.c",
    "libs/glfw-3.3.8/src/wl_monitor.c",
    "libs/glfw-3.3.8/src/wl_window.c",
    "libs/glfw-3.3.8/src/posix_time.c",
    "libs/glfw-3.3.8/src/posix_thread.c",
    "libs/glfw-3.3.8/src/xkb_unicode.c",
};

const glfw_sources_windows_win32 = glfw_sources_common ++ .{
    "libs/glfw-3.3.8/src/wgl_context.c",
    "libs/glfw-3.3.8/src/win32_init.c",
    "libs/glfw-3.3.8/src/win32_joystick.c",
    "libs/glfw-3.3.8/src/win32_monitor.c",
    "libs/glfw-3.3.8/src/win32_window.c",
    "libs/glfw-3.3.8/src/win32_time.c",
    "libs/glfw-3.3.8/src/win32_thread.c",
};

const glfw_sources_macos_cocoa = glfw_sources_common ++ .{
    "libs/glfw-3.3.8/src/nsgl_context.m",
    "libs/glfw-3.3.8/src/cocoa_init.m",
    "libs/glfw-3.3.8/src/cocoa_joystick.m",
    "libs/glfw-3.3.8/src/cocoa_monitor.m",
    "libs/glfw-3.3.8/src/cocoa_window.m",
    "libs/glfw-3.3.8/src/cocoa_time.c",
    "libs/glfw-3.3.8/src/posix_thread.c",
};
