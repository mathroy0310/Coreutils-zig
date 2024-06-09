const std = @import("std");
const log = std.log;

pub fn main() u8 {
    log.debug("hello from false", .{});
    return 1;
}
