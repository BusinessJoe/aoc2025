const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;
const Grid  = @import("../grid.zig").Grid;

const Op = enum {
    Add,
    Mul,
};

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    const part1 = try do_part1(allocator, input);
    const part2 = try do_part2(allocator, input);

    return DayResult.both_parts(part1_buf, part2_buf, part1, part2);
}

fn do_part1(allocator: Allocator, input: []const u8) !u64 {
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

    return part1;
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

fn do_part2(allocator: Allocator, input: []const u8) !u64 {
    const num_lines = std.mem.count(u8, input, &[_]u8{'\n'});
    const rows = num_lines;

    var reverse_lines = std.mem.splitBackwardsScalar(u8, input, '\n');
    const ops_line = reverse_lines.next() orelse return error.ExpectedLine;
    const cols = ops_line.len;

    var grid_buf = try allocator.alloc(u8, rows * cols);
    defer allocator.free(grid_buf);
    {
        var i: usize = 0;
        for (input[0..rows * (cols + 1)]) |char| {
            if (char == '\n') continue;
            grid_buf[i] = char;
            i += 1;
        }
    }
    const grid = Grid(u8).init(grid_buf, rows, cols);

    var part2: u64 = 0;

    var i: usize = 0;
    while (i < ops_line.len) {
        const char = ops_line[i];
        if (char == ' ') continue;

        var acc: u64 = 0;
        var op: Op = .Add;
        if (char == '*') {
            acc = 1;
            op = .Mul;
        }

        while (try get_num_from_col(grid, i)) |num| {
            switch (op) {
                .Add => acc += num,
                .Mul => acc *= num,
            }
            i += 1;
        }

        i += 1;
        part2 += acc;
    }
    
    return part2;
}

fn get_num_from_col(grid: Grid(u8), col_u: usize) !?u64 {
    if (col_u >= grid.cols) return null;
    const col: isize = @intCast(col_u);

    var num: ?u64 = null;

    for (0..grid.rows) |row| {
        const char = grid.get(@intCast(row), col).?;
        if (char == ' ') continue;

        const digit: u64 = @intCast(char - '0');
        num = (num orelse 0) * 10 + digit;
    }

    return num;
}
