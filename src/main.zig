const std = @import("std");
const aoc2025 = @import("aoc2025");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.print("Memory leaked\n", .{});
        } else {
            std.debug.print("All memory freed :)\n", .{});
        }
    }
    const allocator = gpa.allocator();

    var input_dir = try std.fs.cwd().openDir("inputs/real/", .{});
    defer input_dir.close();

    const file_1 = try input_dir.openFile("1", .{});
    defer file_1.close();

    const file_buf: []u8 = try allocator.alloc(u8, 1024 * 1024);
    defer allocator.free(file_buf);

    var file_reader: std.fs.File.Reader = file_1.reader(file_buf);
    const file_ioreader: *std.Io.Reader = &file_reader.interface;
    const solution: aoc2025.Solution = try aoc2025.solution_1(file_ioreader, allocator);
    std.debug.print("Day 1: {?d} {?d}\n", .{solution.part1, solution.part2});
}
