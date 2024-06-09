const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var buffer: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&buffer);
    _ = try stdout.print("{s}\n", .{hostname});
    std.posix.exit(0);
}