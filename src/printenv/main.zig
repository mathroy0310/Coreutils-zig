const std = @import("std");
const clap = @import("clap");
const share_utils = @import("shared_utils");
const stdout = std.io.getStdOut().writer();

const usage = "Usage: printenv [OPTION]... [VARIABLES]";

const description =
    \\Print the values of the specified environment VARIABLE(s).
    \\If no VARIABLE is specified, print name and value pairs for them all.
;

const params = clap.parseParamsComptime(
    \\<VARIABLES>        Variable which value will be printed.
    \\-0, --null        End each output line with NULL instead of newline.
    \\-h, --help        Display this help and exit.
    \\-v, --version     Output version information and exit
);

const parser = .{
    .VARIABLES = clap.parsers.string,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var diag = clap.Diagnostic{};
    var res = clap.parse(
        clap.Help,
        &params,
        parser,
        .{ .diagnostic = &diag, .allocator = gpa.allocator() },
    ) catch |err| {
        return err;
    };
    defer res.deinit();

    if ((res.args.help != 0)) {
        return share_utils.printHelp(std.io.getStdErr().writer(), params, .{ .usage = usage[0..], .description = description[0..] });
    }
    if ((res.args.version != 0)) {
        return share_utils.printVersion(std.io.getStdErr().writer(), "printenv");
    }

    var envs = try std.process.getEnvMap(gpa.allocator());
    defer envs.deinit();

    if (res.positionals.len > 0) {
        for (res.positionals) |name| {
            if (envs.get(name)) |value| {
                if (res.args.null != 0) {
                    try stdout.print("{s}", .{value});
                } else {
                    try stdout.print("{s}\n", .{value});
                }
            }
        }
    } else {
        var iterator = envs.iterator();

        while (iterator.next()) |env| {
            if (res.args.null != 0) {
                try stdout.print("{s}={s}", .{ env.key_ptr.*, env.value_ptr.* });
            } else {
                try stdout.print("{s}={s}\n", .{ env.key_ptr.*, env.value_ptr.* });
            }
        }
    }
}
