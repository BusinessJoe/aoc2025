const std = @import("std");

pub fn Grid(T: type) type {
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

        pub fn get_ptr(self: Self, row: isize, col: isize) ?*T {
            if (!self.contains(row, col)) return null;

            const row_u: usize = @intCast(row);
            const col_u: usize = @intCast(col);
            return &self.buf[row_u * self.cols + col_u];
        }

        pub fn contains(self: Self, row: isize, col: isize) bool {
            if (!(0 <= row and row < self.rows)) return false;
            if (!(0 <= col and col < self.cols)) return false;
            return true;
        }
    };
}
