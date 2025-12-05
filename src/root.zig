const std = @import("std");
const Allocator = std.mem.Allocator;

pub const framework = @import("framework.zig");

pub const solutions = [_]framework.DaySolution{
    @import("days/1.zig").solution,
    @import("days/2.zig").solution,
    @import("days/3.zig").solution,
    @import("days/4.zig").solution,
};
