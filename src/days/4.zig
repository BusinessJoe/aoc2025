const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    const cols: usize = std.mem.indexOfScalar(u8, input, '\n') orelse return error.NoLineEnding;
    const rows: usize = ((input.len + 1) / cols) - 1;

    const grid_buf: []bool = try allocator.alloc(bool, cols * rows);
    defer allocator.free(grid_buf);

    init_grid(grid_buf, input);

    const grid = Grid(bool).init(grid_buf, rows, cols);

    var part1: u32 = 0;
    
    const offsets: [3]isize = [_]isize{-1, 0, 1};

    for (0..rows) |row_u| {
        const row: isize = @intCast(row_u);
        for (0..cols) |col_u| {
            const col: isize = @intCast(col_u);

            // Skip empty cells
            if (grid.get(row, col) == false) continue;
            
            var neighbours: u8 = 0;
            for (offsets) |dr| {
                for (offsets) |dc| {
                    if (dr == 0 and dc == 0) continue;

                    if (grid.get(row + dr, col + dc) == true) {
                        neighbours += 1;
                    }
                }
            }

            if (neighbours < 4) {
                part1 += 1;
            }
        }
    }

    return DayResult.both_parts(part1_buf, part2_buf, part1, null);
}

fn init_grid(grid: []bool, input: []const u8) void {
    var i: usize = 0;
    for (input) |char| {
        if (char == '\n') continue;

        grid[i] = char == '@';
        i += 1;
    }
}


fn Grid(T: type) type {
    return struct {
        const Self = @This();

        buf: []T,
        rows: usize,
        cols: usize,

        pub fn init(buf: []T, rows: usize, cols: usize) Self {
            std.debug.assert(buf.len == rows * cols);

            return .{
                .buf = buf,
                .rows = rows,
                .cols = cols,
            };
        }

        pub fn get(self: Self, row: isize, col: isize) ?T {
            if (!self.contains(row, col)) return null;

            const row_u: usize = @intCast(row);
            const col_u: usize = @intCast(col);
            return self.buf[row_u * self.cols + col_u];
        }

        pub fn contains(self: Self, row: isize, col: isize) bool {
            if (!(0 <= row and row < self.rows)) return false;
            if (!(0 <= col and col < self.cols)) return false;
            return true;
        }
    };
}
