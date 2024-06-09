const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const src_dir = try b.build_root.handle.openDir("src", .{ .iterate = true });
    var srcs_iter = src_dir.iterate();
    while (try srcs_iter.next()) |src_entry| {
        const name = std.fs.path.stem(src_entry.name);
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = b.path(b.fmt("src/{s}/main.zig", .{name})),
            .target = target,
            .optimize = optimize,
        });

        const clap = b.dependency("clap", .{});
        
        const shared_utils_mod = b.addModule(
            "shared_utils",
            .{ .root_source_file = b.path("lib/shared_utils.zig") },
        );
        shared_utils_mod.addImport("clap", clap.module("clap"));

        
        exe.root_module.addImport("clap", clap.module("clap"));
        exe.root_module.addImport("shared_utils", shared_utils_mod);

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(b.fmt("run-{s}", .{name}), b.fmt("Run the {s} bin", .{name}));
        run_step.dependOn(&run_cmd.step);
    }
}
