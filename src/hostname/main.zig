const std = @import("std");
const clap = @import("clap");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help			Display this help and exit.
		\\-v, --version			Display 
        \\
    );
    var diag = clap.Diagnostic{};
    var res = clap.parse(
        clap.Help,
        &params,
        clap.parsers.default,
        .{ .diagnostic = &diag, .allocator = gpa.allocator() },
    ) catch |err| {
        return err;
    };
    defer res.deinit();

    const stdout = std.io.getStdOut().writer();
    if ((res.args.help != 0)) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }
    var buffer: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&buffer);
    _ = try stdout.print("{s}\n", .{hostname});
    std.posix.exit(0);
}
