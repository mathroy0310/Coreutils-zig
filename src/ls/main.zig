const std = @import("std");
const fs = std.fs;
const clap = @import("clap");
const share_utils = @import("shared_utils");
const stdout = std.io.getStdOut().writer();

//TODO
// right now only -a, no params and only dir options works
// may want to make a proper format first doing more params
// -d and -r has issues with more than one dir

const description = "List directory contents";

const params = clap.parseParamsComptime(
    \\--help				Display this help and exit.
    \\-l, --long			Use a long listing format.
    \\-R, --recursive		List subdirectories recursively.
    \\-a, --all				Do not ignore entries starting with `.'.\
    \\-t, --time			Sort by time, newest first.
    \\-r, --reverse			Reverse order while sorting.
    \\-1, --one				List one file per line.
    \\-h, --human-readable	With -l and -s, print sizes like 1K 234M 2G etc.			
    \\-d, --directory		List directories themselves, not their contents.
    \\<DIR>...				Path to dir, if omitted, cwd will be used.
    \\
);

const parsers = .{
    .DIR = clap.parsers.string,
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
        return share_utils.printHelp(std.io.getStdErr().writer(), params, description[0..]);
    }
    var combined_flags: u8 = 0;

    if (res.args.long != 0) combined_flags |= 1 << 0;
    if (res.args.recursive != 0) combined_flags |= 1 << 1;
    if (res.args.all != 0) combined_flags |= 1 << 2;
    if (res.args.time != 0) combined_flags |= 1 << 3;
    if (res.args.reverse != 0) combined_flags |= 1 << 4;
    if (res.args.one != 0) combined_flags |= 1 << 5;
    if (res.args.directory != 0) combined_flags |= 1 << 6;

    if (res.positionals.len == 0) {
        try printDirContent(gpa.allocator(), ".", combined_flags);
    } else {
        for (res.positionals) |file_path| {
            if (res.positionals.len > 1) try stdout.print("{s}:\n", .{file_path});
            try printDirContent(gpa.allocator(), file_path, combined_flags);
            try stdout.print("\n", .{});
        }
    }
}

fn sortFileList(file_list_items: anytype, flags: u8) void {
    const sort = struct {
        fn skipLeadingDots(s: []const u8) []const u8 {
            var i: usize = 0;
            while (i < s.len and s[i] == '.') : (i += 1) {}
            return s[i..];
        }

        fn sort_ascii(_: void, l: []const u8, r: []const u8) bool {
            const stripped_l = skipLeadingDots(l);
            const stripped_r = skipLeadingDots(r);

            return std.ascii.lessThanIgnoreCase(stripped_l, stripped_r);
        }

        fn reverse_sort_ascii(_: void, l: []const u8, r: []const u8) bool {
            const stripped_l = skipLeadingDots(l);
            const stripped_r = skipLeadingDots(r);

            return !std.ascii.lessThanIgnoreCase(stripped_l, stripped_r);
        }
    };

    if (flags & (1 << 4) != 0) {
        std.sort.pdq([]const u8, file_list_items, {}, sort.reverse_sort_ascii);
    } else {
        std.sort.pdq([]const u8, file_list_items, {}, sort.sort_ascii);
    }
}

fn printDirContent(allocator: std.mem.Allocator, target_dir: []const u8, flags: u8) !void {
    var dir = try std.fs.cwd().openDir(target_dir, .{ .iterate = true });
    defer dir.close();

    if ((flags & 1 << 6) != 0) { // -d
        try stdout.print("{s}\n", .{target_dir});
        return;
    }

    var file_list = std.ArrayList([]const u8).init(allocator);
    defer file_list.deinit();

    if (flags & (1 << 2) != 0) { // -a flag small cheat to add the . and ..
        try file_list.append(".");
        try file_list.append("..");
    }

    var dir_iter = dir.iterate();
    while (try dir_iter.next()) |entry| {
        if ((flags & 1 << 2) != 0) { // -a flag
            try file_list.append(entry.name);
        } else if (!std.mem.startsWith(u8, entry.name, ".")) { // no flag
            try file_list.append(entry.name);
        }
    }

    sortFileList(file_list.items, flags);

    // this is bad way of doing it for now

    for (file_list.items) |file| {
        _ = try stdout.print("{s}  ", .{file});
    }
    try stdout.print("\n", .{});
}
