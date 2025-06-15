const std = @import("std");

pub const Options = struct {
    optimize: std.builtin.Mode = .ReleaseSmall,
    target: std.Build.ResolvedTarget,
};

pub fn build(b: *std.Build) void {
    const options = Options{ .target = b.resolveTargetQuery(.{}) };
    const exe = b.addExecutable(.{
        .name = "happy-fathers-day",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = options.target,
        .optimize = options.optimize,
    });

    const zglfw = b.dependency("zglfw", .{
        .target = options.target,
    });
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    exe.linkLibrary(zglfw.artifact("glfw"));

    @import("zgpu").addLibraryPathsTo(exe);
    const zgpu = b.dependency("zgpu", .{
        .target = options.target,
    });
    exe.root_module.addImport("zgpu", zgpu.module("root"));
    exe.linkLibrary(zgpu.artifact("zdawn"));

    const zmath = b.dependency("zmath", .{
        .target = options.target,
    });
    exe.root_module.addImport("zmath", zmath.module("root"));

    const zpool = b.dependency("zpool", .{
        .target = options.target,
    });
    exe.root_module.addImport("zpool", zpool.module("root"));

    if (options.target.result.os.tag == .macos) {
        if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
            exe.addLibraryPath(system_sdk.path("macos12/usr/lib"));
            exe.addSystemFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
        }
    } else if (options.target.result.os.tag == .linux) {
        if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
            exe.addLibraryPath(system_sdk.path("linux/lib/x86_64-linux-gnu"));
        }
    }

    const exe_options = b.addOptions();
    exe.root_module.addOptions("build_options", exe_options);

    // Install
    const install_step = b.step("install-zsdl", "Install");
    install_step.dependOn(&b.addInstallArtifact(exe, .{}).step);

    // Run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(install_step);

    const run_step = b.step("run", "Run");
    run_step.dependOn(&run_cmd.step);

    b.getInstallStep().dependOn(install_step);
}
