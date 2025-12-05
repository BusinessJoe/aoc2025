const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

pub fn solution(allocator: Allocator, bytes: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    _ = allocator;

    var angle: u32 = 50;
    var zero_count: u32 = 0;
    var p2_count: u32 = 0;

    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        const val = try std.fmt.parseInt(u32, line[1..], 10);

        var right: bool = true;
        if (line[0] == 'L') {
            right = false;
        }
        const s = update_angle(angle, right, val);
        angle = s.new_angle;
        p2_count += s.num_zeros;

        if (angle == 0) zero_count += 1;
    }

    return try DayResult.both_parts(part1_buf, part2_buf, zero_count, p2_count);
}

fn update_angle(current_angle: u32, right: bool, val: u32) struct { new_angle: u32, num_zeros: u32 } {
    var p2_count: u32 = 0;
    var new_angle = current_angle;

    p2_count += @intCast(@divFloor(val, 100));

    if (right) {
        new_angle = @mod(current_angle + val, 100);
        if (current_angle > 0 and (new_angle < current_angle or new_angle == 0)) p2_count += 1;
    } else {
        const norm_val: u32 = 100 - @mod(val, 100);
        new_angle = @mod(current_angle + norm_val, 100);
        if (current_angle > 0 and (new_angle > current_angle or new_angle == 0)) p2_count += 1;
    }

    return .{
        .new_angle = new_angle,
        .num_zeros = p2_count,
    };
}


const expectEqual = std.testing.expectEqual;

test "update angle" {
    try expectEqual(0, update_angle(0, true, 1).num_zeros);
    try expectEqual(0, update_angle(0, true, 99).num_zeros);
    try expectEqual(1, update_angle(0, true, 100).num_zeros);
    try expectEqual(1, update_angle(0, true, 101).num_zeros);
    try expectEqual(8, update_angle(0, false, 800).num_zeros);

    try expectEqual(0, update_angle(5, true, 1).num_zeros);
    try expectEqual(0, update_angle(5, true, 94).num_zeros);
    try expectEqual(1, update_angle(5, true, 95).num_zeros);
    try expectEqual(1, update_angle(5, true, 96).num_zeros);
    try expectEqual(1, update_angle(5, true, 99).num_zeros);
    try expectEqual(1, update_angle(5, true, 100).num_zeros);
    try expectEqual(1, update_angle(5, true, 194).num_zeros);
    try expectEqual(2, update_angle(5, true, 195).num_zeros);

    try expectEqual(0, update_angle(0, false, 1).num_zeros);
    try expectEqual(99, update_angle(0, false, 1).new_angle);
    try expectEqual(0, update_angle(0, false, 99).num_zeros);
    try expectEqual(1, update_angle(0, false, 100).num_zeros);
    try expectEqual(1, update_angle(0, false, 101).num_zeros);

    try expectEqual(0, update_angle(5, false, 1).num_zeros);
    try expectEqual(1, update_angle(5, false, 5).num_zeros);
    try expectEqual(1, update_angle(5, false, 99).num_zeros);
    try expectEqual(1, update_angle(5, false, 100).num_zeros);
    try expectEqual(1, update_angle(5, false, 104).num_zeros);
    try expectEqual(2, update_angle(5, false, 105).num_zeros);
    try expectEqual(2, update_angle(5, false, 195).num_zeros);

    try expectEqual(10, update_angle(50, true, 1000).num_zeros);
        
    try expectEqual(8, update_angle(0, true, 823).num_zeros);

    try expectEqual(1, update_angle(50, true, 50).num_zeros);
    try expectEqual(0, update_angle(0, true, 50).num_zeros);
    try expectEqual(1, update_angle(50, false, 50).num_zeros);
    try expectEqual(0, update_angle(0, false, 50).num_zeros);
    try expectEqual(1, update_angle(50, true, 75).num_zeros);
    try expectEqual(1, update_angle(25, false, 50).num_zeros);
}
