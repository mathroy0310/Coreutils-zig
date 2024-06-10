//! This is utility for the functions and tool used by multiple binary
const clap = @import("clap");
const std = @import("std");

pub const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0, .pre = "dev" };
const gpl_license =
    \\Copyright (C) 2024 Free Software Foundation, Inc.
    \\License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
    \\This is free software: you are free to change and redistribute it.
    \\There is NO WARRANTY, to the extent permitted by law.
    \\
    \\Written by Torbjörn Granlund and Richard M. Stallman.
;

pub fn printHelp(out_stream: anytype, params: anytype, p: anytype) !void {
    try out_stream.print("{s}\n{s}\n\n", .{ p.usage, p.description });
    try clap.help(out_stream, clap.Help, &params, .{
        .description_indent = 4,
        .description_on_new_line = false,
        .indent = 2,
        .spacing_between_parameters = 0,
    });
    return out_stream.print("\n", .{});
}

pub fn printVersion(out_stream: anytype, name: []const u8) !void {
    return out_stream.print("{s} (Coreutils-zig)  {any}\n{s}\n", .{ name, version, gpl_license });
}
