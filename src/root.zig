const std = @import("std");
const Allocator = std.mem.Allocator;

pub const framework = @import("framework.zig");
const DayResult = framework.DayResult;


pub fn solution_1(allocator: Allocator, bytes: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
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

pub fn solution_2(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    var total_p1: u64 = 0;
    var total_p2: u64 = 0;

    var pairs = std.mem.splitScalar(u8, input, ',');

    while (pairs.next()) |pair| {
        var ids = std.mem.splitScalar(u8, pair, '-');
        const id_first = try std.fmt.parseInt(u64, ids.next() orelse return error.BadInput, 10);
        const id_last = try std.fmt.parseInt(u64, ids.next() orelse return error.BadInput, 10);

        total_p1 += try get_invalid_values(allocator, id_first, id_last, 2, null);

        // We need to guarantee no repeats
        var set: std.AutoHashMapUnmanaged(u64, void) = .empty;
        defer set.deinit(allocator);
        for (2..get_len(id_last) + 1) |repeats| {
            total_p2 += try get_invalid_values(allocator, id_first, id_last, repeats, &set);
        }
    }

    return DayResult.both_parts(part1_buf, part2_buf, total_p1, total_p2);
}

fn get_invalid_values(allocator: Allocator, id_first: u64, id_last: u64, repeats: u64, set_opt: ?*std.AutoHashMapUnmanaged(u64, void)) !u64 {
    const id_first_len = get_len(id_first);
    const id_last_len = get_len(id_last);

    if (id_first_len != id_last_len) {
        const nines = try std.math.powi(u64, 10, id_first_len) - 1;
        return try get_invalid_values(allocator, id_first, nines, repeats, set_opt) 
            + try get_invalid_values(allocator, nines + 1, id_last, repeats, set_opt);
    }

    if (id_first_len % repeats != 0) return 0;

    var first_half = id_first / try std.math.powi(u64, 10, id_first_len / repeats * (repeats - 1));
    var candidate = try repeat(first_half, repeats);

    var total: u64 = 0;

    // Skip candidates below first id
    while (candidate < id_first) {
        first_half += 1;
        candidate = try repeat(first_half, repeats);
    }

    // Keep candidates below (or equal to) last id
    while (candidate <= id_last) {
        if (set_opt) |set| {
            if (!set.contains(candidate)) {
                total += candidate;
                try set.put(allocator, candidate, {});
            }
        } else {
            total += candidate;
        }
        first_half += 1;
        candidate = try repeat(first_half, repeats);
    }

    return total;
}

fn repeat(n: u64, repeats: u64) !u64 {
    const len = get_len(n);
    const mult = try std.math.powi(u64, 10, len);

    var result: u64 = 0;
    for (0..repeats) |_| {
        result = result * mult + n;
    }
    return result;
}

// fn is_invalid(id: u64, stride: u64) struct { bool, u64 } {
//     const len = get_len(id);
//     var i = len / 2;
//     while (i > 0) {
//         i -= 1;
//         if (get_ith_digit(id, i) != get_ith_digit(id, i + len / 2)) {
//             const step = try std.math.powi(u64, 10, i);
//             return .{ false, step };
//         }
//     }
//     return .{ true, 
// }

fn get_len(int: u64) u64 {
    return std.math.log10_int(int) + 1;
}

fn get_invalid_value(id: u64) !u64 {
    const id_len = std.math.log10_int(id) + 1;
    if (id_len % 2 == 1) return 0;

    const half = id_len / 2;
    for (0..half) |i| {
        if (try get_ith_digit(id, @intCast(i)) != try get_ith_digit(id, @intCast(i + half))) return 0;
    }

    return id;
}

fn get_ith_digit(n: u64, i: u64) !u64 {
    return (n / try std.math.powi(u64, 10, i)) % 10;
}


//
// Testing
//
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
