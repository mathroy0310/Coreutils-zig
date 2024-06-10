const std = @import("std");
const clap = @import("clap");
const share_utils = @import("shared_utils");

const description = "show or set the system's host name";

const params = clap.parseParamsComptime(
    \\-h, --help			Display this help and exit.
    \\
);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

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
        return share_utils.printHelp(std.io.getStdErr().writer(), params, description[0..]);
    }
    var buffer: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&buffer);
    _ = try stdout.print("{s}\n", .{hostname});
    std.posix.exit(0);
}
