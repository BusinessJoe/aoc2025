const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    var lines = std.mem.splitScalar(u8, input, '\n');

    const start_line = lines.next() orelse return error.ExpectedLine;
    _ = lines.next();

    var current_state = try allocator.alloc(u64, start_line.len);
    defer allocator.free(current_state);
    var next_state = try allocator.alloc(u64, start_line.len);
    defer allocator.free(next_state);

    for (current_state, 0..) |*item, i| {
        if (start_line[i] == 'S') {
            item.* = 1;
        } else {
            item.* = 0;
        }
    }

    // Part 1
    var splits: u32 = 0;

    while (lines.next()) |line| {
        // Skip blank line
        _ = lines.next();

        for (current_state, next_state) |*curr, *next| {
            next.* = curr.*;
        }

        for (line, 0..) |char, i| {
            if (char == '^') {
                next_state[i] = 0;
                if (current_state[i] > 0) {
                    splits += 1;
                    if (i > 0) next_state[i - 1] += current_state[i];
                    if (i < next_state.len - 1) next_state[i + 1] += current_state[i];
                }
            }        
        }

        // Swap current and next
        {
            const temp = current_state;
            current_state = next_state;
            next_state = temp;
        }
    }

    // Part 2
    var timelines: u64 = 0;
    for (current_state) |item| {
        timelines += item;
    }

    return DayResult.both_parts(part1_buf, part2_buf, splits, timelines);
}
