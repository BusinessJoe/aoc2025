const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
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
