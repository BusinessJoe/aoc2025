const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    _ = allocator;

    var part1: u64 = 0;
    var part2: u64 = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        part1 += maximizeLine(line, 2);
        part2 += maximizeLine(line, 12);
    }

    return try DayResult.both_parts(part1_buf, part2_buf, part1, part2);
}

fn maximizeLine(line: []const u8, n_digits: usize) u64 {
    var joltage: u64 = 0;

    var remaining = line;

    var end_buffer = n_digits - 1;

    for (0..n_digits) |_| {
        const idx = std.mem.indexOfMax(u8, remaining[0..remaining.len - end_buffer]);
        const max_char = remaining[idx];

        const max_digit: u8 = max_char - '0'; 

        joltage = joltage * 10 + max_digit;

        if (end_buffer > 0) end_buffer -= 1;
        remaining = remaining[idx + 1..];
    }

    return joltage;
}
