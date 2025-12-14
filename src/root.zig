const std = @import("std");
const Allocator = std.mem.Allocator;

pub const framework = @import("framework.zig");

pub const solutions = [_]framework.DaySolution{
    @import("days/1.zig").solution,
    @import("days/2.zig").solution,
    @import("days/3.zig").solution,
    @import("days/4.zig").solution,
    @import("days/5.zig").solution,
    @import("days/6.zig").solution,
    @import("days/7.zig").solution,
    @import("days/8.zig").solution,
};

test {
    _ = @import("bounded_min_heap.zig");
    _ = @import("octree.zig");
}
