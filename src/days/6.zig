const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

const Op = enum {
    Add,
    Mul,
};

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    var lines = std.mem.splitBackwardsScalar(u8, input, '\n');

    const ops_line = lines.next() orelse return error.ExpectedLine;
    const cols = count_cols(ops_line);
    
    const accs = try allocator.alloc(u64, cols);
    defer allocator.free(accs);

    const ops = try allocator.alloc(Op, cols);
    defer allocator.free(ops);

    parse_ops(ops, accs, ops_line);

    while (lines.next()) |line| {
        var token_iter = std.mem.splitScalar(u8, line, ' ');
        var i: usize = 0;
        while (token_iter.next()) |token| {
            if (token.len == 0) continue;

            const num = try std.fmt.parseInt(u64, token, 10);
            switch (ops[i]) {
                .Add => accs[i] += num,
                .Mul => accs[i] *= num,
            }

            i += 1;
        }
    }

    var part1: u64 = 0;
    for (accs) |num| {
        part1 += num;
    }

    return DayResult.both_parts(part1_buf, part2_buf, part1, null);
}

fn count_cols(line: []const u8) u32 {
    var count: u32 = 0;
    var token_iter = std.mem.splitScalar(u8, line, ' ');

    while (token_iter.next()) |token| {
        if (token.len == 0) continue;
        count += 1;
    }

    return count;
}


fn parse_ops(ops: []Op, accs: []u64, ops_line: []const u8) void {
    var token_iter = std.mem.splitScalar(u8, ops_line, ' ');

    var i: usize = 0;
    while (token_iter.next()) |token| {
        if (token.len == 0) continue;

        if (token[0] == '*') {
            ops[i] = .Mul;
            accs[i] = 1;
        } else {
            ops[i] = .Add;
            accs[i] = 0;
        }

        i += 1;
    }
}
