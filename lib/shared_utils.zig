
const clap = @import("clap");

pub fn printHelp(out_stream: anytype, params: anytype, description:  [] const u8) !void{
    try out_stream.print("{s}\n", .{description});
    return clap.help(out_stream, clap.Help, &params, .{});
    
}