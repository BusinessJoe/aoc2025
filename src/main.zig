const std = @import("std");
const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;
const builtin = @import("builtin");

const aoc2025 = @import("aoc2025");
const DaySolution = aoc2025.framework.DaySolution;
const DayResult = aoc2025.framework.DayResult;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const allocator, const is_debug = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };


    // Set up stdout
    const stdout_buf = try allocator.alloc(u8, 1024);
    defer allocator.free(stdout_buf);
    var stdout_writer = std.fs.File.writer(std.fs.File.stdout(), stdout_buf);
    const stdout = &stdout_writer.interface;

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip(); // skip process name
    const input_subdirname = args.next() orelse "real";
    const input_name = try std.fmt.allocPrint(allocator, "inputs/{s}/", .{input_subdirname});
    defer allocator.free(input_name);

    // Directory with input files
    var input_dir = try std.fs.cwd().openDir(input_name, .{});
    defer input_dir.close();

    // All solutions
    const solutions = aoc2025.solutions;

    const part1_buf = try allocator.alloc(u8, 512);
    defer allocator.free(part1_buf);
    const part2_buf = try allocator.alloc(u8, 512);
    defer allocator.free(part2_buf);

    for (solutions, 1..) |solution, day_n| {
        const timed_result = try run_solution(allocator, input_dir, @as(u32, @intCast(day_n)), part1_buf, part2_buf, solution);

        try stdout.print("Day {d}, {d} us:\n  Part 1: {?s}\n  Part 2: {?s}\n", .{
            day_n, 
            timed_result.duration_ns / 1000, 
            timed_result.day_result.part1_str,
            timed_result.day_result.part2_str,
        });
        try stdout.flush();
    }
}

fn trivial_solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    _ = allocator;
    _ = input;

    return try DayResult.both_parts(part1_buf, part2_buf, 1, 2);
}

const TimedDayResult = struct {
    duration_ns: u64,
    day_result: DayResult,
};

fn run_solution(allocator: Allocator, input_dir: std.fs.Dir, day_n: u32, part1_buf: []u8, part2_buf: []u8, solution: DaySolution) !TimedDayResult {
    const filename = try std.fmt.allocPrint(allocator, "{d}", .{day_n});
    defer allocator.free(filename);

    const file = try input_dir.openFile(filename, .{});
    defer file.close();

    const file_size: u64 = try file.getEndPos();
    const file_buf: []u8 = try allocator.alloc(u8, file_size);
    defer allocator.free(file_buf);

    var file_reader: std.fs.File.Reader = file.reader(file_buf);
    const file_ioreader: *std.Io.Reader = &file_reader.interface;

    try file_ioreader.readSliceAll(file_buf);
    const trimmed_file_buf = std.mem.trimEnd(u8, file_buf, &[_]u8{'\n'});

    const start_time = try Instant.now();
    const day_result = try solution(allocator, trimmed_file_buf, part1_buf, part2_buf);
    const end_time = try Instant.now();
    const duration_ns = end_time.since(start_time);

    return . {
        .duration_ns = duration_ns,
        .day_result = day_result,
    };
}
