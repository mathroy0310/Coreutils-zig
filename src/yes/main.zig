const std = @import("std");
const clap = @import("clap");
const share_utils = @import("shared_utils");
const stdout = std.io.getStdOut().writer();

const usage =
    \\Usage: yes [STRING]...
    \\   or:  yes OPTION
;

const description =
    \\Repeatedly output a line with all specified STRING(s), or 'y'.
;

const params = clap.parseParamsComptime(
    \\<STRING>...   Alternative string
    \\--help        			Display this help and exit.
    \\--version					Output version information and exit
);

const parsers = .{
    .STRING = clap.parsers.string,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var diag = clap.Diagnostic{};
    var res = clap.parse(
        clap.Help,
        &params,
        parsers,
        .{ .diagnostic = &diag, .allocator = gpa.allocator() },
    ) catch |err| {
        return err;
    };
    defer res.deinit();

    if ((res.args.help != 0)) {
        return share_utils.printHelp(std.io.getStdErr().writer(), params, .{ .usage = usage[0..], .description = description[0..] });
    }
    if ((res.args.version != 0)) {
        return share_utils.printVersion(std.io.getStdErr().writer(), "yes");
    }

    const message = if (res.positionals.len > 0) blk: {
        var current: ?[]u8 = null;

        for (res.positionals) |value| {
            if (current) |c| {
                const new = try std.fmt.allocPrint(gpa.allocator(), "{s} {s}", .{ c, value });
                gpa.allocator().free(c);
                current = new;
            } else {
                current = try std.fmt.allocPrint(gpa.allocator(), "{s}", .{value});
            }
        }
        break :blk current;
    } else null;

    defer if (message) |msg| gpa.allocator().free(msg);

    while (true) {
        if (message) |msg| {
            try stdout.print("{s}\n", .{msg});
        } else {
            try stdout.print("y\n", .{});
        }
    }
}
