const std = @import("std");
const clap = @import("clap");
const shared_utils = @import("shared_utils");

const stdout = std.io.getStdOut().writer();

const usage =
    \\Usage: sleep NUMBER[SUFFIX]...
    \\or:  sleep OPTION
;

const description =
    \\Pause for NUMBER seconds.  SUFFIX may be 's' for seconds (the default),
    \\'m' for minutes, 'h' for hours or 'd' for days.  NUMBER need not be an
    \\integer.  Given two or more arguments, pause for the amount of time
    \\specified by the sum of their values.
;
const params = clap.parseParamsComptime(
    \\<NUMBER>...      Number of time to sleep with suffix 
    \\-h, --help        Display this help and exit.
    \\-v, --version		Output version information and exit
);

const parser = .{
    .NUMBER = clap.parsers.string,
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
        return shared_utils.printHelp(std.io.getStdErr().writer(), params, .{ .usage = usage[0..], .description = description[0..] });
    }
    if ((res.args.version != 0)) {
        return shared_utils.printVersion(std.io.getStdErr().writer(), "cat");
    }
    if (res.positionals.len == 0) {
        try stdout.print("{s}: missing operand\n", .{"sleep"});
        try stdout.print("Try '{s} --help' for more information.\n", .{"sleep"});
        return;
    }

    var sleep_total: f64 = 0;
    for (res.positionals) |arg| {
        var arg_clean = arg;
        var mutl: f64 = 1.0;
        switch (arg[arg.len - 1]) {
            'm' => {
                arg_clean = arg[0 .. arg.len - 1];
                mutl = 60.0;
            },
            'h' => {
                arg_clean = arg[0 .. arg.len - 1];
                mutl = 60.0 * 60.0;
            },
            'd' => {
                arg_clean = arg[0 .. arg.len - 1];
                mutl = 60.0 * 60.0 * 24.0;
            },
            's' => {
                arg_clean = arg[0 .. arg.len - 1];
                mutl = 1.0;
            },
            else => {},
        }
        const arg_val = std.fmt.parseFloat(f64, arg_clean) catch {
            try stdout.print("{s}: invalid time interval '{s}'\n", .{ "sleep", arg });
            return;
        };
        if (arg_val < 0.0) {
            try stdout.print("{s}: invalid time interval '{s}' -> cannot be negative\n", .{ "sleep", arg });
            return;
        }
        sleep_total += mutl * arg_val;
    }
    const ns_sleep: u64 = @intFromFloat(sleep_total * 1000000000.0);
    std.time.sleep(ns_sleep);
}
