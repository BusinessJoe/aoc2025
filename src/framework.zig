const std = @import("std");
const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

pub const DayResult = struct {
    part1_str: ?[]u8,
    part2_str: ?[]u8,

    pub fn first_part(part1_buf: []u8, part1: anytype) !DayResult {
        return .{
            .part1_str = try std.fmt.bufPrint(part1_buf, "{any}", .{part1}),
            .part2_str = null,
        };
    }

    pub fn both_parts(part1_buf: []u8, part2_buf: []u8, part1: anytype, part2: anytype) !DayResult {
        return .{
            .part1_str = try std.fmt.bufPrint(part1_buf, "{any}", .{part1}),
            .part2_str = try std.fmt.bufPrint(part2_buf, "{any}", .{part2}),
        };
    }
};

pub const DaySolution = *const fn(Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) anyerror!DayResult;

