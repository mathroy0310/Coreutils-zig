const std = @import("std");
const clap = @import("clap");
const share_utils = @import("shared_utils");

const description = "Concatenate files and print to stdout";

const params = clap.parseParamsComptime(
    \\-h, --help        Display this help and exit.
    \\-n, --number      Show line numbers.
    \\-e, --show-ends   Display $ at the end of each line.
    \\<FILE>            Path to file, if omitted, stdin will be used.
    \\
);

const parsers = .{
    .INT = clap.parsers.int(usize, 10),
    .FILE = clap.parsers.string,
};

var line_number: usize = 1;

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

    const stdout = std.io.getStdOut().writer();
    if ((res.args.help != 0)) {
        return share_utils.printHelp(std.io.getStdErr().writer(), params, description[0..]);
    }

    const show_line_numbers = res.args.number != 0;
    const show_ends = res.args.@"show-ends" != 0;

    if (res.positionals.len == 0) {
        try printFile(gpa.allocator(), std.io.getStdIn().reader(), stdout, show_line_numbers, show_ends);
    } else {
        for (res.positionals) |file_path| {
            if (std.mem.eql(u8, file_path, "-")) {
                try printFile(gpa.allocator(), std.io.getStdIn().reader(), stdout, show_line_numbers, show_ends);
            } else {
                var file = try std.fs.cwd().openFile(file_path, .{});
                defer file.close();

                try printFile(gpa.allocator(), file.reader(), stdout, show_line_numbers, show_ends);
            }
        }
    }
}

fn printFile(allocator: std.mem.Allocator, in_stream: anytype, out_stream: anytype, show_line_numbers: bool, show_ends: bool) !void {
    var buf_reader = std.io.bufferedReader(in_stream);
    var buf_in_stream = buf_reader.reader();

    while (true) {
        var line = std.ArrayList(u8).init(allocator);
        defer line.deinit();

        buf_in_stream.streamUntilDelimiter(line.writer(), '\n', null) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };

        const line_slice = try line.toOwnedSlice();
        defer allocator.free(line_slice);

        if (show_line_numbers)
            try out_stream.print("{d: >6}  ", .{line_number});

        try out_stream.print("{s}", .{line_slice});

        try out_stream.print("{s}\n", .{if (show_ends) "$" else ""});

        line_number += 1;
    }
}
