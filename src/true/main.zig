const std = @import("std");
const log = std.log;

pub fn main() u8 {
    log.debug("hello from true", .{});
    return 0;
}