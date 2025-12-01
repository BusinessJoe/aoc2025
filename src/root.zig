const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Solution = struct {
    part1: ?u32,
    part2: ?u32,

    pub fn first_part(part1: u32) Solution {
        return Solution {
            .part1 = part1,
            .part2 = null,
        };
    }

    pub fn both_parts(part1: u32, part2: u32) Solution {
        return Solution {
            .part1 = part1,
            .part2 = part2,
        };
    }
};

pub fn solution_1(reader: *std.Io.Reader, allocator: Allocator) !Solution {
    const max_size = 1024 * 32;
    const bytes: []u8 = try allocator.alloc(u8, max_size);
    defer allocator.free(bytes);
    const n_read = try reader.readSliceShort(bytes);

    if (reader.peek(1) != error.EndOfStream) {
        return error.BufferTooSmall;
    }

    var angle: u32 = 50;
    var zero_count: u32 = 0;

    var lines = std.mem.splitScalar(u8, bytes[0..n_read], '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var val = try std.fmt.parseInt(u32, line[1..], 10);
        val = val % 100;
        if (line[0] == 'L') {
            val = 100 - val;
        }
       
        angle = (angle + val) % 100;
        if (angle == 0) zero_count += 1;
    }

    return Solution.first_part(zero_count);
}
