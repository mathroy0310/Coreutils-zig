const std = @import("std");
const clap = @import("clap");
const share_utils = @import("shared_utils");
const stdout = std.io.getStdOut().writer();

//TODO issue when last line of a file is not termined by a '\n'

const usage = "Usage: cat [OPTION]... [FILE]...";

const description =
    \\Concatenate FILE(s) to standard output.
    \\
    \\With no FILE, or when FILE is -, read standard input."
;

const params = clap.parseParamsComptime(
    \\<FILE>           			Path to file, if omitted, stdin will be used.
    \\-A, --show-all			Equivalent to `-vET'
    \\-b, --number-nonblank 	Number nonempty output lines, overrides -n
    \\-e     					Equivalent to `-vE'
    \\-E, --show-ends  			Display $ at the end of each line.
    \\-n, --number     	 		Show line numbers.
    \\-s, --squeeze-blank		Suppress repeated empty output lines
    \\-t     					Equivalent to -vT
    \\-T, --show-tabs			Display TAB characters as ^I
    \\-u						(ignored)
    \\-v, --show-nonprinting	Use ^ and M- notation, except for LFD and TAB
    \\--help        			Display this help and exit.
    \\--version					Output version information and exit
);

const parsers = .{
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

    if ((res.args.help != 0)) {
        return share_utils.printHelp(std.io.getStdErr().writer(), params, .{ .usage = usage[0..], .description = description[0..] });
    }
    if ((res.args.version != 0)) {
        return share_utils.printVersion(std.io.getStdErr().writer(), "cat");
    }

    const show_line_numbers = res.args.number != 0;
    const show_ends = res.args.@"show-ends" != 0;

    if (res.positionals.len == 0) {
        try printFile(gpa.allocator(), std.io.getStdIn().reader(), show_line_numbers, show_ends);
    } else {
        for (res.positionals) |file_path| {
            if (std.mem.eql(u8, file_path, "-")) {
                try printFile(gpa.allocator(), std.io.getStdIn().reader(), show_line_numbers, show_ends);
            } else {
                var file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
                    switch (err) {
                        std.fs.File.OpenError.FileNotFound => {
                            try stdout.print("{s}: cannot open '{s}' for reading: No such file or directory\n", .{ "cat", file_path });
                        },
                        else => {
                            try stdout.print("{s}: cannot open '{s}' for reading: {any}", .{ "cat", file_path, err });
                        },
                    }
                    continue;
                };
                defer file.close();

                try printFile(gpa.allocator(), file.reader(), show_line_numbers, show_ends);
            }
        }
    }
}

fn printFile(allocator: std.mem.Allocator, in_stream: anytype, show_line_numbers: bool, show_ends: bool) !void {
    const out_stream = std.io.getStdOut().writer();
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

    var last_line = std.ArrayList(u8).init(allocator);
    defer last_line.deinit();
    try buf_in_stream.streamUntilDelimiter(last_line.writer(), 0, null);

    const last_line_slice = try last_line.toOwnedSlice();
    defer allocator.free(last_line_slice);

    try out_stream.print("{s}", .{last_line_slice});
    try out_stream.print("{s}\n", .{if (show_ends) "$" else ""});
}
